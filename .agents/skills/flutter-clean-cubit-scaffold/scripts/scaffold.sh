#!/usr/bin/env bash
#
# scaffold.sh — create a new Flutter app with the Clean-Architecture + Cubit
# structure captured by the flutter-clean-cubit-scaffold skill.
#
# Usage:
#   scaffold.sh <project_name> [options]
#
# Arguments:
#   <project_name>        Dart package name: lowercase, digits, underscores;
#                         must start with a letter. e.g. my_delivery_app
#
# Options:
#   --org <id>            Reverse-domain org for native bundle ids.
#                         Default: com.example  → bundle com.example.<name>
#   --title <text>        Human app title. Default: Title Case of <name>.
#   --desc <text>         pubspec description. Default: "A new Flutter project."
#   --dir <path>          Target directory. Default: ./<name>
#   --base-url <url>      Seed BASE_URL in the generated .env.* files.
#                         Default: https://example.com (so the app boots).
#   --platforms <list>   flutter create platforms. Default: android,ios
#   --flavors            Also run `flutter_flavorizr` for native dev/staging/
#                         prod flavor wiring (fiddly; off by default).
#   --no-codegen         Skip build_runner + easy_localization generation.
#   --force              Allow scaffolding into a non-empty target directory.
#
# Requires: flutter, perl.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_SRC="$(cd "$SCRIPT_DIR/../assets/scaffold" && pwd)"

die() { echo "error: $*" >&2; exit 1; }
info() { echo "▶ $*"; }

command -v flutter >/dev/null 2>&1 || die "flutter not found on PATH."
command -v perl >/dev/null 2>&1 || die "perl not found on PATH."
[ -d "$ASSETS_SRC" ] || die "template dir not found: $ASSETS_SRC"

# --- parse args -------------------------------------------------------------
NAME="${1:-}"
[ -n "$NAME" ] || die "missing <project_name>. See header for usage."
shift || true

ORG="com.example"
TITLE=""
DESCRIPTION="A new Flutter project."
DEST=""
BASE_URL="https://example.com"
PLATFORMS="android,ios"
RUN_FLAVORS=0
RUN_CODEGEN=1
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --org) ORG="$2"; shift 2;;
    --title) TITLE="$2"; shift 2;;
    --desc) DESCRIPTION="$2"; shift 2;;
    --dir) DEST="$2"; shift 2;;
    --base-url) BASE_URL="$2"; shift 2;;
    --platforms) PLATFORMS="$2"; shift 2;;
    --flavors) RUN_FLAVORS=1; shift;;
    --no-codegen) RUN_CODEGEN=0; shift;;
    --force) FORCE=1; shift;;
    *) die "unknown option: $1";;
  esac
done

echo "$NAME" | grep -Eq '^[a-z][a-z0-9_]*$' \
  || die "invalid package name '$NAME' — use lowercase letters, digits, underscores; start with a letter."

[ -n "$DEST" ] || DEST="./$NAME"
[ -n "$TITLE" ] || TITLE="$(echo "$NAME" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1')"
BUNDLE_ID="$ORG.$NAME"

if [ -d "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ] && [ "$FORCE" -ne 1 ]; then
  die "target '$DEST' exists and is not empty. Pass --force to proceed."
fi

# --- 1. flutter create ------------------------------------------------------
info "flutter create → $DEST  (org=$ORG, platforms=$PLATFORMS)"
flutter create --org "$ORG" --project-name "$NAME" --platforms "$PLATFORMS" "$DEST"

DEST="$(cd "$DEST" && pwd)"

# --- 2. overlay the architecture --------------------------------------------
info "overlaying architecture templates"
# Remove flutter-create defaults we replace.
rm -f "$DEST/lib/main.dart" "$DEST/test/widget_test.dart"
# Copy template contents (including dotfiles) over the created project.
cp -R "$ASSETS_SRC"/. "$DEST"/

# --- 3. substitute placeholders ---------------------------------------------
info "substituting package name, title, bundle id"
export PKG="$NAME" APP_TITLE="$TITLE" DESCRIPTION="$DESCRIPTION" BUNDLE_ID="$BUNDLE_ID"
find "$DEST" -type f \
  \( -name '*.dart' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' -o -name '*.md' -o -name '.env.example' \) \
  -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/.dart_tool/*' -print0 \
  | while IFS= read -r -d '' f; do
      perl -i -pe '
        s/__PKG__/$ENV{PKG}/g;
        s/__APP_TITLE__/$ENV{APP_TITLE}/g;
        s/__DESCRIPTION__/$ENV{DESCRIPTION}/g;
        s/__BUNDLE_ID__/$ENV{BUNDLE_ID}/g;
      ' "$f"
    done

# --- 4. env files + gitignore -----------------------------------------------
info "creating .env.dev / .env.staging / .env.prod (BASE_URL=$BASE_URL)"
for flavor in dev staging prod; do
  printf 'BASE_URL=%s\nIMG_URL=\n' "$BASE_URL" > "$DEST/.env.$flavor"
done
if [ -f "$DEST/.gitignore.append" ]; then
  cat "$DEST/.gitignore.append" >> "$DEST/.gitignore"
  rm -f "$DEST/.gitignore.append"
fi

# --- 5. dependencies --------------------------------------------------------
cd "$DEST"
info "flutter pub get"
flutter pub get

# --- 6. code generation -----------------------------------------------------
if [ "$RUN_CODEGEN" -eq 1 ]; then
  info "generating localisation keys"
  dart run easy_localization:generate \
    -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys

  info "build_runner (injectable, retrofit, json, auto_route, flutter_gen)"
  dart run build_runner build --delete-conflicting-outputs
else
  echo "  (skipped codegen — run it yourself before building)"
fi

# --- 7. optional native flavors ---------------------------------------------
if [ "$RUN_FLAVORS" -eq 1 ]; then
  info "flutter_flavorizr (native flavor wiring)"
  dart run flutter_flavorizr || echo "  flavorizr failed — configure flavors manually (see references/extending.md)"
fi

# --- done -------------------------------------------------------------------
cat <<EOF

✅ Scaffolded '$NAME' at $DEST

Next steps:
  cd "$DEST"
  # fill real values in .env.dev / .env.staging / .env.prod
  flutter run -t lib/main_dev.dart        # single-flavor run (works now)
$( [ "$RUN_FLAVORS" -eq 1 ] && echo "  flutter run --flavor dev -t lib/main_dev.dart   # after flavorizr" )

  flutter analyze
  flutter test

Add a new feature slice: see the skill's references/add-a-feature.md
EOF

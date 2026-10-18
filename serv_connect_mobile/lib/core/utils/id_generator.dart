import 'package:uuid/uuid.dart';

/// Generates client-side UUID v4 identifiers for offline-first entity creation
/// and outbox mutation idempotency keys (`CLAUDE.md §11 & §12.2`).
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String newUuid() => _uuid.v4();
}

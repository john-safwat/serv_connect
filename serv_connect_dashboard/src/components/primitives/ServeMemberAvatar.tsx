import type React from 'react';
import { extractInitials } from './avatar_utils';
import {
  ServeAvatar,
  type ServeAvatarSize,
  type ServeAvatarTone,
} from './ServeAvatar';

export interface ServeMemberAvatarProps {
  readonly displayName: string;
  readonly photoUrl?: string | null;
  readonly photoConsent: boolean;
  readonly tone?: ServeAvatarTone;
  readonly size?: ServeAvatarSize;
}

export function ServeMemberAvatar({
  displayName,
  photoUrl,
  photoConsent,
  tone = 'gold',
  size = 'md',
}: ServeMemberAvatarProps): React.JSX.Element {
  const initials = extractInitials(displayName);
  const allowedUrl = photoConsent && photoUrl ? photoUrl : undefined;

  return (
    <ServeAvatar
      initials={initials}
      imageUrl={allowedUrl}
      alt={displayName}
      tone={tone}
      size={size}
    />
  );
}

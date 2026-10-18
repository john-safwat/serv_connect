import { z } from 'zod';
import { LocaleKeys } from '../../generated/locale_keys.g';

const E164_OR_LOCAL_PHONE_REGEX = /^\+?[0-9]{8,15}$/;
const OTP_CODE_REGEX = /^[0-9]{6}$/;

export const Validation = {
  requiredTextSchema: z
    .string()
    .trim()
    .min(1, { message: LocaleKeys.validation_required }),

  emailSchema: z
    .string()
    .trim()
    .min(1, { message: LocaleKeys.validation_required })
    .email({ message: LocaleKeys.validation_invalid_email }),

  phoneSchema: z
    .string()
    .trim()
    .min(1, { message: LocaleKeys.validation_required })
    .regex(E164_OR_LOCAL_PHONE_REGEX, { message: LocaleKeys.validation_invalid_phone }),

  passwordSchema: z
    .string()
    .min(8, { message: LocaleKeys.validation_password_too_short }),

  otpSchema: z
    .string()
    .trim()
    .regex(OTP_CODE_REGEX, { message: LocaleKeys.validation_invalid_otp }),

  uuidSchema: z
    .string()
    .trim()
    .uuid({ message: LocaleKeys.validation_invalid_uuid }),
};

export const IdGenerator = {
  newUuid(): string {
    return crypto.randomUUID();
  },
};

import 'package:easy_localization/easy_localization.dart';
import 'package:serv_connect_mobile/generated/locale_keys.g.dart';

/// Centralised form validators returning localized error messages
/// (`CLAUDE.md §5 & §18`).
abstract final class Validation {
  static final RegExp _emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
  static final RegExp _otpRegex = RegExp(r'^[0-9]{6}$');

  static String? validateRequiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.validation_required.tr();
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final requiredCheck = validateRequiredText(value);
    if (requiredCheck != null) return requiredCheck;
    if (!_emailRegex.hasMatch(value!.trim())) {
      return LocaleKeys.validation_invalid_email.tr();
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final requiredCheck = validateRequiredText(value);
    if (requiredCheck != null) return requiredCheck;
    final normalized = value!.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_phoneRegex.hasMatch(normalized)) {
      return LocaleKeys.validation_invalid_phone.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final requiredCheck = validateRequiredText(value);
    if (requiredCheck != null) return requiredCheck;
    if (value!.length < 8) {
      return LocaleKeys.validation_password_too_short.tr();
    }
    return null;
  }

  static String? validateOtp(String? value) {
    final requiredCheck = validateRequiredText(value);
    if (requiredCheck != null) return requiredCheck;
    if (!_otpRegex.hasMatch(value!.trim())) {
      return LocaleKeys.validation_invalid_otp.tr();
    }
    return null;
  }
}

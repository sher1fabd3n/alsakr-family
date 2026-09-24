/// Validates Egyptian National ID numbers (14 digits).
class NationalIdValidator {
  NationalIdValidator._();

  static final _digitsOnly = RegExp(r'^\d{14}$');

  /// Returns `true` when [id] is a valid 14-digit Egyptian National ID.
  static bool isValid(String? id) {
    final normalized = normalize(id);
    if (normalized == null) return false;
    return _digitsOnly.hasMatch(normalized);
  }

  /// Returns an Arabic validation message, or `null` when valid.
  static String? validationMessage(String? id) {
    if (id == null || id.trim().isEmpty) return 'الرقم القومي مطلوب';
    final normalized = normalize(id);
    if (normalized == null) return 'الرقم القومي مطلوب';
    if (RegExp(r'[A-Za-z]').hasMatch(id)) {
      return 'الرقم القومي لا يمكن أن يحتوي على حروف';
    }
    if (!_digitsOnly.hasMatch(normalized)) {
      return 'الرقم القومي يجب أن يكون 14 رقمًا بالضبط';
    }
    return null;
  }

  /// Converts Eastern Arabic digits and strips separators.
  static String? normalize(String? id) {
    if (id == null) return null;
    final converted = _convertEasternDigits(id.trim());
    final digits = StringBuffer();
    for (final rune in converted.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        digits.writeCharCode(rune);
      }
    }
    final value = digits.toString();
    return value.isEmpty ? null : value;
  }

  static String _convertEasternDigits(String input) {
    final buffer = StringBuffer();
    for (final code in input.runes) {
      if (code >= 0x0660 && code <= 0x0669) {
        buffer.writeCharCode(0x30 + (code - 0x0660));
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.writeCharCode(0x30 + (code - 0x06F0));
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }
}

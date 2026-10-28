/// Input checks shared by forms and view models. Each returns null when the
/// value is fine, or a message that can be shown under the field as is.
class Validators {
  Validators._();

  static String? required(String? value, String message) => (value == null || value.trim().isEmpty) ? message : null;

  static String? maxLength(String? value, int max, String label) =>
      (value != null && value.trim().length > max) ? '$label can be at most $max characters.' : null;

  /// Egyptian mobile number: 01 followed by 9 digits, e.g. 01012345678.
  static String? egyptianMobile(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^01[0125]\d{8}$').hasMatch(digits) ? null : 'Enter a valid mobile number, e.g. 01012345678.';
  }

  /// Any phone format (mobile, landline, international): digits with
  /// optional +, spaces, dashes and brackets. Empty passes.
  static String? phone(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return RegExp(r'^\+?[0-9(][0-9 ()\-]{5,19}$').hasMatch(v) ? null : 'Enter a valid phone number.';
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'Enter a valid email address.';
  }

  /// A number that is 0 or more; a comma works as the decimal point. Empty
  /// passes unless [required] is set. [label] is capitalised: "Selling price".
  static String? nonNegativeNumber(String? value, String label, {bool required = false}) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return required ? 'Enter the ${label.toLowerCase()}.' : null;
    final n = num.tryParse(v);
    if (n == null) return '$label must be a number.';
    return n < 0 ? "$label can't be negative." : null;
  }

  /// The first message from [checks], or null when all pass.
  static String? firstOf(Iterable<String? Function()> checks) {
    for (final check in checks) {
      final message = check();
      if (message != null) return message;
    }
    return null;
  }

  /// Field → message for every failing field; empty when the input is valid.
  static Map<String, String> collect(Map<String, String? Function()> fields) => {
        for (final e in fields.entries)
          if (e.value() case final String message) e.key: message,
      };
}

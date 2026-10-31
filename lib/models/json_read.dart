/// Tolerant readers for API JSON: a missing field or an unexpected type
/// becomes a default instead of a crash.
library;

int? readInt(Object? v) => switch (v) {
      int i => i,
      num n => n.toInt(),
      String s => int.tryParse(s.trim()),
      _ => null,
    };

double readDouble(Object? v, [double fallback = 0]) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s.trim()) ?? fallback,
      _ => fallback,
    };

double? readDoubleOrNull(Object? v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s.trim()),
      _ => null,
    };

String readString(Object? v, [String fallback = '']) => v == null ? fallback : v.toString();

String? readStringOrNull(Object? v) => v?.toString();

DateTime? readDate(Object? v) => v is String ? DateTime.tryParse(v) : null;

Map<String, dynamic>? readMap(Object? v) => v is Map<String, dynamic> ? v : null;

List<Map<String, dynamic>> readList(Object? v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

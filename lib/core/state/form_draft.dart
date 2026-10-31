import 'package:flutter/widgets.dart';

/// The text and picked values of one open form.
///
/// The route that opens a form creates it with a ChangeNotifierProvider, so
/// it lives and is disposed with that route; the form's widgets can then be
/// stateless. Text fields bind to [controller]; dropdowns, switches and
/// pickers use [value] / [set].
class FormDraft extends ChangeNotifier {
  FormDraft({Map<String, String?> text = const {}, Map<String, Object?> values = const {}})
      : _initialText = {for (final e in text.entries) e.key: e.value ?? ''},
        _initialValues = Map.of(values),
        _values = Map.of(values);

  final Map<String, String> _initialText;
  final Map<String, Object?> _initialValues;
  final Map<String, Object?> _values;
  final Map<String, TextEditingController> _controllers = {};

  /// The controller for text field [key], created on first use.
  TextEditingController controller(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: _initialText[key] ?? ''));

  /// The text typed in [key].
  String text(String key) => _controllers[key]?.text ?? _initialText[key] ?? '';

  T? value<T>(String key) => _values[key] as T?;

  bool flag(String key) => _values[key] == true;

  void set(String key, Object? value) {
    if (_values[key] == value) return;
    _values[key] = value;
    notifyListeners();
  }

  /// Replaces the text of [key] from code (e.g. delivery price from a zone).
  void setText(String key, String text) {
    controller(key).text = text;
    notifyListeners();
  }

  /// Rebuilds listeners after a change made through a controller, e.g. live
  /// totals that depend on typed amounts.
  void touch() => notifyListeners();

  /// True when anything differs from what the form opened with, so leaving
  /// can ask before throwing the changes away.
  bool get isDirty {
    for (final e in _controllers.entries) {
      if (e.value.text != (_initialText[e.key] ?? '')) return true;
    }
    for (final e in _values.entries) {
      final initial = _initialValues[e.key];
      if (e.value is List && initial is List) {
        if (!_sameList(e.value as List, initial)) return true;
      } else if (e.value != initial) {
        return true;
      }
    }
    return false;
  }

  static bool _sameList(List a, List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

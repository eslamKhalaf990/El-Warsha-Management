import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';

/// Loading, saving and error state shared by every view model.
///
/// View models wrap their work in [load] (fetching what the screen shows) or
/// [run] (a user action such as save or delete) and never write try/catch
/// themselves. Every failure ends up in [error] as an [ApiException] whose
/// message is safe to show; screens read [errorMessage] and [fieldError].
mixin AsyncViewModel on ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  ApiException? _error;
  bool _disposed = false;

  /// True while [load] runs.
  bool get isLoading => _isLoading;

  /// True while [run] runs; screens disable their buttons meanwhile.
  bool get isSaving => _isSaving;

  bool get isBusy => _isLoading || _isSaving;

  /// True once a [load] has succeeded, so screens can tell "empty" from
  /// "not loaded yet".
  bool get hasLoaded => _hasLoaded;

  /// Why the last [load] or [run] failed, or null.
  ApiException? get error => _error;

  String? get errorMessage => _error?.message;

  /// True when the last [load] failed and there is nothing to show yet.
  bool get loadFailed => _error != null && !_hasLoaded;

  /// The message for [field] (e.g. `name`, `items[0].quantity`) from the last
  /// failure, whether the app or the backend rejected it.
  String? fieldError(String field) => _error?.messageFor(field);

  /// Forgets the last failure, e.g. when a form opens or a field is edited.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notify();
  }

  /// Records a failure found before calling the server (client validation).
  /// Always returns false so actions can `return fail(...)`.
  bool fail(ApiException error) {
    _error = error;
    notify();
    return false;
  }

  /// Runs a fetch. Returns false when it failed; [error] says why.
  @protected
  Future<bool> load(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notify();
    final ok = await _guard(action);
    if (ok) _hasLoaded = true;
    _isLoading = false;
    notify();
    return ok;
  }

  /// Runs a user action. Returns false when it failed; [error] says why.
  @protected
  Future<bool> run(Future<void> Function() action) async {
    _isSaving = true;
    _error = null;
    notify();
    final ok = await _guard(action);
    _isSaving = false;
    notify();
    return ok;
  }

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      _error = e;
    } catch (e, stack) {
      // A bug or unreadable data: log it, show a plain message.
      debugPrint('$runtimeType: $e\n$stack');
      _error = ApiException.unexpected();
    }
    return false;
  }

  /// notifyListeners that is safe after the view model was disposed, which
  /// happens when a request outlives the session that started it.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

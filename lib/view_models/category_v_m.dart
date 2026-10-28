import 'package:flutter/foundation.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/core/state/async_view_model.dart';
import 'package:warsha_app/core/validation/validators.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/services/category_service.dart';

/// Categories screen: list, search, add, edit and delete.
class CategoryVM extends ChangeNotifier with AsyncViewModel {
  CategoryVM(this._service);

  final CategoryService _service;

  static const nameMaxLength = 100;
  static const descriptionMaxLength = 255;

  List<CategoryModel> _all = [];
  String _query = '';

  /// Every category, in creation order.
  List<CategoryModel> get allCategories => List.unmodifiable(_all);

  /// The categories matching the search box.
  List<CategoryModel> get categories {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return allCategories;
    return _all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  String get query => _query;

  Future<bool> fetch() => load(() async => _all = await _service.list());

  void search(String query) {
    if (query == _query) return;
    _query = query;
    notify();
  }

  // ── Validation ──────────────────────────────────────────

  static String? validateName(String? value) => Validators.firstOf([
        () => Validators.required(value, 'Enter the category name.'),
        () => Validators.maxLength(value, nameMaxLength, 'Category name'),
      ]);

  static String? validateDescription(String? value) => Validators.maxLength(value, descriptionMaxLength, 'Description');

  /// Checks [request] the way the backend does, plus duplicate names, so most
  /// mistakes are caught without a round trip.
  Map<String, String> validate(CategoryRequest request, {int? editingId}) {
    final errors = Validators.collect({
      'name': () => validateName(request.name),
      'description': () => validateDescription(request.description),
    });
    if (!errors.containsKey('name')) {
      final key = _key(request.name);
      final clash = _all.where((c) => c.categoryId != editingId && _key(c.name) == key);
      if (clash.isNotEmpty) errors['name'] = 'A category named "${clash.first.name}" already exists.';
    }
    return errors;
  }

  // ── CRUD ────────────────────────────────────────────────
  // Each returns true on success; on failure [error] / [fieldError] say why.

  Future<bool> add(CategoryRequest request) async {
    final errors = validate(request);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async => _all = [..._all, await _service.create(request)]);
  }

  Future<bool> update(int id, CategoryRequest request) async {
    final errors = validate(request, editingId: id);
    if (errors.isNotEmpty) return fail(ApiException.validation(errors));
    return run(() async {
      final updated = await _service.update(id, request);
      _all = [for (final c in _all) c.categoryId == id ? updated : c];
    });
  }

  Future<bool> delete(CategoryModel category) => run(() async {
        await _service.delete(category.categoryId);
        _all = _all.where((c) => c.categoryId != category.categoryId).toList();
      });

  static String _key(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

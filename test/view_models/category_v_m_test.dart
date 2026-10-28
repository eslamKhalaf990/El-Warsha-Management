import 'package:flutter_test/flutter_test.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/services/category_service.dart';
import 'package:warsha_app/view_models/category_v_m.dart';

class FakeCategoryService implements CategoryService {
  List<CategoryModel> rows = [
    const CategoryModel(categoryId: 1, name: 'Rings', productCount: 2),
    const CategoryModel(categoryId: 2, name: 'Chains'),
  ];
  ApiException? failWith;
  int calls = 0;

  Future<T> _answer<T>(T value) async {
    calls++;
    if (failWith != null) throw failWith!;
    return value;
  }

  @override
  Future<List<CategoryModel>> list() => _answer(rows);

  @override
  Future<CategoryModel> create(CategoryRequest r) => _answer(CategoryModel(categoryId: 3, name: r.name.trim()));

  @override
  Future<CategoryModel> update(int id, CategoryRequest r) => _answer(CategoryModel(categoryId: id, name: r.name.trim()));

  @override
  Future<void> delete(int id) => _answer(null);
}

void main() {
  late FakeCategoryService service;
  late CategoryVM vm;

  setUp(() async {
    service = FakeCategoryService();
    vm = CategoryVM(service);
    await vm.fetch();
    service.calls = 0;
  });

  test('search filters by name, case-insensitively', () {
    vm.search('RIN');
    expect(vm.categories.map((c) => c.name), ['Rings']);
    vm.search('');
    expect(vm.categories, hasLength(2));
  });

  test('add validates before calling the server', () async {
    expect(await vm.add(const CategoryRequest(name: '  ')), isFalse);
    expect(vm.fieldError('name'), 'Enter the category name.');

    expect(await vm.add(CategoryRequest(name: 'x' * 101)), isFalse);
    expect(vm.fieldError('name'), 'Category name can be at most 100 characters.');

    expect(await vm.add(const CategoryRequest(name: ' rings ')), isFalse);
    expect(vm.fieldError('name'), 'A category named "Rings" already exists.');

    expect(service.calls, 0);
  });

  test('add appends the saved category', () async {
    expect(await vm.add(const CategoryRequest(name: 'Bracelets')), isTrue);
    expect(vm.allCategories.last.name, 'Bracelets');
    expect(vm.error, isNull);
  });

  test('renaming to its own name is fine, to another one is not', () async {
    expect(await vm.update(1, const CategoryRequest(name: 'RINGS')), isTrue);
    expect(vm.allCategories.first.name, 'RINGS');

    expect(await vm.update(2, const CategoryRequest(name: 'rings')), isFalse);
    expect(vm.fieldError('name'), contains('already exists'));
  });

  test('a server field error shows under the field', () async {
    service.failWith = const ApiException(
      code: 'CONFLICT',
      statusCode: 409,
      message: 'A category named "Gifts" already exists.',
      details: [FieldViolation('name', 'A category named "Gifts" already exists.')],
    );

    expect(await vm.add(const CategoryRequest(name: 'Gifts')), isFalse);
    expect(vm.fieldError('name'), 'A category named "Gifts" already exists.');
    expect(vm.isSaving, isFalse);
  });

  test('a refused delete keeps the category and explains why', () async {
    service.failWith = const ApiException(
      code: 'CONFLICT',
      statusCode: 409,
      message: '"Rings" still has 2 products. Move them to another category first.',
    );

    expect(await vm.delete(vm.allCategories.first), isFalse);
    expect(vm.allCategories, hasLength(2));
    expect(vm.errorMessage, contains('2 products'));
  });

  test('delete removes the category', () async {
    expect(await vm.delete(vm.allCategories.last), isTrue);
    expect(vm.allCategories.map((c) => c.name), ['Rings']);
  });

  test('a failed first load is reported for the retry view', () async {
    service.failWith = ApiException.network();
    final fresh = CategoryVM(service);

    expect(await fresh.fetch(), isFalse);
    expect(fresh.loadFailed, isTrue);
    expect(fresh.errorMessage, contains("Can't reach the server"));
  });
}

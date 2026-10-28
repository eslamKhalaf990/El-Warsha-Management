import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/network/api_exception.dart';
import 'package:warsha_app/models/category_model.dart';

/// Product categories API (backend: CategoryController under `/category`).
/// Every failure surfaces as an [ApiException] from [ApiClient].
class CategoryService {
  CategoryService(this._api);

  final ApiClient _api;

  Future<List<CategoryModel>> list() async {
    final body = await _api.get('category');
    if (body is! List) throw ApiException.badResponse(200);
    return body.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
  }

  Future<CategoryModel> create(CategoryRequest request) async =>
      _category(await _api.post('category', body: request.toJson()));

  Future<CategoryModel> update(int id, CategoryRequest request) async =>
      _category(await _api.put('category/$id', body: request.toJson()));

  Future<void> delete(int id) async {
    await _api.delete('category/$id');
  }

  static CategoryModel _category(Object? body) {
    if (body is! Map<String, dynamic>) throw ApiException.badResponse(200);
    return CategoryModel.fromJson(body);
  }
}

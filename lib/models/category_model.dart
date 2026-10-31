import 'package:warsha_app/models/product_image.dart' show resolveImageUrl;

class CategoryModel {
  final int categoryId;
  final String name;
  final String? description;
  final String? imageUrl;

  /// [imageUrl] on the API host, ready for an image widget.
  String? get imageFullUrl => (imageUrl == null || imageUrl!.isEmpty) ? null : resolveImageUrl(imageUrl!);

  /// Products in this category that are not deleted.
  final int productCount;

  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
    this.productCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: (json['categoryId'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Equal by id, so dropdowns keep their selection after a reload.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel && runtimeType == other.runtimeType && categoryId == other.categoryId;

  @override
  int get hashCode => categoryId.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
    };
  }
}

/// Body of POST /category and PUT /category/{id}. The backend replaces every
/// field, so an edit must send the [imageUrl] it keeps.
class CategoryRequest {
  final String name;
  final String? description;
  final String? imageUrl;

  const CategoryRequest({required this.name, this.description, this.imageUrl});

  CategoryRequest withImage(String? url) => CategoryRequest(name: name, description: description, imageUrl: url);

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': _blankToNull(description),
        'imageUrl': _blankToNull(imageUrl),
      };

  static String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

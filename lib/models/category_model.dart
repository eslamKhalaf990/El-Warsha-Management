class CategoryModel {
  final int categoryId;
  final String name;
  final String? description;
  final String? imageUrl;

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

/// Body of POST /category and PUT /category/{id}.
class CategoryRequest {
  final String name;
  final String? description;

  const CategoryRequest({required this.name, this.description});

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': (description == null || description!.trim().isEmpty) ? null : description!.trim(),
      };
}

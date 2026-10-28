import 'package:warsha_app/services/base_url.dart';

import 'json_read.dart';

/// An extra gallery image of a product (backend: ProductImageDto).
/// The cover image stays in the product's own `imageUrl`.
class ProductImage {
  final int id;
  final String imageUrl;
  final int sortOrder;

  const ProductImage({required this.id, required this.imageUrl, required this.sortOrder});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
        id: readInt(json['id']) ?? 0,
        imageUrl: readString(json['imageUrl']),
        sortOrder: readInt(json['sortOrder']) ?? 0,
      );

  String get fullUrl => imageFullUrl(imageUrl);
}

/// Turns a server path like `/images/a.jpg` into a full URL on the API host.
String imageFullUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = Baseurl.baseURL.endsWith('/')
      ? Baseurl.baseURL.substring(0, Baseurl.baseURL.length - 1)
      : Baseurl.baseURL;
  return '$base${url.startsWith('/') ? url : '/$url'}';
}

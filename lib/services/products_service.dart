import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:warsha_app/utils/const_values.dart';

import 'base_url.dart';

class ProductService {
  // This class will handle the logic for attendance management.
  Future<http.Response> getAllProducts(String token) async {
    debugPrint("getAllProducts called");
    http.Response response;
    try {
      response = await http.get(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          "Authorization": 'Bearer $token',
        },
        Uri.parse(
          Baseurl.getAllProductsAPI,
        ),
      ).timeout(const Duration(seconds: Constants.TIMEOUT));
    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to get your requests: $e');
    }
    return response;
  }

  // This class will handle the logic for attendance management.
  Future<http.Response> getAllCategories(String token) async {
    debugPrint("getAllCategories called");
    http.Response response;
    try {
      response = await http.get(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          "Authorization": 'Bearer $token',
        },
        Uri.parse(
          Baseurl.getAllCategoriesAPI,
        ),
      ).timeout(const Duration(seconds: Constants.TIMEOUT));
    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to get your requests: $e');
    }
    return response;
  }

  Future<http.Response> deleteProduct(String id, String token) async {
    debugPrint("deleteProduct with id: $id called");
    http.Response response;
    try {
      response = await http.delete(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          "Authorization": 'Bearer $token',
        },
        Uri.parse(
          "${Baseurl.deleteProductAPI}/$id",
        ),
      ).timeout(const Duration(seconds: Constants.TIMEOUT));

    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to delete your product: $e');
    }
    return response;
  }

  Future<http.Response> addCategory(String name, String token) async {
    debugPrint("addCategory with name: $name called");
    http.Response response;
    try {
      response = await http.post(
        headers: {
          'Content-Type': 'application/json',
          "Authorization": 'Bearer $token',
        },
        Uri.parse(
          "${Baseurl.addCategoryAPI}/add",
        ),
        body: jsonEncode({
          'name': name,
        }),
      ).timeout(const Duration(seconds: Constants.TIMEOUT));

      print(response.body);

    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to add your category: $e');
    }
    return response;
  }

  Future<http.StreamedResponse> addProductWithImage({
    required String name,
    required String description,
    required String buyingPrice,
    required String sellingPrice,
    required String discount,
    required String category,
    required String quantity,
    required Uint8List? imageBytes,
    String? imageName,
    required String token,
  }) async {
    var uri = Uri.parse(Baseurl.addProductAPI);
    print(discount);
    final product = jsonEncode({
      "name": name,
      "description": description,
      "buyingPrice": buyingPrice,
      "discount": discount,
      "sellingPrice": sellingPrice,
      "category": {"categoryId": category},
      "quantity": quantity,
    });

    var request = http.MultipartRequest("POST", uri);
    request.fields['product'] = product;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes as List<int>,
          filename: imageName ?? "upload.jpg",
        ),
      );
    }

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    return await request.send();
  }

  Future<http.StreamedResponse> updateProductWithImage({
    required String id,
    required String name,
    required String description,
    required String buyingPrice,
    required String sellingPrice,
    required String discount,
    required String category,
    required String quantity,
    required String token,
    required Uint8List? imageBytes,
    String? imageName,
  }) async {
    var uri = Uri.parse("${Baseurl.updateProductAPI}/$id");

    final product = jsonEncode({
      "name": name,
      "description": description,
      "buyingPrice": buyingPrice,
      "sellingPrice": sellingPrice,
      "discount": discount,
      "category": {"categoryId": category},
      "quantity": quantity,
    });

    var request = http.MultipartRequest("PUT", uri);
    request.fields['product'] = product;

    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName ?? "upload.jpg",
        ),
      );
    }

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    return await request.send();
  }

  /// All images in the shared image library: [{ "filename": ..., "url": "/images/..." }]
  Future<http.Response> getLibraryImages(String token) async {
    debugPrint("getLibraryImages called");
    try {
      return await http.get(
        Uri.parse(Baseurl.productImagesAPI),
        headers: {"Authorization": 'Bearer $token'},
      ).timeout(const Duration(seconds: Constants.TIMEOUT));
    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to get library images: $e');
    }
  }

  /// Assigns an existing library image to a product
  Future<http.Response> assignProductImage({
    required String id,
    required String filename,
    required String token,
  }) async {
    debugPrint("assignProductImage $filename -> product $id");
    try {
      return await http.put(
        Uri.parse("${Baseurl.updateProductAPI}/$id/image"),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": 'Bearer $token',
        },
        body: jsonEncode({'filename': filename}),
      ).timeout(const Duration(seconds: Constants.TIMEOUT));
    } on TimeoutException {
      throw Exception('The request timed out. Please try again later.');
    } catch (e) {
      throw Exception('Failed to assign image: $e');
    }
  }
}

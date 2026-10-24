import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

class UpdateProductVM extends ChangeNotifier {
  final ProductService _productService;
  ProductModel? productModel;
  final UserViewModel _userViewModel;


  bool isLoading = false;

  UpdateProductVM(this._productService, this._userViewModel);

  Future<String> updateProduct({
    required String id,
    required String productName,
    required String productDescription,
    required String productBPrice,
    required String productSPrice,
    required String productDiscount,
    required String productCategory,
    required String productQuantity,
    required Uint8List? imageBytes,
    String? imageName,
    String? libraryFilename,
  }) async {
    String status = "";
    try {
      isLoading = true;
      notifyListeners();

      final response = await _productService.updateProductWithImage(
        id: id,
        name: productName,
        description: productDescription,
        buyingPrice: productBPrice,
        sellingPrice: productSPrice,
        category: productCategory,
        discount: productDiscount,
        quantity: productQuantity,
        imageBytes: imageBytes,
        imageName: imageName,
        token: _userViewModel.token
      );

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        status = "product_updated";
        debugPrint("Product updated: $responseBody");

        // Image picked from the library: assign it after saving the details
        if (libraryFilename != null) {
          final assignResponse = await _productService.assignProductImage(
            id: id,
            filename: libraryFilename,
            token: _userViewModel.token,
          );
          if (assignResponse.statusCode != 200) {
            status = "image_not_assigned";
            debugPrint("Assign image failed: ${assignResponse.statusCode} - ${assignResponse.body}");
          }
        }
      } else {
        status = "product_not_updated";
        debugPrint("Update failed: ${response.statusCode} - $responseBody");
      }
    } catch (e) {
      status = "product_not_updated";
      debugPrint("Error updating product: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return status;
  }

  void loadProduct(ProductModel existingProduct) {
    productModel = ProductModel.get(
      id: existingProduct.id,
      name: existingProduct.name,
      buyingPrice: existingProduct.buyingPrice,
      sellingPrice: existingProduct.sellingPrice,
      category: existingProduct.category,
      discount: existingProduct.discount,
      totalPrice: existingProduct.totalPrice,
      categoryId: existingProduct.categoryId,
      quantity: existingProduct.quantity,
      productDescription: existingProduct.productDescription,
      image: existingProduct.image,
    );
    notifyListeners();
  }

}

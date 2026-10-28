import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:warsha_app/models/category_model.dart';
import 'package:warsha_app/models/json_read.dart';
import 'package:warsha_app/models/product_model.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

class ProductVM extends ChangeNotifier {
  final ProductService _productService;
  final UserViewModel _userViewModel;

  bool isLoading = false;
  String deletedProduct = "";

  /// Id of the product created by the last successful [addProduct].
  int? lastCreatedProductId;

  Future<List<ProductModel>>? allProducts;
  List<CategoryModel>? allCategories;
  final TextEditingController searchController = TextEditingController();

  ProductVM(this._productService, this._userViewModel) {
    initAllProducts();
    searchController.addListener(() {
      notifyListeners();
    });
  }

  Future<void> initAllProducts() async {
    allProducts = getAllProducts();
    allCategories = await getAllCategories();
    notifyListeners();
  }

  Future<void> initAllCategories() async {
    allCategories = await getAllCategories();
    notifyListeners();
  }

  Future<List<ProductModel>> getAllProducts() async {
    List<ProductModel> products = [];
    try {
      isLoading = true;
      final response =
          await _productService.getAllProducts(_userViewModel.token);
      if (response.statusCode == 200) {
        final productsData = jsonDecode(response.body);
        final List<dynamic> data = productsData;
        products = data.map((item) => ProductModel.fromJson(item)).toList();
      } else {
        debugPrint("Failed to fetch products: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return products;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    List<CategoryModel> categories = [];
    try {
      isLoading = true;
      final response =
          await _productService.getAllCategories(_userViewModel.token);
      if (response.statusCode == 200) {
        final categoriesData = jsonDecode(response.body);
        final List<dynamic> data = categoriesData;
        categories = data.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        debugPrint("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return categories;
  }

  Future<String> addProduct({
    required String productName,
    required String productDescription,
    String productNameAr = "",
    String productDescriptionAr = "",
    required String productBPrice,
    required String productSPrice,
    required String productDiscount,
    required String productCategory,
    required String productQuantity,
    required Uint8List? imageBytes,
  }) async {
    String status = "";
    try {
      isLoading = true;
      notifyListeners();

      if (productDiscount.isEmpty) {
        productDiscount = "0";
      }

      final response = await _productService.addProductWithImage(
          name: productName,
          description: productDescription,
          nameAr: productNameAr,
          descriptionAr: productDescriptionAr,
          buyingPrice: productBPrice,
          sellingPrice: productSPrice,
          discount: productDiscount,
          category: productCategory,
          quantity: productQuantity,
          imageBytes: imageBytes,
          token: _userViewModel.token);

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        status = "product_added";
        final created = jsonDecode(responseBody);
        lastCreatedProductId = created is Map ? readInt(created['productID'] ?? created['id']) : null;
        debugPrint("Product added: $responseBody");
      } else {
        status = "product_not_added";
      }
    } catch (e) {
      status = "product_not_added";
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return status;
  }

  Future<String> deleteProduct(String productId) async {
    String status = "";
    try {
      isLoading = true;
      deletedProduct = productId;

      notifyListeners();

      final response =
          await _productService.deleteProduct(productId, _userViewModel.token);
      print(response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 204) {
        status = "product_deleted";
        debugPrint("Product deleted successfully");
      } else {
        status = "product_not_deleted";
        debugPrint("Failed to delete product: ${response.statusCode}");
      }
    } catch (e) {
      status = "product_not_deleted";
      debugPrint("Error deleting product: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return status;
  }

  Future<String> addCategory(String name) async {
    String status = "";
    try {
      isLoading = true;

      notifyListeners();

      final response =
          await _productService.addCategory(name, _userViewModel.token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        status = "category_added";
        initAllCategories();
        debugPrint("Category added successfully");
      } else {
        status = "category_not_deleted";
        debugPrint("Failed to add category: ${response.statusCode}");
      }
    } catch (e) {
      status = "category_not_deleted";
      debugPrint("Error adding category: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }

    return status;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

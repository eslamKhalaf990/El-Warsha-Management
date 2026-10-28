import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  // TextEditingControllers
  final TextEditingController productName = TextEditingController();
  final TextEditingController productDescription = TextEditingController();
  final TextEditingController productNameAr = TextEditingController();
  final TextEditingController productDescriptionAr = TextEditingController();
  final TextEditingController productBuyingPrice = TextEditingController();
  final TextEditingController productSellingPrice = TextEditingController();
  final TextEditingController productCategory = TextEditingController();
  final TextEditingController productQuantity = TextEditingController();
  final TextEditingController productSupplier = TextEditingController();
  final TextEditingController discount = TextEditingController();

  // Live price tracking
  double _buyingPrice = 0.0;
  double _sellingPrice = 0.0;

  double get buyingPrice => _buyingPrice;
  double get sellingPrice => _sellingPrice;
  double get profit => _sellingPrice - _buyingPrice;

  // Inside ProductVM class
  List<String> productColors = [];

  void addColor(String color) {
    if (!productColors.contains(color)) {
      productColors.add(color);
      notifyListeners();
    }
  }

  void removeColor(String color) {
    productColors.remove(color);
    notifyListeners();
  }

// Don't forget to clear this list when the screen closes or successfully saves!
  void clearColors() {
    productColors.clear();
    notifyListeners();
  }

  // Inside ProductVM class
  List<String> productSizes = [];

  void addSize(String color) {
    if (!productSizes.contains(color)) {
      productSizes.add(color);
      notifyListeners();
    }
  }

  void removeSize(String color) {
    productSizes.remove(color);
    notifyListeners();
  }

// Don't forget to clear this list when the screen closes or successfully saves!
  void clearSizes() {
    productSizes.clear();
    notifyListeners();
  }


  void updateBuyingPrice(String value) {
    _buyingPrice = double.tryParse(value) ?? 0.0;
    notifyListeners();
  }

  void updateSellingPrice(String value) {
    _sellingPrice = double.tryParse(value) ?? 0.0;
    notifyListeners();
  }

  // Dispose controllers
  @override
  void dispose() {
    productName.dispose();
    productDescription.dispose();
    productNameAr.dispose();
    productDescriptionAr.dispose();
    productBuyingPrice.dispose();
    productSellingPrice.dispose();
    productCategory.dispose();
    productQuantity.dispose();
    productSupplier.dispose();
    discount.dispose();
    super.dispose();
  }

  void clear (){
    productName.clear();
    productName.clear();
    productDescription.clear();
    productNameAr.clear();
    productDescriptionAr.clear();
    productColors.clear();
    productSizes.clear();
    productBuyingPrice.clear();
    productSellingPrice.clear();
    productCategory.clear();
    productQuantity.clear();
    productSupplier.clear();
    discount.clear();
  }
}

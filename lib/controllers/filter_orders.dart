import 'package:flutter/material.dart';

class GovernorateProvider with ChangeNotifier {
  String? _selectedQuery;

  String? get selectedGovernorate => _selectedQuery;

  void selectGovernorate(String governorate) {
    _selectedQuery = governorate;
    notifyListeners();
  }

  void searchByCustomer(String query){
    _selectedQuery = query;
    notifyListeners();
  }

  void selectPayment(String query) {
    _selectedQuery = query;
    notifyListeners();
  }

  void removeFilter (){
    _selectedQuery = null;
    notifyListeners();
  }
}

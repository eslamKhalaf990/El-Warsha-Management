import 'package:flutter/foundation.dart';
import 'package:warsha_app/views/shell/destinations.dart';

/// Which top-level page is showing.
class NavigationVM extends ChangeNotifier {
  AppDestination _current = AppDestination.dashboard;

  AppDestination get current => _current;

  void go(AppDestination destination) {
    if (destination == _current) return;
    _current = destination;
    notifyListeners();
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateDragDropController extends ChangeNotifier {
  Uint8List? droppedBytes;
  String? droppedFileName;
  bool isLoading = false;

  /// True once the user picked a new image; only then is it uploaded.
  bool changed = false;

  void updateDropFile(Uint8List bytes, String name) {
    droppedBytes = bytes;
    droppedFileName = name;
    changed = true;
    notifyListeners();
  }

  Future<void> loadFromUrl(String url, {String? fileName}) async {
    try {
      isLoading = true;
      changed = false;
      notifyListeners();
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        droppedBytes = response.bodyBytes;
        droppedFileName = fileName ?? url.split('/').last;
        notifyListeners();
      } else {
        debugPrint("Failed to load image from $url, status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error loading image from $url: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    droppedBytes = null;
    droppedFileName = null;
    changed = false;
    notifyListeners();
  }
}

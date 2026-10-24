import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdateDragDropController extends ChangeNotifier {
  Uint8List? droppedBytes;
  String? droppedFileName;
  bool isLoading = false;

  /// True only when the user dropped/browsed a new file that must be uploaded
  bool isNewFile = false;

  /// Set when the user picked an existing image from the library
  String? libraryFilename;

  void updateDropFile(Uint8List bytes, String name) {
    droppedBytes = bytes;
    droppedFileName = name;
    isNewFile = true;
    libraryFilename = null;
    notifyListeners();
  }

  /// Picks an existing library image (no upload needed, just assign it)
  Future<void> selectFromLibrary(String filename, String url) async {
    await loadFromUrl(url, fileName: filename);
    libraryFilename = filename;
    notifyListeners();
  }

  Future<void> loadFromUrl(String url, {String? fileName}) async {
    isNewFile = false;
    libraryFilename = null;
    droppedBytes = null;
    droppedFileName = null;
    if (url.isEmpty) {
      notifyListeners();
      return;
    }
    try {
      isLoading = true;
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
    isNewFile = false;
    libraryFilename = null;
    notifyListeners();
  }
}

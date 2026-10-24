import 'package:warsha_app/services/base_url.dart';

class ImageHelper {
  static String? extractFileId(String url) {
    try {
      Uri uri = Uri.parse(url);
      // Check if 'id' parameter exists
      if (uri.queryParameters.containsKey('id')) {
        return uri.queryParameters['id'];
      }

      // Handle other formats like: https://drive.google.com/file/d/<id>/view
      final regex = RegExp(r'/d/([a-zA-Z0-9_-]+)');
      final match = regex.firstMatch(uri.path);
      if (match != null) {
        return match.group(1);
      }
    } catch (e) {
      print("Invalid URL: $e");
    }
    return null;
  }

  /// Turns a backend imageUrl ("/images/abc.jpg") into a full URL.
  /// Absolute URLs are returned unchanged; empty or "-" gives "".
  static String fullUrl(String? path) {
    if (path == null || path.isEmpty || path == "-") return "";
    if (path.startsWith("http")) return path;
    final base = Baseurl.baseURL.endsWith("/")
        ? Baseurl.baseURL.substring(0, Baseurl.baseURL.length - 1)
        : Baseurl.baseURL;
    return path.startsWith("/") ? "$base$path" : "$base/$path";
  }
}

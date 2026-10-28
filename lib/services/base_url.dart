class Baseurl {
  /// Override per build: flutter run --dart-define=API_BASE_URL=https://api.example.com/
  static const String baseURL = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/',
  );
  // static String baseURL = "https://research-mlb-potentially-frequently.trycloudflare.com/"; // PROD
  // static String baseURLImages = "${baseURL}api/files/"; // PROD
  //
  // static String baseURL = "https://mice-arrested-certificates-vocabulary.trycloudflare.com/"; // DEV
  // static String baseURLImages = "https://eminem-weights-mit-trademarks.trycloudflare.com"; // DEV

  /// =============== Authentication APIs ============== ///
  static String loginApi = '${baseURL}auth/login';
  /// =============== Authentication APIs ============== ///


  /// ===============   Orders APIs    ============== ///
  // Order endpoints live in OrdersService (relative to baseURL).
  static String invoiceAPI = '${baseURL}invoice/pdf';
  /// ===============   Orders APIs    ============== ///

  // Every other endpoint lives in its service, relative to [baseURL].
}

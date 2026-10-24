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

  /// ===============   Customers APIs    ============== ///
  static String getAllCustomersAPI = '${baseURL}customers';
  static String addCustomerAPI = '${baseURL}customers';
  static String updateCustomerAPI = '${baseURL}customers';
  static String deleteCustomerAPI = '${baseURL}customers';
  static String countGovernoratePerCustomerAPI = '${baseURL}customers/countsByGovernorate';
  /// ===============   Customers APIs    ============== ///

  /// ===============   Orders APIs    ============== ///
  // Order endpoints live in OrdersService (relative to baseURL).
  static String invoiceAPI = '${baseURL}invoice/pdf';
  /// ===============   Orders APIs    ============== ///

  /// ===============   Products APIs    ============== ///
  static String getAllProductsAPI = '${baseURL}products';
  static String getAllCategoriesAPI = '${baseURL}category';
  static String addProductAPI = '${baseURL}products';
  static String updateProductAPI = '${baseURL}products';
  static String deleteProductAPI = '${baseURL}products';
  static String addCategoryAPI = '${baseURL}category';
  /// ===============   Products APIs    ============== ///

  /// ===============   Cash Flow APIs    ============== ///
  static String getRevenueSummaryAPI = '${baseURL}cashFlow/revenueSummary';
  static String getDailyCashFlowAPI = '${baseURL}cashFlow/daily';
  static String getTotalSoldProductsAPI = '${baseURL}cashFlow/topSoldProducts';

  // --- Customer Analysis Endpoints ---
  static String getLoyalCustomersAPI = '${baseURL}cashFlow/analysis/customers/loyalty';
  static String getVipCustomersAPI = '${baseURL}cashFlow/analysis/customers/vip';
  static String getAtRiskCustomersAPI = '${baseURL}cashFlow/analysis/customers/at-risk';
  static String getDiscountSeekersAPI = '${baseURL}cashFlow/analysis/discount-seekers';

  // --- NEW: Sales & Market Performance Endpoints ---
  static String getAverageBasketSizeAPI = '${baseURL}cashFlow/analysis/kpi/average-basket-size';
  static String getRevenueBySourceAPI = '${baseURL}cashFlow/analysis/revenue-by-source';
  static String getTopPerformersAPI = '${baseURL}cashFlow/analysis/products/top-performers';
  static String getGovernoratePerformanceAPI = '${baseURL}cashFlow/analysis/governorate-performance';
  static String getDailyRevenueReportAPI = '${baseURL}cashFlow/analysis/daily-revenue-report';
  /// ===============   Cash Flow APIs    ============== ///

  /// ===============   Accounting APIs    ============== ///
  static String getAccountsBalanceAPI = '${baseURL}api/bank/accounts';
  static String addTransactionAPI = '${baseURL}api/bank/transaction';
  static String getTransactionsAPI = '${baseURL}api/bank/transactions';
  static String getTransactionCategoriesAPI = '${baseURL}api/bank/transactionCategories';
  static String deleteAllTransactionsAPI = '${baseURL}api/bank/resetTransactions';
  /// ===============   Accounting APIs    ============== ///

  /// ===============   Vendors APIs    ============== ///
  static String getVendorsAPI = '${baseURL}vendors';
  static String addVendorAPI = '${baseURL}vendors';
  static String updateVendorAPI = '${baseURL}vendors';
  static String deleteVendorAPI = '${baseURL}vendors';
  /// ===============   Vendors APIs    ============== ///

  /// ===============   Shipping Zones APIs    ============== ///
  static String getAllShippingZonesAPI = '${baseURL}shipping';
  static String addShippingZoneAPI = '${baseURL}shipping';
  static String updateShippingZoneAPI = '${baseURL}shipping';
  static String deleteShippingZoneAPI = '${baseURL}shipping';
  /// ===============   Shipping Zones APIs    ============== ///
}

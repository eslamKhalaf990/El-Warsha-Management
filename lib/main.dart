import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/controllers/add_order/add_customer.dart';
import 'package:warsha_app/controllers/add_order/add_product.dart';
import 'package:warsha_app/controllers/drag_drop_controller.dart';
import 'package:warsha_app/controllers/navigation.dart';
import 'package:warsha_app/controllers/update_drag_drop.dart';
import 'package:warsha_app/controllers/update_order/updatePaymentDetails.dart';
import 'package:warsha_app/controllers/update_order/update_customer.dart';
import 'package:warsha_app/services/accounting_service.dart';
import 'package:warsha_app/services/category_service.dart';
import 'package:warsha_app/services/customers_services.dart';
import 'package:warsha_app/services/home_service.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/services/product_images_service.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';
import 'package:warsha_app/services/user_service.dart';
import 'package:warsha_app/services/vendors_service.dart';
import 'package:warsha_app/utils/navigator.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/view_models/add_order_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/home_v_m.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';
import 'package:warsha_app/view_models/update_order_v_m.dart';
import 'package:warsha_app/view_models/update_product_v_m.dart';
import 'package:warsha_app/view_models/user_v_m.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';
import 'package:warsha_app/views/auth/auth_gate.dart';
import 'controllers/add_order/add_payment.dart';
import 'controllers/filter_orders.dart';
import 'controllers/transaction_provider.dart';
import 'controllers/update_order/update_product.dart';
import 'view_models/order_v_m.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // App-lifetime objects: the HTTP client and the login session.
  final apiClient = ApiClient();
  final userViewModel = UserViewModel(UserService(apiClient));
  apiClient
    ..tokenProvider = (() => userViewModel.isAuthenticated ? userViewModel.token : null)
    ..onUnauthorized = userViewModel.handleSessionExpired;
  userViewModel.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<UserViewModel>.value(value: userViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

/// Everything that holds data for the logged-in user. It is rebuilt from
/// scratch whenever [UserViewModel.sessionEpoch] changes (login / logout), so
/// nothing leaks from one session into the next.
class SessionScope extends StatelessWidget {
  const SessionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final epoch = context.select<UserViewModel, int>((vm) => vm.sessionEpoch);
    return MultiProvider(
      key: ValueKey(epoch),
      providers: [
        ChangeNotifierProvider(create: (_) => DragDropController()),
        ChangeNotifierProvider(create: (_) => UpdateDragDropController()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => Navigation()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => UpdateCustomerProvider()),
        ChangeNotifierProvider(create: (_) => UpdatePaymentDetails()),
        ChangeNotifierProvider(create: (_) => UpdateProductProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => GovernorateProvider()),
        ChangeNotifierProvider(create: (_) => TransactionsProvider()),

        // Services
        Provider<ProductService>(create: (_) => ProductService()),
        Provider<VendorService>(create: (_) => VendorService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<ShippingZoneService>(create: (_) => ShippingZoneService()),
        Provider<AccountingService>(create: (_) => AccountingService()),
        Provider<HomeService>(create: (_) => HomeService()),
        Provider<OrdersService>(
          create: (context) => OrdersService(context.read<ApiClient>()),
        ),
        Provider<CustomerService>(create: (_) => CustomerService()),
        Provider<ProductVariantsService>(
          create: (context) => ProductVariantsService(context.read<ApiClient>()),
        ),
        Provider<ProductImagesService>(
          create: (context) => ProductImagesService(context.read<ApiClient>()),
        ),

        // View models
        ChangeNotifierProvider<OrderVM>(
          create: (context) => OrderVM(context.read<OrdersService>())..fetchOrders(),
        ),
        ChangeNotifierProvider<ProductVM>(
          create: (context) => ProductVM(
            context.read<ProductService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<VendorVM>(
          create: (context) => VendorVM(
            context.read<VendorService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<CategoryVM>(
          create: (context) => CategoryVM(
            context.read<CategoryService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<ShippingZoneVM>(
          create: (context) => ShippingZoneVM(
            context.read<ShippingZoneService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<AddOrderVM>(
          create: (context) => AddOrderVM(context.read<OrdersService>()),
        ),
        ChangeNotifierProvider<UpdateOrderVM>(
          create: (_) => UpdateOrderVM(),
        ),
        ChangeNotifierProvider<UpdateProductVM>(
          create: (context) => UpdateProductVM(
            context.read<ProductService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<CustomerVM>(
          create: (context) => CustomerVM(
            context.read<CustomerService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<HomeVM>(
          create: (context) => HomeVM(
            context.read<HomeService>(),
            context.read<UserViewModel>(),
          ),
        ),
        ChangeNotifierProvider<AccountingVM>(
          create: (context) => AccountingVM(
            context.read<AccountingService>(),
            context.read<UserViewModel>(),
          ),
        ),
      ],
      child: child,
    );
  }
}

ThemeData onyxTheme = ThemeData(
  fontFamily: 'cairo',
  useMaterial3: true,
  brightness: Brightness.light,

  // 1. The Core Palette: Black, White, and Grey
  colorScheme: ColorScheme.light(
    primary: Colors.black,       // Main Buttons & Active States
    onPrimary: Colors.white,     // Text on Black buttons

    secondary: Colors.grey.shade800, // Secondary actions
    onSecondary: Colors.white,

    tertiary: Colors.black,      // Added tertiary for consistency with some widgets
    onTertiary: Colors.white,

    // Backgrounds: Using a very subtle off-white for depth
    surface: Colors.white,
    onSurface: const Color(0xFF333333), // Light black for text

    surfaceContainerHighest: Colors.grey.shade100, // For input fills or table headers
    outline: Colors.grey.shade300, // Subtle borders

    error: const Color(0xFFC52828), // Keep red ONLY for errors
  ),

  // 2. Background Color (The Canvas)
  scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Slightly off-white/grey for ERP feel

  // 3. Selection Theme (Matches the Black aesthetic)
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.black,
    selectionColor: Colors.black.withAlpha(20), // Subtle grey highlight
    selectionHandleColor: Colors.black,
  ),

  // 4. Card Theme (Consistent 15 radius as requested)
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    color: Colors.white,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),

  // 5. Input Fields (Clean, Sharp, Professional)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

    // Default Border
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),

    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),

    // Active Border (Black)
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.black, width: 1.5),
    ),

    // Label Text Style
    labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
  ),

  // 6. Buttons (High Contrast, 15 radius)
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),

  // 7. Text Theme (Light Black Color)
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600),
    titleLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Color(0xFF333333)),
    bodyMedium: TextStyle(color: Color(0xFF333333)),
    labelLarge: TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w500),
  ),

  // 8. Data Tables (The heart of an ERP)
  dataTableTheme: DataTableThemeData(
    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
    headingTextStyle: const TextStyle(
      fontWeight: FontWeight.w700,
      color: Color(0xFF333333),
      letterSpacing: 0.5,
    ),
    dataRowColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return Colors.grey.shade100;
      }
      return Colors.white;
    }),
    dividerThickness: 1, 
    horizontalMargin: 12,
    columnSpacing: 24,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Warsha ERP',
      theme: onyxTheme,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // Session providers wrap the navigator so every route can read them.
      builder: (context, child) => SessionScope(child: child!),
      home: const AuthGate(),
    );
  }
}

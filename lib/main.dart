import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/network/api_client.dart';
import 'package:warsha_app/core/theme/app_theme.dart';
import 'package:warsha_app/views/auth/auth_gate.dart';
import 'package:warsha_app/views/shell/navigation_v_m.dart';
import 'package:warsha_app/services/accounting_service.dart';
import 'package:warsha_app/services/category_service.dart';
import 'package:warsha_app/services/customers_services.dart';
import 'package:warsha_app/services/home_service.dart';
import 'package:warsha_app/services/orders_service.dart';
import 'package:warsha_app/services/product_images_service.dart';
import 'package:warsha_app/services/product_variants_service.dart';
import 'package:warsha_app/services/products_service.dart';
import 'package:warsha_app/services/reviews_service.dart';
import 'package:warsha_app/services/shipping_zone_service.dart';
import 'package:warsha_app/services/user_service.dart';
import 'package:warsha_app/services/vendors_service.dart';
import 'package:warsha_app/services/vouchers_service.dart';
import 'package:warsha_app/view_models/accountings_v_m.dart';
import 'package:warsha_app/view_models/add_product_v_m.dart';
import 'package:warsha_app/view_models/category_v_m.dart';
import 'package:warsha_app/view_models/customers_v_m.dart';
import 'package:warsha_app/view_models/home_v_m.dart';
import 'package:warsha_app/view_models/order_v_m.dart';
import 'package:warsha_app/view_models/reviews_v_m.dart';
import 'package:warsha_app/view_models/shipping_zone_v_m.dart';
import 'package:warsha_app/view_models/user_v_m.dart';
import 'package:warsha_app/view_models/vendors_v_m.dart';
import 'package:warsha_app/view_models/vouchers_v_m.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Room for a few product grids' worth of decoded photos (default 100 MB),
  // so images scrolled out of view are still there when scrolled back.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20;

  // App-lifetime objects: the HTTP client and the login session.
  final apiClient = ApiClient();
  final userViewModel = UserViewModel(UserService(apiClient));
  apiClient
    ..tokenProvider = (() => userViewModel.isAuthenticated ? userViewModel.token : null)
    ..onUnauthorized = userViewModel.handleSessionExpired;

  // When the session ends, close every page and dialog opened on top so the
  // login page shows.
  userViewModel.addListener(() {
    if (!userViewModel.isAuthenticated) navigatorKey.currentState?.popUntil((route) => route.isFirst);
  });
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
    final signedIn = context.select<UserViewModel, bool>((vm) => vm.isAuthenticated);
    T api<T>(BuildContext c, T Function(ApiClient api) create) => create(c.read<ApiClient>());

    return MultiProvider(
      key: ValueKey(epoch),
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationVM()),

        // Services
        Provider(create: (c) => api(c, ProductService.new)),
        Provider(create: (c) => api(c, ProductVariantsService.new)),
        Provider(create: (c) => api(c, ProductImagesService.new)),
        Provider(create: (c) => api(c, VendorService.new)),
        Provider(create: (c) => api(c, CategoryService.new)),
        Provider(create: (c) => api(c, ShippingZoneService.new)),
        Provider(create: (c) => api(c, AccountingService.new)),
        Provider(create: (c) => api(c, HomeService.new)),
        Provider(create: (c) => api(c, OrdersService.new)),
        Provider(create: (c) => api(c, CustomerService.new)),
        Provider(create: (c) => api(c, ReviewsService.new)),
        Provider(create: (c) => api(c, VouchersService.new)),

        // View models load as soon as someone is signed in.
        ChangeNotifierProvider(create: (c) => _load(signedIn, OrderVM(c.read()), (vm) => vm.fetchOrders())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, ProductVM(c.read(), c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, VendorVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, CategoryVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, ShippingZoneVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, CustomerVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, HomeVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, AccountingVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, ReviewsVM(c.read()), (vm) => vm.fetch())),
        ChangeNotifierProvider(create: (c) => _load(signedIn, VouchersVM(c.read()), (vm) => vm.fetch())),
      ],
      child: child,
    );
  }

  static T _load<T>(bool signedIn, T vm, Future<void> Function(T vm) fetch) {
    if (signedIn) fetch(vm);
    return vm;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Warsha · Back office',
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // Session providers wrap the navigator so every route can read them.
      builder: (context, child) => SessionScope(child: child!),
      home: const AuthGate(),
    );
  }
}

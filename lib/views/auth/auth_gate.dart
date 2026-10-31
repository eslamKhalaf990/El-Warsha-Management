import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/auth/login_page.dart';
import 'package:warsha_app/views/shell/app_shell.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

/// Root route: a splash while the saved session is restored, then the app or
/// the login page. (Routes left open when a session ends are closed in main.)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>();
    if (user.isRestoring) return const _Splash();
    if (user.isAuthenticated) return const AppShell();
    return ChangeNotifierProvider(
      create: (_) => FormDraft(values: {'showPassword': false}),
      child: const LoginPage(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 72),
            SizedBox(height: AppSpacing.s24),
            SizedBox(width: 120, child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

/// The round store logo with an optional wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.showName = false, this.light = false});

  final double size;
  final bool showName;

  /// White wordmark, for the burgundy login panel.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
      child: ClipOval(child: Image.asset('assets/images/logo-no-back.png', fit: BoxFit.contain)),
    );
    if (!showName) return logo;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: AppSpacing.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText.titleSmall('EL WARSHA', color: light ? AppColors.white : AppColors.deepWine),
            AppText.caption('Back office', color: light ? AppColors.champagne : AppColors.muted),
          ],
        ),
      ],
    );
  }
}

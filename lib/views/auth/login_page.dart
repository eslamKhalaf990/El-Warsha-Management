import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/state/form_draft.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/auth/auth_gate.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

/// Sign-in. On wide screens a burgundy brand panel sits beside the form.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = context.isExpanded;
    return Scaffold(
      body: Row(
        children: [
          if (wide) const Expanded(child: _BrandPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const _LoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.burgundy,
      padding: const EdgeInsets.all(AppSpacing.s48),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandLogo(size: 48, showName: true, light: true),
          Spacer(),
          AppText.headline('Run the workshop\nfrom one place.', color: AppColors.white),
          SizedBox(height: AppSpacing.s12),
          AppText.body('Orders, stock, customers and cash, in sync with the online store.', color: AppColors.blush),
          Spacer(),
          AppText.caption('© El Warsha', color: AppColors.champagne),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm();

  Future<void> _submit(BuildContext context) async {
    final draft = context.read<FormDraft>();
    final user = context.read<UserViewModel>();
    if (user.isLoading) return;
    // On success AuthGate swaps to the app; on failure the message shows below.
    await user.login(draft.text('username'), draft.text('password'));
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<FormDraft>();
    final user = context.watch<UserViewModel>();
    final message = user.errorMessage ?? user.logoutReason;
    final showPassword = draft.flag('showPassword');

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!context.isExpanded) ...[
            const Center(child: BrandLogo(size: 72)),
            const SizedBox(height: AppSpacing.s24),
          ],
          const AppText.headline('Welcome back'),
          const SizedBox(height: AppSpacing.s4),
          const AppText.body('Sign in to the El Warsha back office.', color: AppColors.muted),
          const SizedBox(height: AppSpacing.s32),
          if (message != null) ...[
            InlineBanner(
              message: message,
              tone: user.errorMessage != null ? Tone.error : Tone.info,
              icon: user.errorMessage != null ? Iconsax.warning_2_copy : Iconsax.info_circle_copy,
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
          AppTextField(
            label: 'Username',
            icon: Iconsax.user_copy,
            controller: draft.controller('username'),
            autofocus: true,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            label: 'Password',
            icon: Iconsax.lock_1_copy,
            controller: draft.controller('password'),
            obscureText: !showPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _submit(context),
            suffix: IconButton(
              tooltip: showPassword ? 'Hide password' : 'Show password',
              icon: Icon(showPassword ? Iconsax.eye_slash_copy : Iconsax.eye_copy, size: 20),
              onPressed: () => draft.set('showPassword', !showPassword),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          AppButton.primary(
            label: 'Sign in',
            icon: Iconsax.login_copy,
            loading: user.isLoading,
            expand: true,
            onPressed: () => _submit(context),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/utils/default_button.dart';
import 'package:warsha_app/utils/default_text.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  /// On success AuthGate swaps to Home automatically; on failure show why.
  Future<void> _submit() async {
    final userVM = context.read<UserViewModel>();
    if (userVM.isLoading) return;
    final ok = await userVM.login(username.text, password.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
        SnackBar(
          content: Text(userVM.errorMessage ?? 'Failed to login'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoutReason = context.select<UserViewModel, String?>((vm) => vm.logoutReason);

    return Scaffold(
      body: Container(
        child: Stack(
          children: [
            // Right side: Image takes half
            Padding(
              padding: const EdgeInsets.only(left: 300.0),
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  "assets/images/low-poly-abstract-design.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Left side: Login Card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary.withAlpha(120),
                borderRadius: Constants.BORDER_RADIUS_25,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: Constants.BORDER_RADIUS_100,
                    child: Image.asset(
                      "assets/images/logo-no-back.png",
                      width: 150,
                      height: 140,
                    ),
                  ),
                  const DefaultText(
                    txt: "EL WARSHA ERP",
                    size: 26,
                    bold: true,
                  ),
                  const SizedBox(height: 30),

                  if (logoutReason != null) ...[
                    SizedBox(
                      width: 400,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: Constants.BORDER_RADIUS_15,
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Iconsax.info_circle, size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: DefaultText(txt: logoutReason)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],

                  // Email
                  SizedBox(
                    width: 400,
                    child: LoginForm(
                      icon: Iconsax.sms_copy,
                      controller: username,
                      title: "Email",
                      isPassword: false,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password
                  SizedBox(
                    width: 400,
                    child: LoginForm(
                      icon: Iconsax.key_copy,
                      controller: password,
                      title: "Password",
                      isPassword: true,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.only(right: 200.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DefaultText(txt: "Remember me"),
                        SizedBox(width: 10),
                        Icon(Iconsax.tick_square_copy, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: 400,
                    child: Consumer<UserViewModel>(
                      builder: (context, userVM, child) => DefaultButton(
                        onTap: _submit,
                        height: 45,
                        title: "Login",
                        isValid: !userVM.isLoading,
                        isLoading: userVM.isLoading,
                        margin: EdgeInsets.zero,
                        border: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key, required this.icon, required this.title, required this.controller, required this.isPassword, this.onSubmitted});
  final IconData icon;
  final ValueChanged<String>? onSubmitted;
  final String title;
  final bool isPassword;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      onFieldSubmitted: onSubmitted,
      textInputAction: TextInputAction.done,
      cursorColor: Theme.of(context)
          .colorScheme
          .tertiary
          .withAlpha(Constants.OPACITY_05),
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.onPrimary,
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_50),
        errorStyle: TextStyle(color: Colors.red.shade300),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Icon(icon),
        ),
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: Constants.BORDER_RADIUS_50),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: Constants.BORDER_RADIUS_50),
        hintText: title,
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}

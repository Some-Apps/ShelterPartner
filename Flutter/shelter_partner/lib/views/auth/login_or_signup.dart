import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/views/auth/auth_page.dart';
import 'package:shelter_partner/views/auth/forgot_password_page.dart';
import 'package:shelter_partner/views/auth/login_page.dart';
import 'package:shelter_partner/views/auth/signup_page.dart';

class LoginOrSignup extends ConsumerWidget {
  const LoginOrSignup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the current page state
    final currentPage = ref.watch(authPageProvider);

    // Methods to navigate between pages
    void navigateToLogin() {
      ref.read(authPageProvider.notifier).setPage(AuthPageType.login);
    }

    void navigateToSignup() {
      ref.read(authPageProvider.notifier).setPage(AuthPageType.signup);
    }

    void navigateToForgotPassword() {
      ref.read(authPageProvider.notifier).setPage(AuthPageType.forgotPassword);
    }

    switch (currentPage) {
      case AuthPageType.login:
        return LoginPage(
          onTapSignup: navigateToSignup,
          onTapForgotPassword: navigateToForgotPassword,
        );
      case AuthPageType.signup:
        return SignupPage(onTapLogin: navigateToLogin);
      case AuthPageType.forgotPassword:
        return ForgotPasswordPage(onTapLogin: navigateToLogin);
      default:
        return LoginPage(
          onTapSignup: navigateToSignup,
        );
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shelter_partner/pages/forgot_password_page.dart';
import 'package:shelter_partner/pages/login_page.dart';
import 'package:shelter_partner/pages/signup_page.dart';

enum AuthPage { login, signup, forgotPassword }

class LoginOrSignup extends StatefulWidget {
  const LoginOrSignup({super.key});

  @override
  State<LoginOrSignup> createState() => _LoginOrSignupState();
}

class _LoginOrSignupState extends State<LoginOrSignup> {
  // Use an enum to manage which page is active
  AuthPage currentPage = AuthPage.login;

  void navigateToLogin() {
    setState(() {
      currentPage = AuthPage.login;
    });
  }

  void navigateToSignup() {
    setState(() {
      currentPage = AuthPage.signup;
    });
  }

  void navigateToForgotPassword() {
    setState(() {
      currentPage = AuthPage.forgotPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (currentPage) {
      case AuthPage.login:
        return LoginPage(
          onTapSignup: navigateToSignup,
          onTapForgotPassword: navigateToForgotPassword,
        );
      case AuthPage.signup:
        return SignupPage(onTapLogin: navigateToLogin);
      case AuthPage.forgotPassword:
        return ForgotPasswordPage(onTapLogin: navigateToLogin);
      default:
        return LoginPage(
          onTapSignup: navigateToSignup,
        );
    }
  }
}

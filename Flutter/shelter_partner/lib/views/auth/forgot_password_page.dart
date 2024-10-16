import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shelter_partner/views/auth/my_button.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  final void Function()? onTapLogin;

  const ForgotPasswordPage({super.key, required this.onTapLogin});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final emailController = TextEditingController();

  // Method to send password reset email
  void resetPassword() async {
    String email = emailController.text.trim();

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call the sendPasswordReset method in AuthViewModel
    final errorMessage =
        await ref.read(authViewModelProvider.notifier).sendPasswordReset(email);

    // Close the loading indicator
    Navigator.of(context).pop();

    if (errorMessage == null) {
      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Success"),
          content: const Text(
              "A password reset email has been sent. Please check your inbox."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                widget.onTapLogin?.call(); // Go back to login page
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      Future.microtask(() {
        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      });
      // Show error message if something goes wrong
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: const Text("Error"),
      //     content: Text(errorMessage),
      //     actions: [
      //       TextButton(
      //         onPressed: () {
      //           Navigator.of(context).pop(); // Close the dialog
      //         },
      //         child: const Text("OK"),
      //       ),
      //     ],
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Image.asset("assets/images/logo.png", height: 100),
                  const SizedBox(height: 50),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 25),
                  MyButton(
                    title: "Reset Password",
                    onTap: resetPassword,
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Remember your password?'),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTapLogin,
                        child: const Text(
                          'Go Back To Login',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

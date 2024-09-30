import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/components/my_button.dart';
import 'package:shelter_partner/components/my_textfield.dart';
import 'package:shelter_partner/helper/helper_function.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  final void Function()? onTapLogin;

  ForgotPasswordPage({super.key, required this.onTapLogin});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  // Method to send password reset email
  void resetPassword() async {
    String email = emailController.text.trim();

    // Show a loading indicator (optional)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Send password reset email using Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success message
      Navigator.of(context).pop(); // To remove the loading indicator
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
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); // To remove the loading indicator

      // Show error message if something goes wrong
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Error"),
          content: Text(e.message ?? "An error occurred. Please try again."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),

              // logo
              Image.asset("lib/images/logo.png", height: 100),

              const SizedBox(height: 50),

              // email textfield
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              const SizedBox(height: 25),

              // Reset password button
              MyButton(
                title: "Reset Password",
                onTap: resetPassword,
              ),

              const SizedBox(height: 50),

              // Go back to login
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
              )
            ],
          ),
        ),
      ),
    );
  }
}

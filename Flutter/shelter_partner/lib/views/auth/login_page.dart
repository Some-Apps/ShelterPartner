import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';

class LoginPage extends ConsumerStatefulWidget {
  final void Function()? onTapSignup;
  final void Function()? onTapForgotPassword;

  const LoginPage({super.key, this.onTapSignup, this.onTapForgotPassword});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    await ref
        .read(authViewModelProvider.notifier)
        .login(emailController.text.trim(), passwordController.text.trim());
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        // In debug mode (including tests), show image directly without spinner
                        if (kDebugMode) {
                          return Image.asset(
                            "assets/images/square_logo.png",
                            width: 250,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  width: 250,
                                  height: 250,
                                  child: Icon(
                                    Icons.pets,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                ),
                          );
                        }

                        // Production mode - use FutureBuilder with spinner
                        return FutureBuilder(
                          future: precacheImage(
                            const AssetImage("assets/images/square_logo.png"),
                            context,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return Image.asset(
                                "assets/images/square_logo.png",
                                width: 250,
                              );
                            } else {
                              return const SizedBox(
                                width: 250,
                                height: 250,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const Text(
                      "Welcome Back!",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 25),

                    MyTextField(
                      controller: emailController,
                      hintText: 'Email',
                      obscureText: false,
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 10),
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      onSubmitted: (_) => login(),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: login,
                      child: const Text("Log In"),
                    ),
                    // MyButton(
                    //   title: "Log In",
                    //   onTap: login,
                    // ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onTapForgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'New to ShelterPartner?',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: widget.onTapSignup,
                              child: const Text(
                                'Create Shelter',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }
}

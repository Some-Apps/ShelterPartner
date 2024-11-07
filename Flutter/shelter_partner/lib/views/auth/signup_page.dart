import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shelter_partner/views/auth/my_button.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';
import 'package:uuid/uuid.dart';
import 'package:shelter_partner/helper/debug.dart';

import 'package:shelter_partner/view_models/auth_view_model.dart';

class SignupPage extends ConsumerStatefulWidget {
  final void Function()? onTapLogin;
  DebugHelper debugHelper;

  SignupPage({super.key, required this.onTapLogin, DebugHelper? debugHelper})
      : debugHelper = debugHelper ?? DebugHelper();
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final shelterNameController = TextEditingController();
  final shelterAddressController = TextEditingController();

  final List<String> managementSoftwareOptions = [
    'ShelterLuv',
    'ShelterManager',
    'Rescue Groups',
    'ShelterBuddy',
    'PetPoint',
    'Chameleon',
    'Other'
  ];
  String selectedManagementSoftware = 'ShelterLuv';

  void signup() async {
    if (passwordController.text != confirmPasswordController.text) {
      Fluttertoast.showToast(
        msg: 'Passwords don\'t match',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }
    await ref.read(authViewModelProvider.notifier).signup(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          shelterName: shelterNameController.text.trim(),
          shelterAddress: shelterAddressController.text.trim(),
          selectedManagementSoftware: selectedManagementSoftware,
        );
  }

  void createAndLoginTestAccount() async {
    if (widget.debugHelper.isDebugMode() == false) {
      return;
    }
    const uuid = Uuid();
    final testEmail = '${uuid.v4()}@example.com';
    const testPassword = 'password123';
    await ref.read(authViewModelProvider.notifier).signup(
          email: testEmail,
          password: testPassword,
          firstName: 'Test',
          lastName: 'User',
          shelterName: 'Test Shelter',
          shelterAddress: '123 Test St',
          selectedManagementSoftware: 'ShelterLuv',
        );
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
                    controller: firstNameController,
                    hintText: 'First Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: lastNameController,
                    hintText: 'Last Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: shelterNameController,
                    hintText: 'Shelter Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  MyTextField(
                    controller: shelterAddressController,
                    hintText: 'Shelter Address',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Management Software',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedManagementSoftware,
                    items: managementSoftwareOptions.map((String software) {
                      return DropdownMenuItem<String>(
                        value: software,
                        child: Text(software),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedManagementSoftware = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 25),
                  MyButton(
                    title: "Create Shelter",
                    onTap: signup,
                  ),
                  if (widget.debugHelper.isDebugMode())
                    MyButton(
                      title: "Create Test Account",
                      onTap: createAndLoginTestAccount,
                    ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTapLogin,
                        child: const Text(
                          'Login Here',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

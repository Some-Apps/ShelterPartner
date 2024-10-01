import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shelter_partner/views/auth/my_button.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';
import 'package:http/http.dart' as http;
import 'package:shelter_partner/helper/helper_function.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class SignupPage extends StatefulWidget {
  final void Function()? onTapLogin;

  SignupPage({super.key, required this.onTapLogin});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final shelterNameController = TextEditingController();
  final shelterAddressController = TextEditingController();

  // Management software options
  final List<String> managementSoftwareOptions = [
    'ShelterLuv',
    'ShelterManager',
    'Rescue Groups',
    'ShelterBuddy',
    'PetPoint',
    'Chameleon',
    'Other'
  ];
  String selectedManagementSoftware = 'ShelterLuv'; // Default value

  @override
  void dispose() {
    // Dispose controllers to free up resources
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    shelterNameController.dispose();
    shelterAddressController.dispose();
    super.dispose();
  }

  // Function to display messages to the user
  void displayMessageToUser(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

void signupUser() async {
  showDialog(
    context: context,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  if (passwordController.text != confirmPasswordController.text) {
    Navigator.pop(context); // Close the loading dialog
    displayMessageToUser("Passwords don't match!", context);
    return;
  }

  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text,
    );


    String? idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (idToken == null) {
      Navigator.pop(context);
      displayMessageToUser("Unable to obtain ID token.", context);
      return;
    }

    Map<String, dynamic> data = {
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'email': emailController.text.trim(),
      'shelter_name': shelterNameController.text.trim(),
      'management_software': selectedManagementSoftware,
      'shelter_address': shelterAddressController.text.trim(),
    };

    final response = await http.post(
      Uri.parse('https://us-central1-pawpartnerdevelopment.cloudfunctions.net/CreateNewShelter'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(data),
    );

    Navigator.pop(context);

    if (response.statusCode == 200) {
      print('Cloud Function Response: ${response.body}');
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
      displayMessageToUser('Error: ${response.statusCode} - ${response.body}', context);
    }
  } on FirebaseAuthException catch (e) {
    Navigator.pop(context); 
    displayMessageToUser(e.message ?? e.code, context);
  } catch (e) {
    Navigator.pop(context); 
    displayMessageToUser("An error occurred. Please try again. $e", context);
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // To prevent overflow
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Add some padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  // Logo
                  Image.asset("lib/images/logo.png", height: 100),
                  const SizedBox(height: 50),
                  // First Name TextField
                  MyTextField(
                    controller: firstNameController,
                    hintText: 'First Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  // Last Name TextField
                  MyTextField(
                    controller: lastNameController,
                    hintText: 'Last Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  // Email TextField
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  // Password TextField
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  // Confirm Password TextField
                  MyTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  // Shelter Name TextField
                  MyTextField(
                    controller: shelterNameController,
                    hintText: 'Shelter Name',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  // Shelter Address TextField
                  MyTextField(
                    controller: shelterAddressController,
                    hintText: 'Shelter Address',
                    obscureText: false,
                  ),
                  const SizedBox(height: 10),
                  // Management Software Dropdown
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
                  // Create Shelter Button
                  MyButton(
                    title: "Create Shelter",
                    onTap: signupUser,
                  ),
                  const SizedBox(height: 50),
                  // Already have an account? Login Here
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

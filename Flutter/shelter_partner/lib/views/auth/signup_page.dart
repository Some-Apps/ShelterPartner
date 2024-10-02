import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shelter_partner/views/auth/my_button.dart';
import 'package:shelter_partner/views/auth/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';

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
      // Firebase Authentication for creating a user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Get the UID of the newly created user
      String uid = userCredential.user!.uid;

      // Generate a shelter ID
      String shelterId = Uuid().v4();

      // Create user document in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': emailController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'shelter_id': shelterId,
        'type': 'admin',
      });

      // Setup shelter data
      await FirebaseFirestore.instance.collection('shelters').doc(shelterId).set({
        'shelter_name': shelterNameController.text.trim(),
        'address': shelterAddressController.text.trim(),
        'management_software': selectedManagementSoftware,
        'createdAt': FieldValue.serverTimestamp(),
        'reportsDay': 'Never',
        'reportsEmail': '',
        'groupOptions': ["Color", "Building", "Behavior"],
        'secondarySortOptions': ["Color", "Building", "Behavior"],
      });

      // Add animals to Firestore
      await addAnimals(shelterId);

      Navigator.pop(context); // Close the loading dialog

      // Navigate to the main page or show success message
      // ...

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      displayMessageToUser(e.message ?? e.code, context);
    } catch (e) {
      Navigator.pop(context);
      displayMessageToUser("An error occurred. Please try again. $e", context);
    }
  }

  Future<void> addAnimals(String shelterId) async {
    List<String> animalTypes = ['cats', 'dogs'];
    for (String animalType in animalTypes) {
      String filename = 'assets/${animalType.toLowerCase()}.csv';
      await uploadDataToFirestore(filename, animalType, shelterId);
    }
  }

  Future<void> uploadDataToFirestore(String filename, String collectionName, String shelterId) async {
    try {
      // Load CSV file from assets
      String csvData = await rootBundle.loadString(filename);
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(csvData, eol: '\n');
      
      // Assuming the first row contains headers
      List<dynamic> headers = rowsAsListOfValues[0];
      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        List<dynamic> row = rowsAsListOfValues[i];
        Map<String, dynamic> rowData = {};
        for (int j = 0; j < headers.length; j++) {
          rowData[headers[j]] = row[j];
        }
        
        // Process rowData similar to the cloud function
        String animalId = rowData['id'].toString();
        List<String> colorGroups = ["Red", "Blue", "Green", "Orange", "Pink", "Yellow", "Brown"];
        List<String> colors = colorGroups.map((color) => color.toLowerCase()).toList();
        List<String> buildingGroups = ["Building 1", "Building 2", "Building 3"];
        List<String> behaviorGroups = ["Example 1", "Example 2", "Example 3", "Example 4"];
        int randomColorIndex = Random().nextInt(colors.length);
        int randomBuildingIndex = Random().nextInt(buildingGroups.length);
        int randomBehaviorIndex = Random().nextInt(behaviorGroups.length);
        
        Map<String, dynamic> data = {
          'alert': rowData['alert'] ?? '',
          'can_play': (rowData['canPlay'] ?? '').toString().toLowerCase() == 'true',
          'symbol_color': colors[randomColorIndex],
          'symbol': 'pawprint.fill',
          'color_group': colorGroups[randomColorIndex],
          'building_group': buildingGroups[randomBuildingIndex],
          'behavior_group': behaviorGroups[randomBehaviorIndex],
          'color_sort': randomColorIndex,
          'building_sort': randomBuildingIndex,
          'behavior_sort': randomBehaviorIndex,
          'id': animalId,
          'in_kennel': (rowData['inKennel'] ?? '').toString().toLowerCase() == 'true',
          'location': rowData['location'] ?? '',
          'name': rowData['name'] ?? '',
          'start_time': FieldValue.serverTimestamp(),
          'created': FieldValue.serverTimestamp(),
          'photos': [],  // Empty since we're not dealing with photos
          'sex': "Male",
          'age': "3 years 4 months",
          'breed': "Example Breed",
          'description': "Hey there, I'm Example! I'm a handsome guy that came to the shelter as a stray. I can be a bit nervous when I meet new people and would do best in a home as the only pet and with no small kids. If you think a handsome cat like me could be the one for you come visit me soon!",
        };
        
        // Add document to Firestore
        await FirebaseFirestore.instance
            .collection('shelters')
            .doc(shelterId)
            .collection(collectionName)
            .doc(animalId)
            .set(data);
        
        print("Added ${collectionName.substring(0, collectionName.length - 1)} '${data['name']}' with ID $animalId to shelter $shelterId");
      }
    } catch (e) {
      print('Error uploading data from $filename: $e');
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
                  Image.asset("assets/images/logo.png", height: 100),
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

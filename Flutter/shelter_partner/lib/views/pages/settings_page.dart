import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(actions: [
          IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))
        ]),
        body: Center(
          child: Column(children: [
            Text("Logged in as: " + user.email!),
            Text("Settings Page")
          ]),
        ));
  }
}

import 'package:flutter/material.dart';

class VisitorAnimalDetailPage extends StatelessWidget {
  final String id;
  const VisitorAnimalDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Animal Details"),
      ),
      body: Center(
        child: Text("Animal Details $id"),
      ),
    );
  }
}

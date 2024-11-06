import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('logo.png'),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/wiki');
              },
              child: const Text(
                'Wiki',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to ShelterPartner',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'ShelterPartner is a free and open source volunteer facing shelter management app that allows volunteers to have their own accounts and records visits. It’s highly customizable and connects directly to management software like ShelterLuv for animals and Better Impact to sync with your volunteers. If you are interested in using ShelterPartner, I would recommend waiting until January 1, 2025 to sign up. This is when version 2 will be released. Version 2 is a rework of the app built from scratch. If you have any questions, feel free to email me at jared@shelterpartner.org.',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
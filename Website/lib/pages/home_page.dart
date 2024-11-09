import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Image.asset('assets/logo.png'),
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                launchUrl(Uri(
                  scheme: 'https',
                  host: 'wiki.shelterpartner.org',
                ));
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
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to ShelterPartner',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'ShelterPartner is a free and open source volunteer facing shelter management app that allows volunteers to have their own accounts and records visits. It’s highly customizable and connects directly to management software like ShelterLuv for animals and Better Impact to sync with your volunteers. If you are interested in using ShelterPartner, I would recommend waiting until January 1, 2025 to sign up. This is when version 2 will be released. Version 2 is a rework of the app built from scratch. If you have any questions, feel free to email me at jared@shelterpartner.org.',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 36),
              Text(
                'Create Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'As I transition to Version 2, I have disabled the ability to create an account. If you would like to create an account, Version 2 will be released on January 1, 2025. If you have any questions, feel free to email me at jared@shelterpartner.org',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 36),
              Text(
                'Version 2',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'More details on version 2 and a demo experience will be available soon.',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

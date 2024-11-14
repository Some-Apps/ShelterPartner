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
                'ShelterPartner is a free and open source volunteer facing shelter management app that allows volunteers to have their own accounts and records visits. It’s highly customizable and connects directly to your ShelterLuv or ShelterManager account. It can also connect to Better Impact to sync your volunteers.',
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
                'Version 2 is a complete rewrite of the app. It will be available on all platforms including web, iOS, Android, Windows, and Mac and will be released on January 1, 2025. A demo version of the app will be available on December 1, 2024. This will allow you to test the full functionality of the new version while helping me refine it and work out any bugs before the full release. If you have any questions, feel free to email me at jared@shelterpartner.org',
                style: TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

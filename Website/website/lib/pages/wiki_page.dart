
import 'package:flutter/material.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

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
      body: const Center(
        child: Text(
          'Welcome to the Wiki Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

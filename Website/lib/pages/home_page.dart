import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the YouTube iframe element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'youtube-video',
      (int viewId) => html.IFrameElement()
        ..width = '560'
        ..height = '315'
        ..src = 'https://www.youtube.com/embed/obv5Pvv2caw' // Replace with your video ID
        ..style.border = 'none',
    );

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
              // Beta Button
              TextButton(
                onPressed: () {
                  launchUrl(Uri(
                    scheme: 'https',
                    host: 'beta.shelterpartner.org',
                  ));
                },
                child: const Text(
                  'Beta',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              // Download Button with Dialog Tooltip
              TextButton(
                onPressed: () {
                    showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Download Information'),
                      content: Text(
                      'Coming January 1, 2025\n\n'
                      'Platforms:\n'
                      '- Windows\n'
                      '- Mac\n'
                      '- iOS\n'
                      '- Android\n'
                      '- Web',
                      style: TextStyle(fontSize: 16),
                      ),
                      actions: [
                      // TextButton(
                      //   onPressed: () => Navigator.of(context).pop(),
                      //   child: const Text('OK'),
                      // ),
                      ],
                    ),
                    );
                },
                child: const Text(
                  'Download',
                  style: TextStyle(color: Colors.black),
                ),
              ),
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
              TextButton(
                onPressed: () {
                  launchUrl(Uri(
                    scheme: 'https',
                    host: 'github.com',
                    path: '/ShelterPartner/ShelterPartner',
                  ));
                },
                child: const Text(
                  'GitHub',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: SponsorButton(),
              ), // Use the custom SponsorButton here
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: const Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome to Shelter Partner',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Shelter Partner is a free and open source volunteer facing shelter management app that allows volunteers to have their own accounts and records visits. It’s highly customizable and connects directly to your ShelterLuv or ShelterManager account. It can also connect to Better Impact to sync your volunteers.',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 36),
                    // Text(
                    //   'Create Account',
                    //   style:
                    //       TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    // ),
                    // SizedBox(height: 16),
                    // Text(
                    //   'As I transition to Version 2, I have disabled the ability to create an account. If you would like to create an account, Version 2 will be released on January 1, 2025. If you have any questions, feel free to email me at jared@shelterpartner.org',
                    //   style: TextStyle(fontSize: 15),
                    // ),
                    // SizedBox(height: 36),
                    Text(
                      'Version 2 Demo',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Version 2 is a complete rewrite of the app. It will be available on all platforms including web, iOS, Android, Windows, and Mac and will be released on January 1, 2025. You can watch the demo below and try it out by clicking the "Beta" button above.',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 36),
                    // Embedded YouTube Video
                    SizedBox(
                      width: 560,
                      height: 315,
                      child: HtmlElementView(viewType: 'youtube-video'),
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

class SponsorButton extends StatelessWidget {
  const SponsorButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the iframe element
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => html.IFrameElement()
        ..src = 'https://github.com/sponsors/ShelterPartner/button'
        ..style.border = '0'
        ..style.borderRadius = '6px'
        ..width = '114'
        ..height = '32',
    );

    return const SizedBox(
      width: 114,
      height: 32,
      child: HtmlElementView(
        viewType: 'iframeElement',
      ),
    );
  }
}

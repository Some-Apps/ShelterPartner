import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
// Add these two imports for social icons:
import 'package:flutter/widgets.dart';

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
        ..src =
            'https://www.youtube.com/embed/phDOgusydnk' // Replace with your video ID
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
              // TextButton(
              //   onPressed: () {
              //     launchUrl(Uri(
              //       scheme: 'https',
              //       host: 'beta.shelterpartner.org',
              //     ));
              //   },
              //   child: const Text(
              //     'Beta',
              //     style: TextStyle(color: Colors.black),
              //   ),
              // ),
              // Download Button with Dialog Tooltip
              // TextButton(
              //   onPressed: () {
              //     showDialog(
              //       context: context,
              //       builder: (context) => const AlertDialog(
              //         title: Text('Download Information'),
              //         content: Text(
              //           'Coming January 1, 2025\n\n'
              //           'Platforms:\n'
              //           '- Windows\n'
              //           '- Mac\n'
              //           '- iOS\n'
              //           '- Android\n'
              //           '- Web',
              //           style: TextStyle(fontSize: 16),
              //         ),
              //         actions: [
              //           // TextButton(
              //           //   onPressed: () => Navigator.of(context).pop(),
              //           //   child: const Text('OK'),
              //           // ),
              //         ],
              //       ),
              //     );
              //   },
              //   child: const Text(
              //     'Download',
              //     style: TextStyle(color: Colors.black),
              //   ),
              // ),
              TextButton(
                onPressed: () {
                  launchUrl(Uri(
                    scheme: 'https',
                    host: 'app.shelterpartner.org',
                  ));
                },
                child: const Text(
                  'App',
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
              IconButton(
                icon: Icon(Icons.facebook, color: Colors.black),
                onPressed: () {
                  launchUrl(Uri.parse('https://www.facebook.com/ShelterPartner'));
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.black),
                onPressed: () {
                  launchUrl(Uri.parse('https://www.instagram.com/shelterpartner'));
                },
              ),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      MaterialBanner(
                        content: const Text(
                          "There will be an open Zoom meeting on June 6 at 6pm MST for any interested shelters. We'll go over our roadmap and get feedback from shelters.",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        contentTextStyle: const TextStyle(color: Colors.white),
                        actions: const [],
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: const [
                              Text(
                                'Welcome',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Shelter Partner is a free and open source web and mobile app that directly connects to ShelterLuv or ASM to help your volunteers and staff better prioritize the animals in your care. Watch the video below to learn more. You can access the web version by clicking the "App" button above.',
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Version 2 Tutorial',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              const SizedBox(
                                width: 560,
                                height: 315,
                                child: HtmlElementView(viewType: 'youtube-video'),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  launchUrl(Uri(
                                    scheme: 'https',
                                    host: 'www.youtube.com',
                                    path: '/watch',
                                    queryParameters: {'v': 'phDOgusydnk'},
                                  ));
                                },
                                child: const Text('Watch Full Screen on YouTube'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // const SizedBox(height: 36),
                      // const SponsorsWidget(),
                      const SizedBox(height: 36),
                      // Footer with Privacy Policy
                      // TextButton(
                      //   onPressed: () async {
                      //     const pdfUrl =
                      //         'assets/privacy_policy.pdf'; // For local assets
                      //     final pdfUri = Uri.parse(pdfUrl);

                      //     // If hosted online, use an HTTP/HTTPS link:
                      //     // final pdfUri = Uri.parse('https://example.com/privacy_policy.pdf');

                      //     if (await canLaunchUrl(pdfUri)) {
                      //       await launchUrl(pdfUri);
                      //     } else {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         const SnackBar(
                      //             content:
                      //                 Text('Unable to open Privacy Policy PDF')),
                      //       );
                      //     }
                      //   },
                      //   child: const Text(
                      //     'Privacy Policy',
                      //     style: TextStyle(color: Colors.blue),
                      //   ),
                      // ),
                    ],
                  ),
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
        ..src = 'https://github.com/sponsors/Shelter-Partner/button'
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

class SponsorsWidget extends StatelessWidget {
  const SponsorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for demonstration purposes

    final sponsors = List.generate(
      100,
      (index) => {
        'name': 'Sponsor ${index + 1}',
        'amount': (index + 1) * 5,
        'photoUrl': 'assets/logo.png',
      },
    );

    final lessThan25 =
        sponsors.where((s) => (s['amount'] as int) < 25).toList();
    final between25And100 = sponsors
        .where((s) => (s['amount'] as int) >= 25 && (s['amount'] as int) < 100)
        .toList();
    final between100And250 = sponsors
        .where((s) => (s['amount'] as int) >= 100 && (s['amount'] as int) < 250)
        .toList();
    final above250 =
        sponsors.where((s) => (s['amount'] as int) >= 250).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (above250.isNotEmpty) ...[
          const Text('Gold Sponsors'),
          Column(
            children: above250
                .map((s) => Card(
                      child: ListTile(
                        leading: Image.asset(
                          s['photoUrl'] as String? ?? 'assets/logo.png',
                          width: 100,
                          height: 100,
                        ),
                        title: Text(
                          s['name']! as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (between100And250.isNotEmpty) ...[
          const Text('Silver Sponsors'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: between100And250
                .map((s) => Column(
                      children: [
                        Image.asset(
                          s['photoUrl'] as String? ?? 'assets/logo.png',
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s['name']! as String,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (between25And100.isNotEmpty) ...[
          const Text('Bronze Sponsors'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: between25And100
                .map((s) => Column(
                      children: [
                        Image.asset(
                          s['photoUrl'] as String? ?? 'assets/logo.png',
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 4),
                        Text(s['name']! as String),
                      ],
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (lessThan25.isNotEmpty) ...[
          const Text('Supporters'),
          Wrap(
            children: lessThan25
                .map((s) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(s['name']! as String),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
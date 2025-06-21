// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  launchUrl(
                    Uri(scheme: 'https', host: 'app.shelterpartner.org'),
                  );
                },
                child: const Text('App', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () {
                  launchUrl(
                    Uri(scheme: 'https', host: 'wiki.shelterpartner.org'),
                  );
                },
                child: const Text(
                  'Wiki',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () {
                  launchUrl(
                    Uri(
                      scheme: 'https',
                      host: 'github.com',
                      path: '/ShelterPartner/ShelterPartner',
                    ),
                  );
                },
                child: const Text(
                  'GitHub',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://github.com/sponsors/Shelter-Partner'),
                  );
                },
                child: const Text(
                  'Sponsor',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.facebook,
                  color: Colors.black,
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://www.facebook.com/people/Shelter-Partner/61565670425368/',
                    ),
                  );
                },
              ),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.instagram,
                  color: Colors.black,
                ),
                onPressed: () {
                  launchUrl(
                    Uri.parse('https://www.instagram.com/shelterpartner'),
                  );
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "There will be an open Zoom meeting today, June 6 at 6pm MST for any interested shelters. We'll go over our roadmap and get feedback from shelters. Here is a link to the meeting. All are welcome!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          launchUrl(
                            Uri.parse('https://us05web.zoom.us/j/83987575528'),
                          );
                        },
                        child: const Text(
                          'https://us05web.zoom.us/j/83987575528',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          Text(
                            'Welcome',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Shelter Partner is a free and open source web and mobile app that directly connects to ShelterLuv to help your volunteers and staff better prioritize the animals in your care. Watch the video below to learn more. You can access the web version by clicking the "App" button above.',
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          const Text(
                            'Version 2 Tutorial',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              launchUrl(
                                Uri(
                                  scheme: 'https',
                                  host: 'www.youtube.com',
                                  path: '/watch',
                                  queryParameters: {'v': 'phDOgusydnk'},
                                ),
                              );
                            },
                            child: const Text(
                              'Watch Version 2 Tutorial on YouTube',
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          // const SizedBox(height: 16),
                          // ElevatedButton(
                          //   onPressed: () {
                          //     launchUrl(
                          //       Uri(
                          //         scheme: 'https',
                          //         host: 'www.youtube.com',
                          //         path: '/watch',
                          //         queryParameters: {'v': 'phDOgusydnk'},
                          //       ),
                          //     );
                          //   },
                          //   child: const Text('Watch Full Screen on YouTube'),
                          // ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
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

    final lessThan25 = sponsors
        .where((s) => (s['amount'] as int) < 25)
        .toList();
    final between25And100 = sponsors
        .where((s) => (s['amount'] as int) >= 25 && (s['amount'] as int) < 100)
        .toList();
    final between100And250 = sponsors
        .where((s) => (s['amount'] as int) >= 100 && (s['amount'] as int) < 250)
        .toList();
    final above250 = sponsors
        .where((s) => (s['amount'] as int) >= 250)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (above250.isNotEmpty) ...[
          const Text('Gold Sponsors'),
          Column(
            children: above250
                .map(
                  (s) => Card(
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
                  ),
                )
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
                .map(
                  (s) => Column(
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
                  ),
                )
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
                .map(
                  (s) => Column(
                    children: [
                      Image.asset(
                        s['photoUrl'] as String? ?? 'assets/logo.png',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(height: 4),
                      Text(s['name']! as String),
                    ],
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (lessThan25.isNotEmpty) ...[
          const Text('Supporters'),
          Wrap(
            children: lessThan25
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(s['name']! as String),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

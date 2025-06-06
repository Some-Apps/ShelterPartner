import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' hide Navigator, Text;
import 'package:flutter/material.dart';

void _registerWikiViewFactory() {
  if (!kIsWeb) return;
  final registry = js.context['flutter']['platformViewRegistry'];
  registry.callMethod('registerViewFactory', <dynamic>[
    'iframeElement',
    js.allowInterop((int viewId) {
      final iframe = HTMLIFrameElement();
      iframe.src = 'https://pawpartner.gitbook.io/pawpartner-wiki/';
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      return iframe;
    }),
  ]);
}

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    _registerWikiViewFactory();

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
              child: const Text('Wiki', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      body: const HtmlElementView(viewType: 'iframeElement'),
    );
  }
}

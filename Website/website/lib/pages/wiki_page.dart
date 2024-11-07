import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WikiPage extends StatelessWidget {
  const WikiPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Register the IFrameElement
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'iframeElement',
      (int viewId) => html.IFrameElement()
        ..src = 'https://pawpartner.gitbook.io/pawpartner-wiki/'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );

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
      body: const HtmlElementView(viewType: 'iframeElement'),
    );
  }
}

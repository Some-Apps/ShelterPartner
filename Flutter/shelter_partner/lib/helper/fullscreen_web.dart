// fullscreen_web.dart

import 'dart:html' as html;

void enterFullScreen() {
  html.document.documentElement?.requestFullscreen();
}

void exitFullScreen() {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  }
}

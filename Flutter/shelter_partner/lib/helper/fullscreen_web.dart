// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void enterFullScreen() {
  html.document.documentElement?.requestFullscreen();
}

void exitFullScreen() {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  }
}

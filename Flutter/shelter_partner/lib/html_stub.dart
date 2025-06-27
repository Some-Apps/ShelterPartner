/// Stub implementation for dart:html for non-web platforms.
/// This file is used to avoid import errors on iOS and Android.
library;

class Window {
  Navigator get navigator => Navigator();
  Location get location => Location();
}

class Navigator {
  String get userAgent => '';
}

class Location {
  void assign(String url) {}
}

final Window window = Window();

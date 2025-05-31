import 'package:flutter/services.dart';

/// FileLoader class for abstracting file loading (for testability)
abstract class FileLoader {
  Future<String> loadString(String filename);
}

class DefaultFileLoader implements FileLoader {
  @override
  Future<String> loadString(String filename) => rootBundle.loadString(filename);
}

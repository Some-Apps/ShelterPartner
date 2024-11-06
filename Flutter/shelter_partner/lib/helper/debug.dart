import 'package:flutter/foundation.dart';

class DebugHelper {
  bool debugMode;

  DebugHelper({this.debugMode = kDebugMode});

  bool isDebugMode() => debugMode;
}

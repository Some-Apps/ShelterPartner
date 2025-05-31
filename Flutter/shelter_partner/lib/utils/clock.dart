import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => SystemClock());

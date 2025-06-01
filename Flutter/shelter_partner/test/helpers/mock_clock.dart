import 'package:shelter_partner/utils/clock.dart';

class MockClock implements Clock {
  DateTime _now;
  MockClock(this._now);
  @override
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}

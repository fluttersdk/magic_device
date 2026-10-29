import 'package:flutter_inactive_timer/flutter_inactive_timer_platform_interface.dart';

/// Milliseconds since the last keyboard or pointer input, system-wide, read
/// through the FFI clock macOS and Windows expose.
Future<int> osIdleMilliseconds() =>
    FlutterInactiveTimerPlatform.instance.getIdleDuration();

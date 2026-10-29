/// # Magic Device, device signals for Flutter
library;

// `DevicePower`'s constructor takes a battery reader returning this type, so a
// host that supplies its own reader should not need `battery_plus` as a direct
// dependency just to name it.
export 'package:battery_plus/battery_plus.dart' show BatteryState;
export 'src/power/device_power.dart';
export 'src/window/window_fullscreen.dart';

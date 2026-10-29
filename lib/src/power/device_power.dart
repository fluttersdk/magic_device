import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:magic_device/src/power/os_idle.dart';

/// The two hardware signals a background job gates on: whether the device
/// draws from the mains, and whether the viewer has been away long enough that
/// the work would not disturb them.
///
/// Nothing is collected until [start], so a process that never asks holds no
/// channel and no timer. [idle] is a cached flag that the desktop poll keeps
/// current, so a gate reads it without awaiting; [charging] asks the platform
/// once per read.
///
/// ```dart
/// final DevicePower power = DevicePower(television: () => isTelevision);
/// power.start();
///
/// if (await power.charging && power.idle) {
///   // Safe to run the heavy job.
/// }
/// ```
final class DevicePower with WidgetsBindingObserver {
  /// The shared instance; a test builds its own through the constructor.
  static final DevicePower instance = DevicePower();

  /// How long without input before the viewer counts as away.
  static const Duration idleThreshold = Duration(minutes: 2);

  /// How often the desktop poll re-reads the OS idle duration. Cheap (one FFI
  /// call), and a poll is the only shape available: neither macOS nor Windows
  /// notifies "the user came back".
  static const Duration pollInterval = Duration(seconds: 30);

  /// Every reader is injectable. [television] answers whether the device is a
  /// television, which has no battery to read; the package cannot tell, so the
  /// default is `() => false` and the host passes its own signal.
  DevicePower({
    Future<BatteryState> Function()? batteryState,
    Future<int> Function()? idleDuration,
    TargetPlatform? platform,
    bool Function()? television,
  })  : _readBatteryState = batteryState ?? _batteryStateOf,
        _readIdleDuration = idleDuration ?? osIdleMilliseconds,
        _platform = platform ?? defaultTargetPlatform,
        _isTelevision = television ?? _neverTelevision;

  /// One `Battery()` for the process: a second instance steals the first one's
  /// EventChannel subscription.
  static final Battery _battery = Battery();

  final Future<BatteryState> Function() _readBatteryState;
  final Future<int> Function() _readIdleDuration;
  final TargetPlatform _platform;
  final bool Function() _isTelevision;

  Timer? _poll;
  bool _started = false;
  bool _idle = false;

  /// Whether the device is on mains power right now.
  ///
  /// A television answers true without asking the platform: a batteryless
  /// Android TV reports `unknown`, which would gate the work off forever on a
  /// box that never runs on anything else.
  Future<bool> get charging async {
    if (_isTelevision()) return true;

    try {
      return isOnMains(await _readBatteryState());
    } on MissingPluginException {
      // A platform with no battery_plus implementation cannot answer, which is
      // not the same as being on mains; the gate stays closed.
      return false;
    }
  }

  /// Whether the viewer has been away for at least [idleThreshold].
  bool get idle => _idle;

  /// Starts collecting. Idempotent: a call while already running does nothing.
  void start() {
    if (_started) return;
    _started = true;

    // macOS and Windows expose a system-wide last-input clock; everything else
    // only knows whether the app is in front.
    if (_desktopIdle) {
      _poll = Timer.periodic(
        pollInterval,
        (Timer _) => unawaited(refreshIdle()),
      );
      unawaited(refreshIdle());
      return;
    }

    WidgetsBinding.instance.addObserver(this);
  }

  /// Stops collecting and forgets both answers, so a stopped instance claims no
  /// signal rather than a stale one.
  void stop() {
    if (!_started) return;
    _started = false;

    _poll?.cancel();
    _poll = null;

    if (!_desktopIdle) WidgetsBinding.instance.removeObserver(this);

    _idle = false;
  }

  /// Re-reads the OS idle duration now. [pollInterval] calls this on desktop;
  /// a test calls it directly to drive a faked reader without waiting.
  @visibleForTesting
  Future<void> refreshIdle() async {
    final int idleMs = await _readIdleDuration();

    if (!_started) return;

    _idle = idleMs >= idleThreshold.inMilliseconds;
  }

  /// Mobile idle is "the app is not in front": neither iOS nor Android exposes a
  /// system-wide last-input clock, so this is the whole answer there.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _idle = state != AppLifecycleState.resumed;
  }

  /// Whether [state] means the device draws from the mains.
  ///
  /// A Mac without a battery (mini, Studio, a batteryless VM) reports
  /// `connectedNotCharging`, which is exactly the on-mains answer wanted here.
  /// `unknown` is what a batteryless Android reports, so it cannot count.
  @visibleForTesting
  static bool isOnMains(BatteryState state) => switch (state) {
        BatteryState.full ||
        BatteryState.charging ||
        BatteryState.connectedNotCharging =>
          true,
        BatteryState.discharging || BatteryState.unknown => false,
      };

  bool get _desktopIdle =>
      !kIsWeb &&
      (_platform == TargetPlatform.macOS ||
          _platform == TargetPlatform.windows);

  static Future<BatteryState> _batteryStateOf() => _battery.batteryState;

  static bool _neverTelevision() => false;
}

# Magic Device

Device signals for Flutter apps.

> **Alpha**: `magic_device` is under active development. APIs may change between minor versions until `1.0.0`.

## DevicePower

Two hardware signals a background job can gate on: whether the device draws from the mains, and whether the viewer has been away long enough that the work would not disturb them.

```dart
import 'package:magic_device/magic_device.dart';

final DevicePower power = DevicePower(television: () => isTelevision);
power.start();

if (await power.charging && power.idle) {
  // Safe to run the heavy job.
}

power.stop();
```

| Signal | Meaning |
|--------|---------|
| `charging` | On mains power. `full`, `charging` and `connectedNotCharging` count; `discharging` and `unknown` do not. A platform with no battery implementation answers false. |
| `idle` | Away for at least `DevicePower.idleThreshold` (2 minutes). macOS and Windows read the system-wide last-input clock every `pollInterval` (30 seconds); every other platform reports idle whenever the app is not in front. |

Nothing is collected until `start()`, and `stop()` forgets both answers.

### Televisions

A batteryless Android TV reports `unknown`, which would read as not charging forever. Pass a `television` predicate and `charging` answers true without asking the platform. The default is `() => false`.

### Testing

Every platform read is a constructor parameter: `batteryState`, `idleDuration`, `platform` and `television`.

## Dependencies

`battery_plus` for the battery state (one `Battery()` per process, held by `DevicePower`) and `flutter_inactive_timer` for the desktop idle clock, loaded through a conditional export so `dart:ffi` never reaches the web compiler. The web has no system-wide input clock.

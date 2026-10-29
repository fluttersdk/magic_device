# Magic Device

[![pub.dev version](https://img.shields.io/pub/v/magic_device.svg)](https://pub.dev/packages/magic_device)
[![CI Status](https://img.shields.io/github/actions/workflow/status/fluttersdk/magic_device/ci.yml?branch=main&label=CI)](https://github.com/fluttersdk/magic_device/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![pub points](https://img.shields.io/pub/points/magic_device)](https://pub.dev/packages/magic_device/score)

Device signals for Flutter apps: whether the device is on mains power, whether the viewer is away, and the macOS window fullscreen state.

> **Alpha**: `magic_device` is under active development. APIs may change between minor versions until `1.0.0`.

## Install

```bash
flutter pub add magic_device
```

`DevicePower` needs no setup. `WindowFullscreen` registers its own macOS plugin, so a macOS host needs no edit to its Runner either.

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
| `idle` | Away for at least `DevicePower.idleThreshold` (2 minutes). macOS and Windows read the system-wide last-input clock every `pollInterval` (30 seconds); every other platform reports idle whenever the app is not in front, read from the current lifecycle state at `start()` and followed from there. |

Nothing is collected until `start()`, and `stop()` forgets both answers.

### Televisions

A batteryless Android TV reports `unknown`, which would read as not charging forever. Pass a `television` predicate and `charging` answers true without asking the platform. The default is `() => false`.

### Testing

Every platform read is a constructor parameter: `batteryState`, `idleDuration`, `platform` and `television`.

## WindowFullscreen

Whether the macOS window is fullscreen, and the one call that flips it. The package's macOS plugin registers the `magic_device/window` channel itself, so the host's `MainFlutterWindow.swift` stays Flutter's stock one.

```dart
import 'package:magic_device/magic_device.dart';

final WindowFullscreen fullscreen = WindowFullscreen.instance;
fullscreen.addListener(() => setState(() {}));

if (fullscreen.available) {
  await fullscreen.toggle();
}
```

| Reading | Meaning |
|---------|---------|
| `available` | True on macOS only. Everywhere else `toggle()` sends nothing, so gate the control on it. |
| `active` | Fullscreen, as the window last confirmed (AppKit's did-notification). |
| `target` | Fullscreen or on its way there: moves on the will-notification, so a layout can animate with the window. |
| `transitioning` | Between the two: the window's size changes on every frame. |

The state follows the window, not the calls: the green button, Esc and the Window menu notify listeners just as `toggle()` does, and a window that opens already fullscreen is read once on first use.

`toggle()` is ignored while a press or an animation is under way, so a double press cannot undo itself. It throws a `PlatformException` (`no_window`) when the Flutter view is not in a window, and that refusal releases the press. AppKit silently ignores the call for an app that is not frontmost; when the window posts nothing within `WindowFullscreen.pressTimeout` (1 second), the press ends and the window's state is read again.

Use the one `instance`: the channel takes one handler. A view adds and removes a listener and never disposes it. A test calls `WindowFullscreen.resetInstance()` in `tearDown`.

The `example/` app toggles the window from a button and logs each notification in order.

## Dependencies

`battery_plus` for the battery state (one `Battery()` per process, held by `DevicePower`) and `flutter_inactive_timer` for the desktop idle clock, loaded through a conditional export so `dart:ffi` never reaches the web compiler. The web has no system-wide input clock. `WindowFullscreen` uses the Flutter SDK only.

# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.0.1] - 2026-10-29

### Added
- **`DevicePower`**: whether the device is on mains power (`charging`) and whether the viewer is away (`idle`). Desktop idle polls the OS last-input clock; mobile idle follows the app lifecycle. `television` is an injectable predicate that defaults to `() => false`.
- **`WindowFullscreen`**: whether the macOS window is fullscreen (`active`), where it is going (`target`, moved by AppKit's will-notification) and whether it is animating (`transitioning`), with `toggle()` to flip it. One shared `instance`; listeners hear each change, whether it came from `toggle()`, the window's green button, Esc or the Window menu. `available` is true on macOS only. The native half is a macOS plugin (`MagicDevicePlugin`, channel `magic_device/window`) that finds the window holding the Flutter view on each call, so the host's Runner needs no edit.
- **`BatteryState` is exported from the barrel.** `DevicePower`'s `batteryState` reader returns it, so a host that supplies its own reader names the type without adding `battery_plus` as a direct dependency.

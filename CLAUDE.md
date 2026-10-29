# Magic Device Plugin

Device signals for Flutter apps and the Magic Framework. Dart only: no native plugin code of its own.

**Version:** 0.0.1 · **Dart:** >=3.6.0 · **Flutter:** >=3.27.0

## Commands

| Command | Description |
|---------|-------------|
| `flutter test --coverage` | Run all tests with coverage |
| `flutter analyze --no-fatal-infos` | Static analysis |
| `dart format .` | Format all code |
| `flutter pub publish --dry-run` | Pre-publish check |

## Architecture

```
lib/
├── magic_device.dart     # Barrel export, the only public API
└── src/
    └── power/            # DevicePower: mains power and viewer-away signals
        ├── device_power.dart
        ├── os_idle.dart          # Conditional export: web arm, or the FFI arm when dart:ffi exists
        ├── os_idle_native.dart   # flutter_inactive_timer (macOS and Windows)
        └── os_idle_web.dart      # Throws: the web has no system-wide input clock
```

## Post-Change Checklist

After ANY source code change, sync **before committing**:

1. **`CHANGELOG.md`**: Add entry under `[Unreleased]` section
2. **`README.md`**: Update if features, API, or usage changes
3. **`CLAUDE.md`**: Update the architecture tree when files move

## Development Flow (TDD)

Every feature, fix, or refactor must go through the red-green-refactor cycle:

1. **Red**: Write a failing test that describes the expected behavior
2. **Green**: Write the minimum code to make the test pass
3. **Refactor**: Clean up while keeping tests green

**Rules:**
- No production code without a failing test first
- Run `flutter test` after every change: all tests must stay green
- Run `dart analyze` after every change: zero warnings, zero errors
- Run `dart format .` before committing: zero formatting issues

## Testing

- Inject every platform read through the `DevicePower` constructor (`batteryState`, `idleDuration`, `platform`, `television`); no mocking library
- Tests mirror `lib/src/` structure in `test/`
- Import from `package:magic_device/src/...` in tests, not the barrel

## Key Gotchas

| Mistake | Fix |
|---------|-----|
| A second `Battery()` instance | `DevicePower` holds the single static one; a second instance steals the first one's EventChannel subscription |
| Importing `flutter_inactive_timer` from `device_power.dart` | Go through `os_idle.dart`, so `dart:ffi` never reaches the web compiler |
| Treating `unknown` as mains | A batteryless Android reports `unknown`; the host passes `television` to answer true on a box that never runs on a battery |
| Referencing an app type in the package | The `television` predicate is the seam; the default is `() => false` |
| Relative paths in `pubspec_overrides.yaml` | Use ABSOLUTE ones; the file is never committed |

## First publish

The first publish (0.0.1) is a manual `flutter pub publish`, since tag-triggered OIDC cannot create a package. Later tags publish through `publish.yml` once automated publishing is enabled on pub.dev.

## CI

- `ci.yml`: push/PR → `flutter pub get` → `flutter analyze --no-fatal-infos` → `dart format --set-exit-if-changed` → `flutter test --coverage` → codecov upload

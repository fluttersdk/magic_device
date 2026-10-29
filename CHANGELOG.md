# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.0.1] - 2026-10-29

### Added
- **`DevicePower`**: whether the device is on mains power (`charging`) and whether the viewer is away (`idle`). Desktop idle polls the OS last-input clock; mobile idle follows the app lifecycle. `television` is an injectable predicate that defaults to `() => false`.

/// The OS idle clock, kept behind a conditional export so `dart:ffi` never
/// reaches the web compiler.
library;

export 'os_idle_web.dart' if (dart.library.ffi) 'os_idle_native.dart';

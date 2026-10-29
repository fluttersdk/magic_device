/// The web build has no system-wide input clock. `DevicePower` never asks: its
/// desktop poll is gated on `!kIsWeb`.
Future<int> osIdleMilliseconds() =>
    throw UnsupportedError('The OS idle clock is not available on the web.');

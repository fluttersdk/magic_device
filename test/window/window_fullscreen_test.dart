import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_device/src/window/window_fullscreen.dart';

const MethodChannel _channel = MethodChannel('magic_device/window');

/// What the window answers and what it was asked, standing in for the macOS
/// plugin.
class _FakeWindow {
  bool fullScreen = false;

  /// Set to make the next `toggleFullScreen` fail the way a window the plugin
  /// cannot reach does.
  bool refuseToggle = false;

  final List<String> calls = [];

  Future<Object?> handle(MethodCall call) async {
    calls.add(call.method);

    switch (call.method) {
      case 'isFullScreen':
        return fullScreen;
      case 'toggleFullScreen':
        if (refuseToggle) {
          refuseToggle = false;
          throw PlatformException(code: 'no_window');
        }
        return null;
    }

    throw MissingPluginException(call.method);
  }
}

/// Delivers [method] as if AppKit had posted the matching notification.
Future<void> _push(String method) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    _channel.name,
    const StandardMethodCodec().encodeMethodCall(MethodCall(method)),
    (ByteData? _) {},
  );
}

/// The three readings, so one expectation pins a whole state.
(bool, bool, bool) _state(WindowFullscreen window) => (
      window.active,
      window.target,
      window.transitioning,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeWindow window;

  setUp(() {
    window = _FakeWindow();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, window.handle);
  });

  tearDown(() {
    WindowFullscreen.resetInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  group('on macOS', () {
    test('is available', () {
      expect(WindowFullscreen.instance.available, isTrue);
    });

    test('reads a window that is already fullscreen', () async {
      window.fullScreen = true;
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      int notified = 0;
      fullscreen.addListener(() => notified++);

      await pumpEventQueue();

      expect(window.calls, ['isFullScreen']);
      expect(_state(fullscreen), (true, true, false));
      expect(notified, 1);
    });

    test('a windowed start notifies nobody', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      int notified = 0;
      fullscreen.addListener(() => notified++);

      await pumpEventQueue();

      expect(_state(fullscreen), (false, false, false));
      expect(notified, 0);
    });

    test('the will-notification moves target before did confirms it', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();
      final List<(bool, bool, bool)> heard = [];
      fullscreen.addListener(() => heard.add(_state(fullscreen)));

      await _push('willEnterFullScreen');
      await _push('didEnterFullScreen');
      await _push('willExitFullScreen');
      await _push('didExitFullScreen');

      expect(heard, [
        (false, true, true),
        (true, true, false),
        (true, false, true),
        (false, false, false),
      ]);
    });

    test('follows a change the window made on its own', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();

      await _push('didEnterFullScreen');

      expect(window.calls, ['isFullScreen']);
      expect(_state(fullscreen), (true, true, false));
    });

    test('toggle asks the window', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();

      await fullscreen.toggle();

      expect(window.calls, ['isFullScreen', 'toggleFullScreen']);
      expect(_state(fullscreen), (false, false, false));
    });

    test('a second press before the window starts is ignored', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();

      await fullscreen.toggle();
      await fullscreen.toggle();

      expect(window.calls.where((String c) => c == 'toggleFullScreen'),
          hasLength(1));
    });

    test('a press during the animation is ignored, and allowed once it lands',
        () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();

      await _push('willEnterFullScreen');
      await fullscreen.toggle();
      expect(window.calls, ['isFullScreen']);

      await _push('didEnterFullScreen');
      await fullscreen.toggle();
      expect(window.calls, ['isFullScreen', 'toggleFullScreen']);
    });

    test('a refused toggle rethrows and releases the press', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();
      window.refuseToggle = true;

      await expectLater(fullscreen.toggle(), throwsA(isA<PlatformException>()));
      await fullscreen.toggle();

      expect(window.calls.where((String c) => c == 'toggleFullScreen'),
          hasLength(2));
    });

    test('one shared reader', () {
      expect(identical(WindowFullscreen.instance, WindowFullscreen.instance),
          isTrue);
    });

    test('a reset reader reads the window afresh', () async {
      WindowFullscreen.instance;
      await pumpEventQueue();
      WindowFullscreen.resetInstance();
      window.fullScreen = true;

      final WindowFullscreen fresh = WindowFullscreen.instance;
      await pumpEventQueue();

      expect(window.calls, ['isFullScreen', 'isFullScreen']);
      expect(fresh.active, isTrue);
    });

    test('a disposed reader ignores the window', () async {
      final WindowFullscreen fullscreen = WindowFullscreen.instance;
      await pumpEventQueue();
      WindowFullscreen.resetInstance();

      await _push('didEnterFullScreen');

      expect(fullscreen.active, isFalse);
    });
  });

  group('anywhere else', () {
    for (final TargetPlatform platform in const [
      TargetPlatform.iOS,
      TargetPlatform.android,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      test('${platform.name} has no window to drive', () async {
        debugDefaultTargetPlatformOverride = platform;
        final WindowFullscreen fullscreen = WindowFullscreen.instance;

        await fullscreen.toggle();
        await pumpEventQueue();

        expect(fullscreen.available, isFalse);
        expect(window.calls, isEmpty);
      });
    }
  });
}

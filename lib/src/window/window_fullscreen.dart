import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the macOS window is fullscreen, and the one call that flips it.
///
/// Drives `magic_device/window`, which the package's macOS plugin registers on
/// its own: the host's Runner needs no edit. The plugin pushes
/// `willEnterFullScreen` and `willExitFullScreen` as AppKit starts animating
/// the window, and `didEnterFullScreen` and `didExitFullScreen` once it lands,
/// for every change, the window's own green button, Esc and the Window menu
/// included, so the state follows the window rather than the calls made here.
/// Listeners hear each change.
///
/// Two readings of one state: [target] is where the window is going, and what
/// a layout should move to as the animation starts, so the page and the window
/// animate together; [active] is what the window confirmed. [transitioning]
/// covers the gap between them.
///
/// Anywhere but macOS there is no window this package can drive: [available]
/// is false and [toggle] sends nothing, so a control gated on [available]
/// never promises a state that cannot be produced.
///
/// One per app, through [instance], because the channel takes one handler: a
/// second object would install its own over the first, and whichever was
/// disposed last would set it to null, leaving every other reader windowed
/// inside a fullscreen window. A view adds and removes a listener and never
/// disposes it.
///
/// ```dart
/// final WindowFullscreen fullscreen = WindowFullscreen.instance;
///
/// if (fullscreen.available) {
///   await fullscreen.toggle();
/// }
/// ```
class WindowFullscreen extends ChangeNotifier {
  /// Reads the window's state once: a window already fullscreen pushes nothing
  /// until it changes.
  WindowFullscreen._() {
    if (!available) return;

    _channel.setMethodCallHandler(_onNative);
    unawaited(
      _channel
          .invokeMethod<bool>('isFullScreen')
          .then((bool? value) => _settle(value ?? false)),
    );
  }

  static const MethodChannel _channel = MethodChannel('magic_device/window');

  static WindowFullscreen? _instance;

  /// The app's one reader of the window, made on first use.
  static WindowFullscreen get instance => _instance ??= WindowFullscreen._();

  /// Drops the shared reader, so the next [instance] reads the window afresh.
  @visibleForTesting
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  bool _active = false;

  bool _target = false;

  /// Set from a will-notification until the window confirms the change.
  bool _transitioning = false;

  /// Set from a [toggle] until the window starts animating or confirms. The
  /// window animates for a while after the call returns and [active] reads the
  /// old state throughout, so a second press inside that span would undo the
  /// first.
  ///
  /// Kept apart from [transitioning] because AppKit ignores the call for an app
  /// that is not frontmost and says nothing: a press must not move the layout
  /// on a change that may never start.
  bool _pressed = false;

  bool _disposed = false;

  /// Whether there is a window to make fullscreen: macOS only.
  bool get available =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Whether the window is fullscreen, as it last confirmed.
  bool get active => _active;

  /// Whether the window is fullscreen or on its way there: moves on AppKit's
  /// will-notification, ahead of [active].
  bool get target => _target;

  /// Whether the window is animating between the two states, during which its
  /// size changes on every frame.
  bool get transitioning => _transitioning;

  /// Asks the window to enter fullscreen, or leave it; ignored while a press or
  /// a change is under way. [target] moves when the window starts.
  ///
  /// Throws the [PlatformException] the plugin answers with when it cannot
  /// reach a window. A refused call sends no notification, so the press ends
  /// here: on the one shared reader it would otherwise hold every later toggle
  /// in the app.
  Future<void> toggle() async {
    if (!available || _pressed || _transitioning) return;

    _pressed = true;

    try {
      await _channel.invokeMethod<void>('toggleFullScreen');
    } on PlatformException {
      _pressed = false;
      rethrow;
    }
  }

  Future<void> _onNative(MethodCall call) async {
    switch (call.method) {
      case 'willEnterFullScreen':
        _begin(true);
      case 'willExitFullScreen':
        _begin(false);
      case 'didEnterFullScreen':
        _settle(true);
      case 'didExitFullScreen':
        _settle(false);
    }
  }

  /// The window started animating toward [target], from a press here or its
  /// own controls.
  void _begin(bool target) =>
      _apply(active: _active, target: target, transitioning: true);

  /// Any confirmed state ends the transition, whether or not it changed.
  void _settle(bool active) =>
      _apply(active: active, target: active, transitioning: false);

  void _apply({
    required bool active,
    required bool target,
    required bool transitioning,
  }) {
    if (_disposed) return;

    _pressed = false;

    if (active == _active &&
        target == _target &&
        transitioning == _transitioning) {
      return;
    }

    _active = active;
    _target = target;
    _transitioning = transitioning;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;

    if (available) _channel.setMethodCallHandler(null);

    super.dispose();
  }
}

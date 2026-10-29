import Cocoa
import FlutterMacOS

/// Answers `magic_device/window`, the channel `WindowFullscreen` drives, for the
/// window that holds the Flutter view.
///
/// The window is looked up on every call and every notification rather than
/// captured at registration: `register(with:)` runs inside the host's
/// `awakeFromNib`, before the view is guaranteed to sit in a window, and a host
/// may move the view to another window later. So the four fullscreen
/// notifications are observed for every window and forwarded only when they
/// come from the one holding the view.
///
/// All four fire on Esc, the window's own green button and the Window menu, not
/// only on a call this channel made, which keeps the Dart side correct either
/// way. The will-pair lets a layout move with the animation rather than jump
/// once it ends.
public final class MagicDevicePlugin: NSObject, FlutterPlugin {
  /// Weak because the engine owns the registrar, and the registrar's channel
  /// owns this plugin.
  private weak var registrar: FlutterPluginRegistrar?

  private let channel: FlutterMethodChannel

  /// The NotificationCenter tokens, removed when the plugin goes.
  private var observers: [NSObjectProtocol] = []

  private init(registrar: FlutterPluginRegistrar, channel: FlutterMethodChannel) {
    self.registrar = registrar
    self.channel = channel
    super.init()
  }

  deinit {
    observers.forEach { NotificationCenter.default.removeObserver($0) }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "magic_device/window",
      binaryMessenger: registrar.messenger
    )
    let instance = MagicDevicePlugin(registrar: registrar, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.observeFullScreen()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "toggleFullScreen":
      guard let window = window else {
        result(
          FlutterError(
            code: "no_window",
            message: "The Flutter view is not in a window.",
            details: nil
          )
        )
        return
      }
      window.toggleFullScreen(nil)
      result(nil)

    case "isFullScreen":
      result(window?.styleMask.contains(.fullScreen) ?? false)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The window holding the Flutter view right now, if any.
  private var window: NSWindow? {
    registrar?.view?.window
  }

  private func observeFullScreen() {
    let forwarded: [(NSNotification.Name, String)] = [
      (NSWindow.willEnterFullScreenNotification, "willEnterFullScreen"),
      (NSWindow.didEnterFullScreenNotification, "didEnterFullScreen"),
      (NSWindow.willExitFullScreenNotification, "willExitFullScreen"),
      (NSWindow.didExitFullScreenNotification, "didExitFullScreen"),
    ]

    observers = forwarded.map { name, method in
      NotificationCenter.default.addObserver(
        forName: name,
        object: nil,
        queue: .main
      ) { [weak self] notification in
        self?.forward(notification, as: method)
      }
    }
  }

  private func forward(_ notification: Notification, as method: String) {
    guard let window = window, notification.object as? NSWindow === window else {
      return
    }

    channel.invokeMethod(method, arguments: nil)
  }
}

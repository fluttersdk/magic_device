# magic_device example

A macOS app with one button that toggles the window's fullscreen through `WindowFullscreen`, and a numbered log of every change the window reports. The Runner is Flutter's stock one: the package's plugin registers the window channel on its own.

```bash
flutter run -d macos
```

Press the button, then the window's green button: each change logs its will-notification before its did-notification.

import 'package:flutter/material.dart';
import 'package:magic_device/magic_device.dart';

void main() => runApp(const ExampleApp());

/// One button that toggles the window's fullscreen, and a log of every change
/// the window reports, so the will-notification can be seen landing before the
/// did-notification whether the change came from the button or from the
/// window's own green button.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final WindowFullscreen _fullscreen = WindowFullscreen.instance;

  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _fullscreen.addListener(_record);
  }

  @override
  void dispose() {
    _fullscreen.removeListener(_record);
    super.dispose();
  }

  /// Logs on screen and to the console, so a run from a terminal shows the
  /// same order.
  void _record() {
    final String entry = _describe();
    debugPrint('magic_device_example: $entry');
    setState(() => _log.add(entry));
  }

  /// Names the notification a change came from: a transitioning state is a
  /// will-notification toward [WindowFullscreen.target], a settled one a
  /// did-notification at [WindowFullscreen.active].
  String _describe() {
    if (_fullscreen.transitioning) {
      return _fullscreen.target ? 'willEnterFullScreen' : 'willExitFullScreen';
    }

    return _fullscreen.active ? 'didEnterFullScreen' : 'didExitFullScreen';
  }

  Future<void> _toggle() async {
    try {
      await _fullscreen.toggle();
    } on Exception catch (error) {
      setState(() => _log.add('toggle refused: $error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('magic_device: WindowFullscreen')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'available ${_fullscreen.available}, '
                'active ${_fullscreen.active}, '
                'target ${_fullscreen.target}, '
                'transitioning ${_fullscreen.transitioning}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _fullscreen.available ? _toggle : null,
                child: const Text('Toggle fullscreen'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    for (final (int index, String entry) in _log.indexed)
                      Text('${index + 1}. $entry'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

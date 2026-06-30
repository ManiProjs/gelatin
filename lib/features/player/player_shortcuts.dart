import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerShortcuts extends StatelessWidget {
  const PlayerShortcuts({
    super.key,
    required this.child,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onFullscreen,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onMute,
    required this.onEscape,
  });

  final Widget child;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onFullscreen;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onMute;
  final VoidCallback onEscape;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;

        if (key == LogicalKeyboardKey.space) {
          onPlayPause();
        } else if (key == LogicalKeyboardKey.arrowRight) {
          onSeekForward();
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          onSeekBackward();
        } else if (key == LogicalKeyboardKey.keyF) {
          onFullscreen();
        } else if (key == LogicalKeyboardKey.escape) {
          onEscape();
        } else if (key == LogicalKeyboardKey.arrowUp) {
          onVolumeUp();
        } else if (key == LogicalKeyboardKey.arrowDown) {
          onVolumeDown();
        } else if (key == LogicalKeyboardKey.keyM) {
          onMute();
        } else {
          return KeyEventResult.ignored;
        }

        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}

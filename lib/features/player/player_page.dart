import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import 'player_shortcuts.dart';

class PlayerPage extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, String>? headers;

  const PlayerPage({
    super.key,
    required this.url,
    required this.title,
    this.headers,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage>
    with SingleTickerProviderStateMixin {
  late final Player player;
  late final VideoController videoController;
  late final AnimationController playPauseAnim;
  late final Animation<double> scaleAnim;

  bool showControls = true;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isPlaying = false;

  Timer? _controlsTimer;

  bool _isFullscreen = false;

  Future<void> _toggleFullscreen() async {
    final fullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!fullscreen);

    if (!mounted) return;
    setState(() {
      _isFullscreen = !fullscreen;
    });
  }

  void _togglePlayPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
    playPauseAnim.forward(from: 0);
  }

  void _seekRelative(int seconds) {
    final target = position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    player.seek(clamped);
  }

  @override
  void initState() {
    super.initState();

    windowManager.isFullScreen().then((fullscreen) {
      if (!mounted) return;
      setState(() {
        _isFullscreen = fullscreen;
      });
    });

    // 1. Create player
    player = Player();

    // 2. Video controller (binds player to UI)
    videoController = VideoController(player);
    // 3. Open media (NO AVPlayer, NO range issues)
    player.open(Media(widget.url, httpHeaders: widget.headers ?? {}));
    // player.open(Media('https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'));

    player.stream.position.listen((p) {
      setState(() => position = p);
    });

    player.stream.duration.listen((d) {
      setState(() => duration = d);
    });

    player.stream.playing.listen((p) {
      setState(() {
        isPlaying = p;
        if (p) {
          _scheduleControlsHide();
        } else {
          _controlsTimer?.cancel();
          showControls = true;
        }
      });
    });

    playPauseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    scaleAnim = CurvedAnimation(
      parent: playPauseAnim,
      curve: Curves.easeOutBack,
    );
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    if (!isPlaying) return;
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => showControls = false);
      }
    });
  }

  void toggleControls() {
    setState(() {
      showControls = !showControls;
      if (showControls) {
        _scheduleControlsHide();
      } else {
        _controlsTimer?.cancel();
      }
    });
  }

  String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    player.dispose();
    playPauseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PlayerShortcuts(
        onPlayPause: _togglePlayPause,
        onSeekForward: () => _seekRelative(10),
        onSeekBackward: () => _seekRelative(-10),
        onFullscreen: _toggleFullscreen,
        onVolumeUp: () {},
        onVolumeDown: () {},
        onMute: () {},
        onEscape: () async {
          if (_isFullscreen) {
            await _toggleFullscreen();
          }
        },
        child: GestureDetector(
          onTap: toggleControls,
          child: Stack(
            children: [
              // 🎬 VIDEO
              Center(
                child: Video(
                  controller: videoController,
                  fit: BoxFit.contain,
                  controls: null,
                ),
              ),

              // 🎬 ANIMATED OVERLAY (controls)
              AnimatedOpacity(
                opacity: showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !showControls,
                  child: Stack(
                    children: [
                      // 🌫 BACKDROP
                      Container(color: Colors.black45),

                      // 🔝 TOP BAR
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ▶ CENTER PLAY BUTTON (ANIMATED)
                      Center(
                        child: ScaleTransition(
                          scale: scaleAnim,
                          child: GestureDetector(
                            onTap: _togglePlayPause,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                key: ValueKey(isPlaying),
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 📊 BOTTOM CONTROLS
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: SafeArea(
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                color: Colors.black.withOpacity(0.35),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // SEEK BAR
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 14,
                                            ),
                                      ),
                                      child: Slider(
                                        value: position.inSeconds
                                            .toDouble()
                                            .clamp(
                                              0,
                                              duration.inSeconds
                                                  .toDouble()
                                                  .clamp(1, double.infinity),
                                            ),
                                        max: duration.inSeconds
                                            .toDouble()
                                            .clamp(1, double.infinity),
                                        onChanged: (v) {
                                          player.seek(
                                            Duration(seconds: v.toInt()),
                                          );
                                        },
                                      ),
                                    ),

                                    // TIME + SKIP
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "${format(position)} / ${format(duration)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isPlaying
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                              ),
                                              onPressed: _togglePlayPause,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.replay_10,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                player.seek(
                                                  position -
                                                      const Duration(
                                                        seconds: 10,
                                                      ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.forward_10,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                player.seek(
                                                  position +
                                                      const Duration(
                                                        seconds: 10,
                                                      ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                _isFullscreen
                                                    ? Icons
                                                          .fullscreen_exit_rounded
                                                    : Icons.fullscreen_rounded,
                                                color: Colors.white,
                                              ),
                                              tooltip: _isFullscreen
                                                  ? 'Exit Full Screen'
                                                  : 'Full Screen',
                                              onPressed: _toggleFullscreen,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

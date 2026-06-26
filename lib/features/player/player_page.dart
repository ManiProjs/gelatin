import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  @override
  void initState() {
    super.initState();

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
      setState(() => isPlaying = p);
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

  void toggleControls() {
    setState(() => showControls = !showControls);
  }

  String format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() {
    player.dispose();
    playPauseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
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
                              style: const TextStyle(color: Colors.white),
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
                          onTap: () {
                            if (isPlaying) {
                              player.pause();
                            } else {
                              player.play();
                            }
                            playPauseAnim.forward(from: 0);
                          },
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
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.black54,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // SEEK BAR
                              Slider(
                                value: position.inSeconds.toDouble().clamp(
                                  0,
                                  duration.inSeconds.toDouble().clamp(
                                    1,
                                    double.infinity,
                                  ),
                                ),
                                max: duration.inSeconds.toDouble().clamp(
                                  1,
                                  double.infinity,
                                ),
                                onChanged: (v) {
                                  player.seek(Duration(seconds: v.toInt()));
                                },
                              ),

                              // TIME + SKIP
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${format(position)} / ${format(duration)}",
                                    style: const TextStyle(color: Colors.white),
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
                                        onPressed: () {
                                          if (isPlaying) {
                                            player.pause();
                                          } else {
                                            player.play();
                                          }
                                          playPauseAnim.forward(from: 0);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          player.seek(
                                            position -
                                                const Duration(seconds: 10),
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
                                                const Duration(seconds: 10),
                                          );
                                        },
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

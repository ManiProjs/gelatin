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

class _PlayerPageState extends State<PlayerPage> {
  late final Player player;
  late final VideoController videoController;

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
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🎬 VIDEO
          Center(
            child: Video(controller: videoController, fit: BoxFit.contain),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

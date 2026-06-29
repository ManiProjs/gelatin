import 'package:flutter/material.dart';
import 'package:gelatin/core/playback/playback_controller.dart';
import 'package:gelatin/core/playback/playback_service.dart';
import 'package:gelatin/features/player/player_page.dart';

class ItemDetailPage extends StatelessWidget {
  final String server;
  final String token;
  final Map<String, dynamic> item;
  final PlaybackService playback;

  const ItemDetailPage({
    super.key,
    required this.server,
    required this.token,
    required this.item,
    required this.playback,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['Id'];

    final backdropUrl = '$server/Items/$id/Images/Backdrop';

    final posterUrl = '$server/Items/$id/Images/Primary';

    final logoUrl = '$server/Items/$id/Images/Logo';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop image
                  Image.network(
                    backdropUrl,
                    headers: {'X-Emby-Token': token},
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: Colors.black),
                  ),
                  // Bottom gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.55, 1.0],
                      ),
                    ),
                  ),
                  // Positioned content overlaid on backdrop
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Poster image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            posterUrl,
                            headers: {'X-Emby-Token': token},
                            width: 160,
                            height: 240,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.movie, size: 80),
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right column
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo or title
                              Image.network(
                                logoUrl,
                                headers: {'X-Emby-Token': token},
                                height: 72,
                                errorBuilder: (_, _, _) => Text(
                                  item['Name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Chips for year and runtime
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item['ProductionYear'] != null)
                                    Chip(
                                      label: Text(
                                        '${item['ProductionYear']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: Colors.grey[800],
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (item['RunTimeTicks'] != null)
                                    Chip(
                                      label: Text(
                                        '${((item['RunTimeTicks'] as int) ~/ 600000000)} min',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: Colors.grey[800],
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 220,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final id = item['Id'].toString();
                                      final type = item['Type'];

                                      String streamUrl;

                                      if (type == 'Audio') {
                                        // direct music stream (no PlaybackInfo)
                                        streamUrl = '$server/Audio/$id/stream';
                                      } else {
                                        try {
                                          final controller = PlaybackController(
                                            playback,
                                          );
                                          streamUrl = await controller.resolve(
                                            id,
                                          );
                                        } catch (_) {
                                          // fallback if PlaybackInfo fails
                                          streamUrl =
                                              '$server/Items/$id/Download';
                                        }
                                      }

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlayerPage(
                                            url: streamUrl,
                                            title: item['Name'] ?? '',
                                            headers: {'X-Emby-Token': token},
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Playback unavailable for this item',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text("Play"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    "Overview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['Overview'] ?? 'No description available.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

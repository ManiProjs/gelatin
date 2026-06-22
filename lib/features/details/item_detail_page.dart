import 'package:flutter/material.dart';

class ItemDetailPage extends StatelessWidget {
  final String server;
  final String token;
  final Map<String, dynamic> item;

  const ItemDetailPage({
    super.key,
    required this.server,
    required this.token,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final id = item['Id'];

    final backdropUrl = '$server/Items/$id/Images/Backdrop';

    final posterUrl = '$server/Items/$id/Images/Primary';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                backdropUrl,
                headers: {'X-Emby-Token': token},
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          posterUrl,
                          headers: {'X-Emby-Token': token},
                          width: 120,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.movie, size: 80),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['Name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              item['ProductionYear']?.toString() ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 16),

                            ElevatedButton.icon(
                              onPressed: () {
                                // later: playback
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Play"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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

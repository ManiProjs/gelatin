import 'package:flutter/material.dart';

class PosterCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Map<String, String> headers;

  const PosterCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            headers: headers,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.movie, size: 40),
          ),

          // optional gradient overlay for “Netflix feel”
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

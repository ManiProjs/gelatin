import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gelatin/features/details/item_detail_page.dart';

class JellyfinSearchDelegate extends SearchDelegate<dynamic> {
  JellyfinSearchDelegate({
    required this.api,
    required this.server,
    required this.token,
    required this.playback,
  });

  final dynamic api;
  final String server;
  final String token;
  final dynamic playback;

  String backdropUrl(String id) => '$server/Items/$id/Images/Backdrop';
  String posterUrl(String id) => '$server/Items/$id/Images/Primary';
  String logoUrl(String id) => '$server/Items/$id/Images/Logo';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Start typing to search'));
    }
    return FutureBuilder(
      future: api != null ? Future.microtask(() => api.search(query)) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (kDebugMode) {
            print(snapshot.error);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = (snapshot.data as Iterable?)?.toList() ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No results'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item['Name'] ?? item.name ?? 'Unknown';
            final subtitle = item['Type'] ?? item.type;
            return ListTile(
              leading: Builder(
                builder: (_) {
                  final isPoster =
                      item['Type'] == 'Movie' || item['Type'] == 'Series';
                  final width = isPoster ? 48.0 : 48.0;
                  final height = isPoster ? 72.0 : 48.0;

                  if (item['PrimaryImageTag'] == null) {
                    return SizedBox(
                      width: width,
                      height: height,
                      child: const Icon(Icons.movie),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      '${posterUrl(item['Id'].toString())}?tag=${item['PrimaryImageTag']}&quality=90',
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      headers: {'X-Emby-Token': token},
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: width,
                        height: height,
                        child: const Icon(Icons.movie),
                      ),
                    ),
                  );
                },
              ),
              title: Text('$title'),
              subtitle: subtitle != null ? Text('$subtitle') : null,
              onTap: () {
                close(context, null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailPage(
                      item: item,
                      server: server,
                      token: token,
                      playback: playback,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Start typing to search'));
    }
    return FutureBuilder(
      future: api != null ? Future.microtask(() => api.search(query)) : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (kDebugMode) {
            print(snapshot.error);
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = (snapshot.data as Iterable?)?.toList() ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No results'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final title = item['Name'] ?? item.name ?? 'Unknown';
            final subtitle = item['Type'] ?? item.type;
            return ListTile(
              leading: Builder(
                builder: (_) {
                  final isPoster =
                      item['Type'] == 'Movie' || item['Type'] == 'Series';
                  final width = isPoster ? 48.0 : 48.0;
                  final height = isPoster ? 72.0 : 48.0;

                  if (item['PrimaryImageTag'] == null) {
                    return SizedBox(
                      width: width,
                      height: height,
                      child: const Icon(Icons.movie),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      '${posterUrl(item['Id'].toString())}?tag=${item['PrimaryImageTag']}&quality=90',
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      headers: {'X-Emby-Token': token},
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: width,
                        height: height,
                        child: const Icon(Icons.movie),
                      ),
                    ),
                  );
                },
              ),
              title: Text('$title'),
              subtitle: subtitle != null ? Text('$subtitle') : null,
              onTap: () {
                close(context, null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ItemDetailPage(
                      item: item,
                      server: server,
                      token: token,
                      playback: playback,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

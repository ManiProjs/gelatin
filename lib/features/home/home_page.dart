import 'package:flutter/material.dart';
import 'package:gelatin/core/storage/auth_storage.dart';
import 'package:gelatin/features/auth/login_page.dart';
import 'package:gelatin/features/home/widgets/poster_card.dart';
import '../../core/api/jellyfin_api.dart';

class HomePage extends StatefulWidget {
  final String server;
  final String token;

  const HomePage({super.key, required this.server, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final JellyfinApi api;

  List<dynamic> libs = [];
  String? selectedLibraryId;
  String? heroLibraryId;
  bool loading = true;
  int selectedIndex = 0;
  int heroIndex = 0;
  final Map<String, Future<List<dynamic>>> cache = {};

  late Future<List<dynamic>> librariesFuture;

  @override
  void initState() {
    super.initState();

    api = JellyfinApi(server: widget.server, token: widget.token);

    librariesFuture = api.getLibraries();

    librariesFuture.then((data) {
      libs = data;
      loading = false;

      if (data.isNotEmpty) {
        selectedLibraryId = data.first['Id'];
      }
      selectedIndex = 0;
      heroIndex = 0;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: librariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final libs = snapshot.data ?? [];
          final activeLibs = selectedIndex == 0
              ? libs
              : [libs[selectedIndex - 1]];

          final movieLibs = activeLibs.where((l) {
            final type = (l['CollectionType'] ?? '').toString().toLowerCase();
            return type == 'movies' || type == 'tvshows';
          }).toList();

          final musicLibs = activeLibs.where((l) {
            final type = (l['CollectionType'] ?? '').toString().toLowerCase();
            return type == 'music';
          }).toList();

          if (libs.isEmpty) {
            return const Center(child: Text('No libraries found'));
          }

          return SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: true,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      heroIndex = 0;
                      selectedIndex = index;

                      if (index == 0) {
                        selectedLibraryId = libs.isNotEmpty
                            ? libs.first['Id']
                            : null;
                      } else {
                        selectedLibraryId = libs[index - 1]['Id'];
                      }

                      heroLibraryId = selectedLibraryId;
                    });
                  },
                  labelType: NavigationRailLabelType.none,
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    for (final lib in libs)
                      NavigationRailDestination(
                        icon: Icon(
                          lib['CollectionType'] == 'music'
                              ? Icons.music_note
                              : Icons.movie,
                        ),
                        label: Text(lib['Name'] ?? 'Unknown'),
                      ),
                  ],
                  trailing: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return SafeArea(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Settings',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ListTile(
                                          leading: const Icon(Icons.logout),
                                          title: const Text('Sign out'),
                                          onTap: () async {
                                            Navigator.of(context).pop();

                                            await AuthStorage.clear();

                                            if (!context.mounted) return;

                                            Navigator.of(
                                              context,
                                            ).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const LoginPage(), // or your actual login widget
                                              ),
                                              (route) => false,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const Text('Settings', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                const VerticalDivider(width: 1),

                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : selectedIndex == 0
                      ? CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: StatefulBuilder(
                                builder: (context, setHeroState) {
                                  return FutureBuilder<List<dynamic>>(
                                    future: cache.putIfAbsent(
                                      'items_hero_${selectedIndex}_${heroLibraryId ?? 'home'}',
                                      () => api.getItems(
                                        libs.isNotEmpty
                                            ? (selectedIndex == 0
                                                  ? libs.first['Id']
                                                  : selectedLibraryId ??
                                                        libs.first['Id'])
                                            : '',
                                      ),
                                    ),
                                    builder: (context, snap) {
                                      final items = snap.data ?? [];

                                      if (snap.connectionState ==
                                              ConnectionState.waiting ||
                                          items.isEmpty) {
                                        return const SizedBox(
                                          height: 320,
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      int localIndex = heroIndex.clamp(
                                        0,
                                        items.length - 1,
                                      );
                                      final item = items[localIndex];

                                      return Stack(
                                        children: [
                                          Container(
                                            height: 420,
                                            margin: const EdgeInsets.only(
                                              left: 12,
                                              right: 12,
                                              top: 12,
                                              bottom: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  '${widget.server}/Items/${item['Id']}/Images/Backdrop',
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Color(0xCC000000),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              alignment: Alignment.bottomLeft,
                                              padding: const EdgeInsets.all(16),
                                              child: Align(
                                                alignment: Alignment.bottomLeft,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: Image.network(
                                                    '${widget.server}/Items/${item['Id']}/Images/Logo',
                                                    height: 110,
                                                    fit: BoxFit.contain,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Text(
                                                            item['Name'] ?? '',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 22,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 8,
                                            top: 0,
                                            bottom: 0,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.chevron_left,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              onPressed: () {
                                                setHeroState(() {
                                                  if (items.isEmpty) return;
                                                  heroIndex =
                                                      (heroIndex -
                                                          1 +
                                                          items.length) %
                                                      items.length;
                                                });
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            right: 8,
                                            top: 0,
                                            bottom: 0,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                              onPressed: () {
                                                setHeroState(() {
                                                  if (items.isEmpty) return;
                                                  heroIndex =
                                                      (heroIndex + 1) %
                                                      items.length;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            // --- Inserted separation: movieLibs and musicLibs ---
                            for (final lib in movieLibs)
                              SliverToBoxAdapter(
                                key: ValueKey('movie_section_${lib['Id']}'),
                                child: FutureBuilder<List<dynamic>>(
                                  future: cache.putIfAbsent(
                                    'items_movie_${lib['Id']}',
                                    () => api.getItems(lib['Id']),
                                  ),
                                  builder: (context, snap) {
                                    final items = snap.data ?? [];

                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        right: 12,
                                        bottom: 24,
                                        top: 12,
                                      ),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 4,
                                              mainAxisSpacing: 10,
                                              crossAxisSpacing: 10,
                                              childAspectRatio: 0.65,
                                            ),
                                        itemCount: items.length,
                                        itemBuilder: (context, i) {
                                          final item = items[i];
                                          final imageUrl =
                                              '${widget.server}/Items/${item['Id']}/Images/Primary';

                                          return PosterCard(
                                            title: item['Name'] ?? '',
                                            imageUrl: imageUrl,
                                            headers: {
                                              'X-Emby-Token': widget.token,
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            for (final lib in musicLibs)
                              SliverToBoxAdapter(
                                key: ValueKey('music_section_${lib['Id']}'),
                                child: FutureBuilder<List<dynamic>>(
                                  future: cache.putIfAbsent(
                                    'items_music_${lib['Id']}',
                                    () => api.getItems(lib['Id']),
                                  ),
                                  builder: (context, snap) {
                                    final items = snap.data ?? [];

                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        right: 12,
                                        bottom: 24,
                                        top: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: List.generate(items.length, (
                                          i,
                                        ) {
                                          final item = items[i];

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                    width: 56,
                                                    height: 56,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            const Icon(
                                                              Icons.music_note,
                                                              size: 30,
                                                            ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        item['Name'] ?? '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        item['Album'] ??
                                                            item['AlbumArtist'] ??
                                                            '',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white70,
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        )
                      : selectedLibraryId == null
                      ? const Center(child: Text('No folder selected'))
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              key: ValueKey(selectedLibraryId),
                              child: FutureBuilder<List<dynamic>>(
                                future: cache.putIfAbsent(
                                  'lib_${selectedLibraryId!}',
                                  () => api.getItems(selectedLibraryId!),
                                ),
                                builder: (context, snap) {
                                  final items = snap.data ?? [];

                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final lib = libs.firstWhere(
                                    (e) => e['Id'] == selectedLibraryId,
                                  );

                                  final isMusic =
                                      lib['CollectionType'] == 'music';

                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Folder title and SizedBox removed for cleaner UI
                                        if (isMusic)
                                          Column(
                                            children: List.generate(items.length, (
                                              i,
                                            ) {
                                              final item = items[i];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      child: Image.network(
                                                        '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                        width: 56,
                                                        height: 56,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => const Icon(
                                                              Icons.music_note,
                                                              size: 30,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item['Name'] ?? '',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            item['Album'] ??
                                                                item['AlbumArtist'] ??
                                                                '',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white70,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          )
                                        else
                                          GridView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 4,
                                                  mainAxisSpacing: 10,
                                                  crossAxisSpacing: 10,
                                                  childAspectRatio: 0.65,
                                                ),
                                            itemCount: items.length,
                                            itemBuilder: (context, i) {
                                              final item = items[i];
                                              final imageUrl =
                                                  '${widget.server}/Items/${item['Id']}/Images/Primary';

                                              return PosterCard(
                                                title: item['Name'] ?? '',
                                                imageUrl: imageUrl,
                                                headers: {
                                                  'X-Emby-Token': widget.token,
                                                },
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

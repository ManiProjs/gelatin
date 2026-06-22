import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Gelatin')),

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

          if (libs.isEmpty) {
            return const Center(child: Text('No libraries found'));
          }

          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    heroIndex = 0;
                    selectedIndex = index;
                    if (index == 0) {
                      heroLibraryId = libs.isNotEmpty ? libs.first['Id'] : null;
                    } else {
                      heroLibraryId = libs[index - 1]['Id'];
                    }
                  });
                },
                labelType: NavigationRailLabelType.all,
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
                                    libs.isNotEmpty
                                        ? (selectedIndex == 0
                                              ? libs.first['Id']
                                              : selectedLibraryId ??
                                                    libs.first['Id'])
                                        : '',
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
                                          height: 320,
                                          margin: const EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            top: 12,
                                            bottom: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
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
                                                padding: const EdgeInsets.only(
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
                          for (final lib in libs)
                            SliverToBoxAdapter(
                              child: FutureBuilder<List<dynamic>>(
                                future: cache.putIfAbsent(
                                  lib['Id'],
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

                                  final isMusic =
                                      lib['CollectionType'] == 'music';

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
                                      children: [
                                        // Folder title and SizedBox removed for cleaner UI
                                        if (isMusic)
                                          Column(
                                            children: List.generate(
                                              items.length,
                                              (i) {
                                                final item = items[i];

                                                return ListTile(
                                                  leading: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: Image.network(
                                                      '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                      width: 48,
                                                      height: 48,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            _,
                                                            __,
                                                            ___,
                                                          ) => const Icon(
                                                            Icons.music_note,
                                                          ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    item['Name'] ?? '',
                                                  ),
                                                  subtitle: Text(
                                                    item['Album'] ??
                                                        item['AlbumArtist'] ??
                                                        '',
                                                  ),
                                                );
                                              },
                                            ),
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
                      )
                    : selectedLibraryId == null
                    ? const Center(child: Text('No folder selected'))
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: FutureBuilder<List<dynamic>>(
                              future: cache.putIfAbsent(
                                selectedLibraryId!,
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

                                            return ListTile(
                                              leading: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child: Image.network(
                                                  '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(
                                                        Icons.music_note,
                                                      ),
                                                ),
                                              ),
                                              title: Text(item['Name'] ?? ''),
                                              subtitle: Text(
                                                item['Album'] ??
                                                    item['AlbumArtist'] ??
                                                    '',
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
          );
        },
      ),
    );
  }
}

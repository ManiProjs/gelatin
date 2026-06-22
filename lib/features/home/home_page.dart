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
  bool loading = true;
  int selectedIndex = 0;

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
                    selectedIndex = index;
                    if (index > 0 && libs.isNotEmpty) {
                      selectedLibraryId = libs[index - 1]['Id'];
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
                      icon: const Icon(Icons.folder),
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
                          for (final lib in libs)
                            SliverToBoxAdapter(
                              child: FutureBuilder<List<dynamic>>(
                                future: api.getItems(lib['Id']),
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
                                        Text(
                                          lib['Name'],
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 12),

                                        if (isMusic)
                                          Column(
                                            children: List.generate(
                                              items.length,
                                              (i) {
                                                final item = items[i];

                                                return ListTile(
                                                  leading: const Icon(
                                                    Icons.music_note,
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
                              future: api.getItems(selectedLibraryId!),
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
                                      Text(
                                        lib['Name'],
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 12),

                                      if (isMusic)
                                        Column(
                                          children: List.generate(
                                            items.length,
                                            (i) {
                                              final item = items[i];

                                              return ListTile(
                                                leading: const Icon(
                                                  Icons.music_note,
                                                ),
                                                title: Text(item['Name'] ?? ''),
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gelatin/core/playback/playback_service.dart';
import 'package:gelatin/core/storage/auth_storage.dart';
import 'package:gelatin/features/auth/login_page.dart';
import 'package:gelatin/features/details/item_detail_page.dart';
import 'package:gelatin/features/home/widgets/poster_card.dart';
import 'package:gelatin/app.dart';
import 'package:gelatin/features/search/jellyfin_search_delegate.dart';
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

  late PlaybackService playback;

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

    playback = PlaybackService(api);

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
    final themeController = ThemeControllerScope.of(context);

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
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Move the existing showModalBottomSheet(...) code from the current settings destination branch here unchanged.
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
                                          leading: const Icon(
                                            Icons.palette_outlined,
                                          ),
                                          title: const Text('Appearance'),
                                          subtitle: Text(
                                            switch (themeController.mode) {
                                              ThemeMode.system => 'System',
                                              ThemeMode.light => 'Light',
                                              ThemeMode.dark => 'Dark',
                                            },
                                          ),
                                          onTap: () {
                                            Navigator.of(context).pop();
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (context) => SafeArea(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.brightness_auto,
                                                      ),
                                                      title: const Text(
                                                        'System',
                                                      ),
                                                      onTap: () async {
                                                        themeController
                                                            .setSystem();
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.light_mode,
                                                      ),
                                                      title: const Text(
                                                        'Light',
                                                      ),
                                                      onTap: () async {
                                                        themeController
                                                            .setLight();
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                        Icons.dark_mode,
                                                      ),
                                                      title: const Text('Dark'),
                                                      onTap: () async {
                                                        themeController
                                                            .setDark();
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const Divider(),
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
                                                    const LoginPage(),
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.settings),
                                SizedBox(width: 24),
                                Text('Settings'),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                            // Insert SearchBar at the top of Home slivers
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  height: 48,
                                  child: SearchBar(
                                    readOnly: true,
                                    leading: const Icon(Icons.search),
                                    hintText: 'Search',
                                    onTap: () {
                                      showSearch(
                                        context: context,
                                        delegate: JellyfinSearchDelegate(
                                          api: api,
                                          server: widget.server,
                                          token: widget.token,
                                          playback: playback,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
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

                                      // HERO UI POLISH
                                      final productionYear =
                                          item['ProductionYear']?.toString();
                                      final mediaType = (item['Type'] ?? '')
                                          .toString();
                                      final heroLogo = Image.network(
                                        '${widget.server}/Items/${item['Id']}/Images/Logo',
                                        height: 64,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Text(
                                                item['Name'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: -0.5,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            },
                                      );
                                      return Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ItemDetailPage(
                                                        server: widget.server,
                                                        token: widget.token,
                                                        item: item,
                                                        playback: playback,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 420,
                                              margin: const EdgeInsets.only(
                                                left: 20,
                                                right: 20,
                                                top: 16,
                                                bottom: 24,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                                      BorderRadius.circular(20),
                                                  gradient:
                                                      const LinearGradient(
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                        colors: [
                                                          Color(0xCC000000),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                ),
                                                alignment: Alignment.bottomLeft,
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // Left: Logo/title, metadata, play button
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          heroLogo,
                                                          if (productionYear !=
                                                                  null ||
                                                              mediaType
                                                                  .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
                                                                    bottom: 2.0,
                                                                  ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  if (productionYear !=
                                                                      null)
                                                                    Text(
                                                                      productionYear,
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white70,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  if (productionYear !=
                                                                          null &&
                                                                      mediaType
                                                                          .isNotEmpty)
                                                                    const Padding(
                                                                      padding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            6,
                                                                      ),
                                                                      child: Text(
                                                                        '·',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.white54,
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  if (mediaType
                                                                      .isNotEmpty)
                                                                    Text(
                                                                      mediaType,
                                                                      style: const TextStyle(
                                                                        color: Colors
                                                                            .white70,
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 10.0,
                                                                ),
                                                            child: FilledButton.icon(
                                                              style: FilledButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                foregroundColor:
                                                                    Colors
                                                                        .black,
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          22,
                                                                      vertical:
                                                                          10,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        22,
                                                                      ),
                                                                ),
                                                                textStyle: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              icon: const Icon(
                                                                Icons
                                                                    .play_arrow_rounded,
                                                                size: 26,
                                                              ),
                                                              label: const Text(
                                                                'Play',
                                                              ),
                                                              onPressed: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (_) => ItemDetailPage(
                                                                      server: widget
                                                                          .server,
                                                                      token: widget
                                                                          .token,
                                                                      item:
                                                                          item,
                                                                      playback:
                                                                          playback,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Right: Large poster image
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 16,
                                                            bottom: 4,
                                                            right: 2,
                                                          ),
                                                      child: Container(
                                                        width: 170,
                                                        height: 255,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                18,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.22,
                                                                  ),
                                                              blurRadius: 18,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    6,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        clipBehavior:
                                                            Clip.hardEdge,
                                                        child: Image.network(
                                                          '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Container(
                                                                color: Colors
                                                                    .grey[800],
                                                                child: const Icon(
                                                                  Icons.movie,
                                                                  color: Colors
                                                                      .white60,
                                                                  size: 48,
                                                                ),
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
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
                                    final visibleItems = items
                                        .take(10)
                                        .toList();
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        bottom: 36,
                                        top: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                lib['Name'] ?? 'Movies',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 24,
                                                ),
                                              ),
                                              const Spacer(),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  shape: const StadiumBorder(),
                                                  side: BorderSide(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4,
                                                      ),
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_forward,
                                                  size: 20,
                                                ),
                                                label: const Text('More'),
                                                onPressed: () {
                                                  final idx = libs.indexWhere(
                                                    (l) => l['Id'] == lib['Id'],
                                                  );
                                                  if (idx != -1) {
                                                    setState(() {
                                                      selectedIndex = idx + 1;
                                                      selectedLibraryId =
                                                          lib['Id'];
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 290,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: visibleItems.length,
                                              itemBuilder: (context, i) {
                                                final item = visibleItems[i];
                                                final imageUrl =
                                                    '${widget.server}/Items/${item['Id']}/Images/Primary';
                                                return GestureDetector(
                                                  onTap: () async {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ItemDetailPage(
                                                              server:
                                                                  widget.server,
                                                              token:
                                                                  widget.token,
                                                              item: item,
                                                              playback:
                                                                  playback,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 4.0,
                                                        ),
                                                    child: Container(
                                                      width: 170,
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 14,
                                                          ),
                                                      child: PosterCard(
                                                        title:
                                                            item['Name'] ?? '',
                                                        imageUrl: imageUrl,
                                                        headers: {
                                                          'X-Emby-Token':
                                                              widget.token,
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
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
                                    final visibleItems = items
                                        .take(10)
                                        .toList();
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 20,
                                        bottom: 36,
                                        top: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                lib['Name'] ?? 'Music',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 24,
                                                ),
                                              ),
                                              const Spacer(),
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  shape: const StadiumBorder(),
                                                  side: BorderSide(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4,
                                                      ),
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_forward,
                                                  size: 20,
                                                ),
                                                label: const Text('More'),
                                                onPressed: () {
                                                  final idx = libs.indexWhere(
                                                    (l) => l['Id'] == lib['Id'],
                                                  );
                                                  if (idx != -1) {
                                                    setState(() {
                                                      selectedIndex = idx + 1;
                                                      selectedLibraryId =
                                                          lib['Id'];
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 120,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: visibleItems.length,
                                              itemBuilder: (context, i) {
                                                final item = visibleItems[i];
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ItemDetailPage(
                                                              server:
                                                                  widget.server,
                                                              token:
                                                                  widget.token,
                                                              item: item,
                                                              playback:
                                                                  playback,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 260,
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 14,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerHighest,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
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
                                                            width: 64,
                                                            height: 64,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  _,
                                                                  __,
                                                                  ___,
                                                                ) => const Icon(
                                                                  Icons
                                                                      .music_note,
                                                                  size: 36,
                                                                  color: Colors
                                                                      .white54,
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 16,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                item['Name'] ??
                                                                    '',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 4,
                                                              ),
                                                              Text(
                                                                item['Album'] ??
                                                                    item['AlbumArtist'] ??
                                                                    '',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                left: 8.0,
                                                              ),
                                                          child: Material(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            shape:
                                                                const CircleBorder(),
                                                            child: InkWell(
                                                              customBorder:
                                                                  const CircleBorder(),
                                                              onTap: () {
                                                                // Play action (kept as before)
                                                              },
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      6.0,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .play_arrow_rounded,
                                                                  size: 28,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
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
                            // Insert SearchBar at the top of library view slivers
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  height: 48,
                                  child: SearchBar(
                                    readOnly: true,
                                    leading: const Icon(Icons.search),
                                    hintText: 'Search',
                                    onTap: () {
                                      showSearch(
                                        context: context,
                                        delegate: JellyfinSearchDelegate(
                                          api: api,
                                          server: widget.server,
                                          token: widget.token,
                                          playback: playback,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
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
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isMusic)
                                          Column(
                                            children: List.generate(items.length, (
                                              i,
                                            ) {
                                              final item = items[i];
                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ItemDetailPage(
                                                            server:
                                                                widget.server,
                                                            token: widget.token,
                                                            item: item,
                                                            playback: playback,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 14,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
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
                                                          width: 64,
                                                          height: 64,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => const Icon(
                                                                Icons
                                                                    .music_note,
                                                                size: 36,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              item['Name'] ??
                                                                  '',
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 16,
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
                                                                    fontSize:
                                                                        13,
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
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 8.0,
                                                            ),
                                                        child: Material(
                                                          color: Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                          shape:
                                                              const CircleBorder(),
                                                          child: InkWell(
                                                            customBorder:
                                                                const CircleBorder(),
                                                            onTap: () {
                                                              // Play action (kept as before)
                                                            },
                                                            child: const Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                    6.0,
                                                                  ),
                                                              child: Icon(
                                                                Icons
                                                                    .play_arrow_rounded,
                                                                size: 28,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
                                              return GestureDetector(
                                                onTap: () async {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ItemDetailPage(
                                                            server:
                                                                widget.server,
                                                            token: widget.token,
                                                            item: item,
                                                            playback: playback,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: PosterCard(
                                                  title: item['Name'] ?? '',
                                                  imageUrl: imageUrl,
                                                  headers: {
                                                    'X-Emby-Token':
                                                        widget.token,
                                                  },
                                                ),
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

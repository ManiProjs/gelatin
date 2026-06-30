import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gelatin/core/playback/playback_service.dart';
import 'package:gelatin/core/storage/auth_storage.dart';
import 'package:gelatin/features/auth/login_page.dart';
import 'package:gelatin/features/details/item_detail_page.dart';
import 'package:gelatin/features/home/widgets/poster_card.dart';
import 'package:gelatin/app.dart';
import 'package:gelatin/features/search/jellyfin_search_delegate.dart';
import '../../core/api/jellyfin_api.dart';

class _FeedSection {
  final String type;
  final dynamic lib;
  final int score;
  final IconData icon;
  final String title;

  _FeedSection({
    required this.type,
    this.lib,
    required this.score,
    required this.icon,
    required this.title,
  });
}

class HomePage extends StatefulWidget {
  final String server;
  final String token;

  const HomePage({super.key, required this.server, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _heroTimer;

  void _startHeroTimer(
    List<dynamic> items,
    void Function(VoidCallback) setHeroState,
  ) {
    _heroTimer?.cancel();
    if (items.isEmpty) return;

    _heroTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      setHeroState(() {
        heroIndex = (heroIndex + 1) % items.length;
      });
    });
  }

  // --- HERO CHIP HELPER ---
  Widget _heroChip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  late final JellyfinApi api;
  final Map<String, int> _libInteractionScore = {};

  late PlaybackService playback;

  void _boostLibrary(String? libId, [int amount = 2]) {
    if (libId == null) return;

    final key = libId.toString();
    _libInteractionScore[key] = (_libInteractionScore[key] ?? 0) + amount;
  }

  List<dynamic> libs = [];
  String? selectedLibraryId;
  String? heroLibraryId;
  bool loading = true;
  int selectedIndex = 0;
  int heroIndex = 0;
  bool focusMode = false;
  final Map<String, Future<List<dynamic>>> cache = {};

  late Future<List<dynamic>> librariesFuture;

  List<_FeedSection> _buildFeedSections(List<dynamic> libs) {
    int score(dynamic lib) {
      final id = lib['Id']?.toString() ?? '';
      final type = (lib['CollectionType'] ?? '').toString().toLowerCase();

      int base;

      switch (type) {
        case 'movies':
        case 'tvshows':
        case 'tv':
        case 'series':
          base = 100;
          break;
        case 'music':
          base = 80;
          break;
        default:
          base = 50;
      }

      final interaction = _libInteractionScore[id] ?? 0;

      return base + (interaction * 20);
    }

    final sorted = [...libs]
      ..sort((a, b) {
        return score(b).compareTo(score(a));
      });

    return sorted.map((lib) {
      final type = (lib['CollectionType'] ?? '').toString().toLowerCase();
      final icon = switch (type) {
        'movies' => Icons.movie_creation_outlined,
        'tvshows' || 'tv' || 'series' => Icons.live_tv_outlined,
        'music' => Icons.graphic_eq,
        _ => Icons.auto_awesome,
      };
      final title = switch (type) {
        'movies' => '🎬 Tonight\'s Watch',
        'tvshows' || 'tv' || 'series' => '📺 Continue Watching',
        'music' => '🎵 Music Mix',
        _ => '✨ Discover',
      };
      return _FeedSection(
        lib: lib,
        score: score(lib),
        type: type,
        icon: icon,
        title: title,
      );
    }).toList();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    super.dispose();
  }

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

  List<dynamic> _rankLibraries(List<dynamic> libs) {
    int rank(dynamic lib) {
      final type = (lib['CollectionType'] ?? '').toString().toLowerCase();

      if (type == 'movies' ||
          type == 'tvshows' ||
          type == 'tv' ||
          type == 'series') {
        return 0; // highest priority
      }
      if (type == 'music') {
        return 1;
      }
      return 2;
    }

    final sorted = [...libs];
    sorted.sort((a, b) => rank(a).compareTo(rank(b)));
    return sorted;
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
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await AuthStorage.clear();
              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ServerPage()),
                (route) => false,
              );
            });

            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to connect to Jellyfin'),
                  SizedBox(height: 12),
                  CircularProgressIndicator(),
                ],
              ),
            );
          }

          final libs = snapshot.data ?? [];
          final filteredLibs = libs.where((l) {
            final type = (l['CollectionType'] ?? '').toString().toLowerCase();
            return type != 'folders';
          }).toList();
          final rankedLibs = _rankLibraries(libs);
          final feedSections = _buildFeedSections(rankedLibs);

          if (libs.isEmpty) {
            return const Center(child: Text('No libraries found'));
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    extended: !focusMode,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) {
                      final libId = index == 0
                          ? (filteredLibs.isNotEmpty
                                ? filteredLibs.first['Id']
                                : null)
                          : filteredLibs[index - 1]['Id'];

                      _boostLibrary(libId, 1);

                      setState(() {
                        heroIndex = 0;
                        selectedIndex = index;
                        if (index == 0) {
                          selectedLibraryId = filteredLibs.isNotEmpty
                              ? filteredLibs.first['Id']
                              : null;
                        } else {
                          selectedLibraryId = filteredLibs[index - 1]['Id'];
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
                      for (int i = 0; i < filteredLibs.length; i++)
                        NavigationRailDestination(
                          icon: Builder(
                            builder: (context) {
                              final lib = filteredLibs[i];
                              final isSelected = selectedIndex == i + 1;

                              final type = (lib['CollectionType'] ?? '')
                                  .toString()
                                  .toLowerCase();

                              IconData iconData;
                              switch (type) {
                                case 'music':
                                  iconData = Icons.music_note;
                                  break;
                                case 'movies':
                                  iconData = Icons.movie;
                                  break;
                                case 'tvshows':
                                case 'tv':
                                case 'series':
                                  iconData = Icons.tv;
                                  break;
                                case 'photos':
                                  iconData = Icons.photo_library;
                                  break;
                                case 'books':
                                  iconData = Icons.menu_book;
                                  break;
                                default:
                                  iconData = Icons.folder;
                              }

                              final color = isSelected
                                  ? switch (type) {
                                      'music' => Colors.pinkAccent,
                                      'movies' => Colors.blueAccent,
                                      'tvshows' ||
                                      'tv' ||
                                      'series' => Colors.purpleAccent,
                                      'photos' => Colors.greenAccent,
                                      'books' => Colors.orangeAccent,
                                      _ => Colors.grey,
                                    }
                                  : Colors.grey.shade500;

                              return Icon(iconData, color: color);
                            },
                          ),
                          label: Builder(
                            builder: (context) {
                              final lib = filteredLibs[i];
                              return Text(lib['Name'] ?? 'Unknown');
                            },
                          ),
                        ),
                    ],
                    trailing: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final pageContext = context;
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
                                        SwitchListTile(
                                          value: focusMode,
                                          onChanged: (value) {
                                            setState(() {
                                              focusMode = value;
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          secondary: const Icon(
                                            Icons.center_focus_strong,
                                          ),
                                          title: const Text('Focus Mode'),
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading: const Icon(
                                            Icons.palette_outlined,
                                          ),
                                          title: const Text('Appearance'),
                                          onTap: () async {
                                            Navigator.of(context).pop();
                                            await Future<void>.delayed(
                                              const Duration(milliseconds: 180),
                                            );
                                            if (!pageContext.mounted) return;

                                            await showModalBottomSheet<void>(
                                              context: pageContext,
                                              showDragHandle: true,
                                              builder: (dialogContext) {
                                                final controller =
                                                    ThemeControllerScope.of(
                                                      dialogContext,
                                                    );
                                                return SafeArea(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      RadioListTile<ThemeMode>(
                                                        value: ThemeMode.system,
                                                        groupValue:
                                                            controller.mode,
                                                        onChanged: (_) =>
                                                            controller
                                                                .setSystem(),
                                                        secondary: const Icon(
                                                          Icons
                                                              .brightness_auto_outlined,
                                                        ),
                                                        title: const Text(
                                                          'System',
                                                        ),
                                                      ),
                                                      RadioListTile<ThemeMode>(
                                                        value: ThemeMode.light,
                                                        groupValue:
                                                            controller.mode,
                                                        onChanged: (_) =>
                                                            controller
                                                                .setLight(),
                                                        secondary: const Icon(
                                                          Icons
                                                              .light_mode_outlined,
                                                        ),
                                                        title: const Text(
                                                          'Light',
                                                        ),
                                                      ),
                                                      RadioListTile<ThemeMode>(
                                                        value: ThemeMode.dark,
                                                        groupValue:
                                                            controller.mode,
                                                        onChanged: (_) =>
                                                            controller
                                                                .setDark(),
                                                        secondary: const Icon(
                                                          Icons
                                                              .dark_mode_outlined,
                                                        ),
                                                        title: const Text(
                                                          'Dark',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        const Divider(),
                                        ListTile(
                                          leading: const Icon(Icons.logout),
                                          title: const Text('Sign out'),
                                          onTap: () async {
                                            /* unchanged */
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
                            padding: const EdgeInsets.all(12),
                            child: focusMode
                                ? const Icon(Icons.settings)
                                : Row(
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
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }

                                        int localIndex = heroIndex.clamp(
                                          0,
                                          items.length - 1,
                                        );
                                        final item = items[localIndex];

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (mounted) {
                                                _startHeroTimer(
                                                  items,
                                                  setHeroState,
                                                );
                                              }
                                            });

                                        // HERO UI POLISH
                                        final productionYear =
                                            item['ProductionYear']?.toString();
                                        final mediaType = (item['Type'] ?? '')
                                            .toString();
                                        final heroLogo = Image.network(
                                          '${widget.server}/Items/${item['Id']}/Images/Logo',
                                          height: 100,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            // Fallback: outlined + filled text for hero logo title
                                            return Stack(
                                              children: [
                                                // Outline
                                                Text(
                                                  item['Name'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      TextStyle(
                                                        fontSize: 34,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: -0.5,
                                                        height: 0.95,
                                                      ).copyWith(
                                                        foreground: Paint()
                                                          ..style =
                                                              PaintingStyle
                                                                  .stroke
                                                          ..strokeWidth = 3
                                                          ..color = Theme.of(
                                                            context,
                                                          ).colorScheme.surface,
                                                      ),
                                                ),
                                                // Fill
                                                Text(
                                                  item['Name'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.5,
                                                    color: Colors.white,
                                                    height: 0.95,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        return AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 450,
                                          ),
                                          switchInCurve: Curves.easeOutCubic,
                                          switchOutCurve: Curves.easeInCubic,
                                          transitionBuilder:
                                              (child, animation) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(
                                                        0.08,
                                                        0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(animation),
                                                    child: child,
                                                  ),
                                                );
                                              },
                                          child: SizedBox(
                                            key: ValueKey(
                                              item['Id'] ?? heroIndex,
                                            ),
                                            child: Stack(
                                              children: [
                                                // Cinematic hero section with clean clipping
                                                GestureDetector(
                                                  onTap: () {
                                                    _boostLibrary(
                                                      selectedLibraryId,
                                                      2,
                                                    );
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
                                                    height: 420,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                          '${widget.server}/Items/${item['Id']}/Images/Backdrop',
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    child: Stack(
                                                      children: [
                                                        // --- Accent-tinted gradient overlay for hero banner only ---
                                                        Positioned.fill(
                                                          child: IgnorePointer(
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                gradient: LinearGradient(
                                                                  begin: Alignment
                                                                      .centerLeft,
                                                                  end: Alignment
                                                                      .centerRight,
                                                                  colors: [
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .surface,
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .surface
                                                                        .withValues(
                                                                          alpha:
                                                                              0.85,
                                                                        ),
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .surface
                                                                        .withValues(
                                                                          alpha:
                                                                              0.45,
                                                                        ),
                                                                    Colors
                                                                        .transparent,
                                                                  ],
                                                                  stops: const [
                                                                    0.0,
                                                                    0.22,
                                                                    0.48,
                                                                    0.82,
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Cinematic vertical overlay
                                                        Container(
                                                          decoration: const BoxDecoration(
                                                            gradient: LinearGradient(
                                                              begin: Alignment
                                                                  .bottomCenter,
                                                              end: Alignment
                                                                  .topCenter,
                                                              colors: [
                                                                Color(
                                                                  0xF2000000,
                                                                ),
                                                                Color(
                                                                  0xC0000000,
                                                                ),
                                                                Color(
                                                                  0x40000000,
                                                                ),
                                                                Colors
                                                                    .transparent,
                                                              ],
                                                              stops: [
                                                                0.0,
                                                                0.35,
                                                                0.7,
                                                                1.0,
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        // Cinematic horizontal overlay for readability
                                                        IgnorePointer(
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                begin: Alignment
                                                                    .centerLeft,
                                                                end: Alignment
                                                                    .centerRight,
                                                                colors: [
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .surface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.90,
                                                                      ),
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .surface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.70,
                                                                      ),
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .surface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.35,
                                                                      ),
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .surface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.10,
                                                                      ),
                                                                  Colors
                                                                      .transparent,
                                                                ],
                                                                stops: const [
                                                                  0.0,
                                                                  0.18,
                                                                  0.40,
                                                                  0.62,
                                                                  0.82,
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Content
                                                        Container(
                                                          alignment: Alignment
                                                              .bottomLeft,
                                                          padding:
                                                              const EdgeInsets.fromLTRB(
                                                                32,
                                                                24,
                                                                32,
                                                                28,
                                                              ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              // Left: Logo/title, metadata, play button
                                                              Expanded(
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    // --- Hero Logo (height changed) ---
                                                                    Image.network(
                                                                      '${widget.server}/Items/${item['Id']}/Images/Logo',
                                                                      height:
                                                                          88,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                      errorBuilder:
                                                                          (
                                                                            context,
                                                                            error,
                                                                            stackTrace,
                                                                          ) {
                                                                            // Fallback: outlined + filled text for hero logo title (smaller variant)
                                                                            return Stack(
                                                                              children: [
                                                                                // Outline
                                                                                Text(
                                                                                  item['Name'] ??
                                                                                      '',
                                                                                  maxLines: 2,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style:
                                                                                      TextStyle(
                                                                                        fontSize: 28,
                                                                                        fontWeight: FontWeight.bold,
                                                                                        letterSpacing: -0.5,
                                                                                      ).copyWith(
                                                                                        foreground: Paint()
                                                                                          ..style = PaintingStyle.stroke
                                                                                          ..strokeWidth = 3
                                                                                          ..color = Theme.of(
                                                                                            context,
                                                                                          ).colorScheme.surface,
                                                                                      ),
                                                                                ),
                                                                                // Fill
                                                                                Text(
                                                                                  item['Name'] ??
                                                                                      '',
                                                                                  maxLines: 2,
                                                                                  overflow: TextOverflow.ellipsis,
                                                                                  style: const TextStyle(
                                                                                    color: Colors.white,
                                                                                    fontSize: 28,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    letterSpacing: -0.5,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            );
                                                                          },
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          20,
                                                                    ),
                                                                    // --- Plot Overview ---
                                                                    if ((item['Overview'] ??
                                                                            '')
                                                                        .toString()
                                                                        .isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          bottom:
                                                                              18,
                                                                        ),
                                                                        child: ConstrainedBox(
                                                                          constraints: const BoxConstraints(
                                                                            maxWidth:
                                                                                520,
                                                                          ),
                                                                          child: Text(
                                                                            item['Overview'],
                                                                            maxLines:
                                                                                3,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            style: const TextStyle(
                                                                              color: Colors.white70,
                                                                              fontSize: 15,
                                                                              height: 1.45,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    if (productionYear !=
                                                                            null ||
                                                                        mediaType
                                                                            .isNotEmpty)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          bottom:
                                                                              8,
                                                                        ),
                                                                        child: Wrap(
                                                                          spacing:
                                                                              8,
                                                                          runSpacing:
                                                                              8,
                                                                          children: [
                                                                            if (productionYear !=
                                                                                null)
                                                                              _heroChip(
                                                                                productionYear,
                                                                              ),
                                                                            if (mediaType.isNotEmpty)
                                                                              _heroChip(
                                                                                mediaType,
                                                                              ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    if (item['CommunityRating'] !=
                                                                        null)
                                                                      Padding(
                                                                        padding: const EdgeInsets.only(
                                                                          bottom:
                                                                              14,
                                                                        ),
                                                                        child: _heroChip(
                                                                          '${(item['CommunityRating'] as num).toStringAsFixed(1)} ★',
                                                                          icon:
                                                                              Icons.star_rounded,
                                                                        ),
                                                                      ),
                                                                    Padding(
                                                                      padding:
                                                                          const EdgeInsets.only(
                                                                            top:
                                                                                10.0,
                                                                          ),
                                                                      child: Wrap(
                                                                        spacing:
                                                                            16,
                                                                        runSpacing:
                                                                            12,
                                                                        children: [
                                                                          FilledButton.icon(
                                                                            style: ButtonStyle(
                                                                              backgroundColor: WidgetStatePropertyAll(
                                                                                Theme.of(
                                                                                  context,
                                                                                ).colorScheme.primary,
                                                                              ),
                                                                              foregroundColor: WidgetStatePropertyAll(
                                                                                Theme.of(
                                                                                  context,
                                                                                ).colorScheme.onPrimary,
                                                                              ),
                                                                              padding: const WidgetStatePropertyAll(
                                                                                EdgeInsets.symmetric(
                                                                                  horizontal: 34,
                                                                                  vertical: 18,
                                                                                ),
                                                                              ),
                                                                              shape: const WidgetStatePropertyAll(
                                                                                StadiumBorder(),
                                                                              ),
                                                                              elevation: const WidgetStatePropertyAll(
                                                                                2,
                                                                              ),
                                                                              textStyle: const WidgetStatePropertyAll(
                                                                                TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              overlayColor: const WidgetStatePropertyAll(
                                                                                Colors.white10,
                                                                              ),
                                                                              mouseCursor: const WidgetStatePropertyAll(
                                                                                SystemMouseCursors.click,
                                                                              ),
                                                                            ),
                                                                            icon: const Icon(
                                                                              Icons.play_arrow_rounded,
                                                                              size: 24,
                                                                            ),
                                                                            label: const Text(
                                                                              'Play Now',
                                                                            ),
                                                                            onPressed: () {
                                                                              _boostLibrary(
                                                                                selectedLibraryId,
                                                                                2,
                                                                              );
                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder:
                                                                                      (
                                                                                        _,
                                                                                      ) => ItemDetailPage(
                                                                                        server: widget.server,
                                                                                        token: widget.token,
                                                                                        item: item,
                                                                                        playback: playback,
                                                                                      ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                          OutlinedButton.icon(
                                                                            style: ButtonStyle(
                                                                              padding: const WidgetStatePropertyAll(
                                                                                EdgeInsets.symmetric(
                                                                                  horizontal: 30,
                                                                                  vertical: 18,
                                                                                ),
                                                                              ),
                                                                              shape: const WidgetStatePropertyAll(
                                                                                StadiumBorder(),
                                                                              ),
                                                                              side: const WidgetStatePropertyAll(
                                                                                BorderSide(
                                                                                  color: Colors.white30,
                                                                                  width: 1.2,
                                                                                ),
                                                                              ),
                                                                              foregroundColor: const WidgetStatePropertyAll(
                                                                                Colors.white,
                                                                              ),
                                                                              textStyle: const WidgetStatePropertyAll(
                                                                                TextStyle(
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.w700,
                                                                                ),
                                                                              ),
                                                                              overlayColor: const WidgetStatePropertyAll(
                                                                                Colors.white10,
                                                                              ),
                                                                              mouseCursor: const WidgetStatePropertyAll(
                                                                                SystemMouseCursors.click,
                                                                              ),
                                                                            ),
                                                                            icon: const Icon(
                                                                              Icons.info_outline_rounded,
                                                                            ),
                                                                            label: const Text(
                                                                              'Details',
                                                                            ),
                                                                            onPressed: () {
                                                                              _boostLibrary(
                                                                                selectedLibraryId,
                                                                                2,
                                                                              );
                                                                              Navigator.push(
                                                                                context,
                                                                                MaterialPageRoute(
                                                                                  builder:
                                                                                      (
                                                                                        _,
                                                                                      ) => ItemDetailPage(
                                                                                        server: widget.server,
                                                                                        token: widget.token,
                                                                                        item: item,
                                                                                        playback: playback,
                                                                                      ),
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ],
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
                                                                  width: 160,
                                                                  height: 240,
                                                                  decoration: BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          18,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: Colors
                                                                          .white12,
                                                                    ),
                                                                    boxShadow: [
                                                                      BoxShadow(
                                                                        color: Colors
                                                                            .black
                                                                            .withValues(
                                                                              alpha: 0.22,
                                                                            ),
                                                                        blurRadius:
                                                                            28,
                                                                        offset:
                                                                            const Offset(
                                                                              0,
                                                                              10,
                                                                            ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  clipBehavior:
                                                                      Clip.hardEdge,
                                                                  child: Image.network(
                                                                    '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorBuilder: (_, _, _) => Container(
                                                                      color: Colors
                                                                          .grey[800],
                                                                      child: const Icon(
                                                                        Icons
                                                                            .movie,
                                                                        color: Colors
                                                                            .white60,
                                                                        size:
                                                                            48,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 8,
                                                  top: 0,
                                                  bottom: 0,
                                                  child: IconButton(
                                                    icon: Opacity(
                                                      opacity: 0.75,
                                                      child: const Icon(
                                                        Icons.chevron_left,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      setHeroState(() {
                                                        if (items.isEmpty) {
                                                          return;
                                                        }
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
                                                    icon: Opacity(
                                                      opacity: 0.75,
                                                      child: const Icon(
                                                        Icons.chevron_right,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      setHeroState(() {
                                                        if (items.isEmpty) {
                                                          return;
                                                        }
                                                        heroIndex =
                                                            (heroIndex + 1) %
                                                            items.length;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              // --- Inserted separation: movieLibs and musicLibs ---
                              for (final section in feedSections)
                                SliverToBoxAdapter(
                                  key: ValueKey('section_${section.lib['Id']}'),
                                  child: Builder(
                                    builder: (context) {
                                      final type = section.type;
                                      return FutureBuilder<List<dynamic>>(
                                        future: cache.putIfAbsent(
                                          'semantic_${section.type}',
                                          () async {
                                            final all = <dynamic>[];
                                            for (final library in rankedLibs) {
                                              final items = await api.getItems(
                                                library['Id'],
                                              );
                                              all.addAll(items);
                                            }
                                            return all;
                                          },
                                        ),
                                        builder: (context, snap) {
                                          final items = snap.data ?? [];
                                          if (snap.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Padding(
                                              padding: EdgeInsets.all(24),
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }
                                          List<dynamic> visibleItems;
                                          switch (type) {
                                            case 'movies':
                                              visibleItems = items.where((
                                                item,
                                              ) {
                                                final type =
                                                    (item['Type'] ?? '')
                                                        .toString();

                                                return type == 'Movie';
                                              }).toList();

                                              visibleItems.sort(
                                                (a, b) =>
                                                    ((b['CommunityRating'] ?? 0)
                                                            as num)
                                                        .compareTo(
                                                          (a['CommunityRating'] ??
                                                                  0)
                                                              as num,
                                                        ),
                                              );

                                              visibleItems = visibleItems
                                                  .take(10)
                                                  .toList();
                                              break;
                                            case 'tvshows':
                                            case 'tv':
                                            case 'series':
                                              visibleItems = items.where((
                                                item,
                                              ) {
                                                final itemType =
                                                    (item['Type'] ?? '')
                                                        .toString();
                                                final pos =
                                                    item['UserData']?['PlaybackPositionTicks'] ??
                                                    0;
                                                return (itemType == 'Episode' ||
                                                        itemType == 'Series') &&
                                                    pos > 0;
                                              }).toList();

                                              if (visibleItems.isEmpty) {
                                                visibleItems = items
                                                    .where((item) {
                                                      final itemType =
                                                          (item['Type'] ?? '')
                                                              .toString();
                                                      return itemType ==
                                                              'Episode' ||
                                                          itemType == 'Series';
                                                    })
                                                    .take(10)
                                                    .toList();
                                              }
                                              break;
                                            case 'music':
                                              visibleItems = items.where((
                                                item,
                                              ) {
                                                final itemType =
                                                    (item['Type'] ?? '')
                                                        .toString();
                                                return itemType == 'Audio' ||
                                                    itemType == 'MusicAlbum' ||
                                                    itemType == 'MusicArtist';
                                              }).toList();

                                              visibleItems.sort(
                                                (a, b) =>
                                                    DateTime.tryParse(
                                                      (b['DateCreated'] ?? '')
                                                          .toString(),
                                                    )?.compareTo(
                                                      DateTime.tryParse(
                                                            (a['DateCreated'] ??
                                                                    '')
                                                                .toString(),
                                                          ) ??
                                                          DateTime(1970),
                                                    ) ??
                                                    0,
                                              );

                                              visibleItems = visibleItems
                                                  .take(10)
                                                  .toList();
                                              break;
                                            default:
                                              visibleItems = items
                                                  .take(10)
                                                  .toList();
                                          }
                                          final isMusic = type == 'music';
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
                                                    Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        section.icon,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      section.title,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  switch (type) {
                                                    'movies' =>
                                                      'Top-rated movies picked for you',
                                                    'tvshows' ||
                                                    'tv' ||
                                                    'series' =>
                                                      visibleItems.isEmpty
                                                          ? 'Popular shows to start'
                                                          : 'Resume where you left off',
                                                    'music' =>
                                                      'Recently added music',
                                                    _ =>
                                                      'Discover something new today',
                                                  },
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 20),
                                                SizedBox(
                                                  height: isMusic ? 140 : 290,
                                                  child: ListView.builder(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount:
                                                        visibleItems.length,
                                                    itemBuilder: (context, i) {
                                                      final item =
                                                          visibleItems[i];
                                                      return GestureDetector(
                                                        onTap: () {
                                                          _boostLibrary(
                                                            selectedLibraryId,
                                                            2,
                                                          );
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  ItemDetailPage(
                                                                    server: widget
                                                                        .server,
                                                                    token: widget
                                                                        .token,
                                                                    item: item,
                                                                    playback:
                                                                        playback,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        child: Container(
                                                          width: isMusic
                                                              ? 260
                                                              : 170,
                                                          margin:
                                                              const EdgeInsets.only(
                                                                right: 14,
                                                              ),
                                                          child: PosterCard(
                                                            title:
                                                                item['Name'] ??
                                                                '',
                                                            imageUrl:
                                                                '${widget.server}/Items/${item['Id']}/Images/Primary',
                                                            headers: {
                                                              'X-Emby-Token':
                                                                  widget.token,
                                                            },
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
                                                    _boostLibrary(
                                                      selectedLibraryId,
                                                      2,
                                                    );
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
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 14,
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
                                                                  _,
                                                                  _,
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
                                                                style: const TextStyle(
                                                                  fontSize: 13,
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
                                                    _boostLibrary(
                                                      selectedLibraryId,
                                                      2,
                                                    );
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
            ),
          );
        },
      ),
    );
  }
}

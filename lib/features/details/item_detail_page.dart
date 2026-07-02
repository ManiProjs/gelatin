import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gelatin/core/playback/playback_controller.dart';
import 'package:gelatin/core/playback/playback_service.dart';
import 'package:gelatin/features/player/player_page.dart';

class ItemDetailPage extends StatefulWidget {
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
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  static const double _kWideLayoutBreakpoint = 980;
  late Map<String, dynamic> _item;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.item);
  }

  String _formatRuntime(dynamic ticksValue) {
    if (ticksValue is! int || ticksValue <= 0) return '';
    final totalMinutes = ticksValue ~/ 600000000;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${totalMinutes} min';
  }

  String _formatDate(dynamic value) {
    if (value is! String || value.length < 10) return '';
    return value.substring(0, 10);
  }

  Widget _buildHeroPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {double width = 220}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchLatestItem(String id) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${widget.server}/Users/Me/Items/$id?Fields=UserData,MediaSources',
        ),
        headers: {'X-Emby-Token': widget.token},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  Future<void> _refreshItem() async {
    final id = _item['Id']?.toString();
    if (id == null || id.isEmpty) return;

    final previousPlaybackPositionTicks =
        (_item['UserData']?['PlaybackPositionTicks'] as int?) ?? 0;

    Future<bool> tryRefresh({required bool acceptUnchanged}) async {
      final latestItem = await _fetchLatestItem(id);
      if (!mounted || latestItem == null) return false;

      final latestUserData = latestItem['UserData'] is Map
          ? Map<String, dynamic>.from(latestItem['UserData'] as Map)
          : null;
      final latestMediaSources = latestItem['MediaSources'];
      final latestRunTimeTicks = latestItem['RunTimeTicks'];
      final latestPlaybackPositionTicks =
          (latestUserData?['PlaybackPositionTicks'] as int?) ?? 0;

      final changed =
          latestPlaybackPositionTicks != previousPlaybackPositionTicks ||
          latestMediaSources != null ||
          latestRunTimeTicks != null;

      if (!changed && !acceptUnchanged) {
        return false;
      }

      setState(() {
        final updated = Map<String, dynamic>.from(_item);

        if (latestUserData != null) {
          updated['UserData'] = latestUserData;
        }
        if (latestMediaSources != null) {
          updated['MediaSources'] = latestMediaSources;
        }
        if (latestRunTimeTicks != null) {
          updated['RunTimeTicks'] = latestRunTimeTicks;
        }

        _item = updated;
      });

      return true;
    }

    if (await tryRefresh(acceptUnchanged: false)) return;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (await tryRefresh(acceptUnchanged: false)) return;

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await tryRefresh(acceptUnchanged: true);
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final server = widget.server;
    final token = widget.token;
    final playback = widget.playback;
    final id = item['Id'];

    final backdropUrl = '$server/Items/$id/Images/Backdrop';
    final posterUrl = '$server/Items/$id/Images/Primary';
    final logoUrl = '$server/Items/$id/Images/Logo';

    final runtimeLabel = _formatRuntime(item['RunTimeTicks']);
    final premiereDate = _formatDate(item['PremiereDate']);
    final genres = item['Genres'] is List
        ? (item['Genres'] as List).cast<dynamic>()
        : const [];
    final taglines = item['Taglines'] is List
        ? (item['Taglines'] as List).cast<dynamic>()
        : const [];
    final studios = item['Studios'] is List
        ? (item['Studios'] as List).cast<dynamic>()
        : const [];
    final productionLocations = item['ProductionLocations'] is List
        ? (item['ProductionLocations'] as List).cast<dynamic>()
        : const [];
    final mediaSources = item['MediaSources'] is List
        ? (item['MediaSources'] as List).cast<dynamic>()
        : const [];
    final providerIds = item['ProviderIds'] is Map
        ? item['ProviderIds'] as Map
        : const {};
    final people = item['People'] is List
        ? (item['People'] as List)
              .whereType<Map>()
              .map((person) => Map<String, dynamic>.from(person))
              .toList()
        : <Map<String, dynamic>>[];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _kWideLayoutBreakpoint;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 500,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        backdropUrl,
                        headers: {'X-Emby-Token': token},
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: Colors.black),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xF5000000),
                              Color(0xCC000000),
                              Color(0x66000000),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.28, 0.55, 0.85],
                          ),
                        ),
                      ),
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
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 28,
                                    offset: Offset(0, 10),
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  posterUrl,
                                  headers: {'X-Emby-Token': token},
                                  width: 160,
                                  height: 240,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox(
                                    width: 160,
                                    height: 240,
                                    child: ColoredBox(
                                      color: Colors.black26,
                                      child: Icon(
                                        Icons.movie,
                                        size: 80,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (item['ProductionYear'] != null)
                                        _buildHeroPill(
                                          '${item['ProductionYear']}',
                                        ),
                                      if (runtimeLabel.isNotEmpty)
                                        _buildHeroPill(runtimeLabel),
                                      if (item['OfficialRating'] != null)
                                        _buildHeroPill(
                                          '${item['OfficialRating']}',
                                        ),
                                      if (item['Type'] != null)
                                        _buildHeroPill('${item['Type']}'),
                                    ],
                                  ),
                                  if (taglines.isNotEmpty || genres.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (taglines.isNotEmpty)
                                            Text(
                                              '${taglines.first}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white70,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          if (genres.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              genres.join(' • '),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white60,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  if (item['CommunityRating'] != null) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (item['CommunityRating'] as num)
                                              .toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  Builder(
                                    builder: (context) {
                                      final playbackPositionTicks =
                                          item['UserData']?['PlaybackPositionTicks'] ??
                                          0;
                                      final canResume =
                                          playbackPositionTicks > 0;
                                      final runTimeTicks =
                                          item['RunTimeTicks'] ?? 0;
                                      double progress = 0.0;
                                      if (runTimeTicks is int &&
                                          runTimeTicks > 0 &&
                                          playbackPositionTicks is int) {
                                        progress =
                                            playbackPositionTicks /
                                            runTimeTicks;
                                        if (progress < 0) progress = 0.0;
                                        if (progress > 1) progress = 1.0;
                                      }

                                      String formatTicks(int ticks) {
                                        final seconds = (ticks / 10000000)
                                            .floor();
                                        final h = (seconds ~/ 3600)
                                            .toString()
                                            .padLeft(2, '0');
                                        final m = ((seconds % 3600) ~/ 60)
                                            .toString()
                                            .padLeft(2, '0');
                                        final s = (seconds % 60)
                                            .toString()
                                            .padLeft(2, '0');
                                        return '$h:$m:$s';
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (canResume)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 320,
                                                    child: LinearProgressIndicator(
                                                      value: progress,
                                                      minHeight: 6,
                                                      backgroundColor:
                                                          Colors.white12,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.amber),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Resume from ${formatTicks(playbackPositionTicks)}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 12,
                                            children: [
                                              FilledButton.icon(
                                                onPressed: () async {
                                                  try {
                                                    final id = item['Id']
                                                        .toString();
                                                    final latestItem =
                                                        await _fetchLatestItem(
                                                          id,
                                                        );
                                                    final effectiveItem =
                                                        latestItem ?? item;
                                                    final latestUserData =
                                                        effectiveItem['UserData']
                                                            as Map<
                                                              String,
                                                              dynamic
                                                            >? ??
                                                        const {};
                                                    final latestPlaybackPositionTicks =
                                                        latestUserData['PlaybackPositionTicks'] ??
                                                        0;
                                                    final latestCanResume =
                                                        latestPlaybackPositionTicks
                                                            is int &&
                                                        latestPlaybackPositionTicks >
                                                            0;
                                                    final type =
                                                        effectiveItem['Type'];

                                                    String streamUrl;

                                                    if (type == 'Audio') {
                                                      streamUrl =
                                                          '$server/Audio/$id/stream';
                                                    } else {
                                                      try {
                                                        final controller =
                                                            PlaybackController(
                                                              playback,
                                                            );
                                                        streamUrl =
                                                            await controller
                                                                .resolve(id);
                                                      } catch (_) {
                                                        streamUrl =
                                                            '$server/Items/$id/Download';
                                                      }
                                                    }

                                                    if (!context.mounted)
                                                      return;

                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => PlayerPage(
                                                          url: streamUrl,
                                                          title:
                                                              effectiveItem['Name'] ??
                                                              item['Name'] ??
                                                              '',
                                                          headers: {
                                                            'X-Emby-Token':
                                                                token,
                                                          },
                                                          startPosition:
                                                              latestCanResume
                                                              ? Duration(
                                                                  microseconds:
                                                                      latestPlaybackPositionTicks ~/
                                                                      10,
                                                                )
                                                              : null,
                                                          server: server,
                                                          itemId: id,
                                                        ),
                                                      ),
                                                    );

                                                    if (!context.mounted) {
                                                      return;
                                                    }

                                                    await _refreshItem();
                                                  } catch (_) {
                                                    if (!context.mounted)
                                                      return;

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
                                                icon: Icon(
                                                  canResume
                                                      ? Icons.play_circle_fill
                                                      : Icons.play_arrow,
                                                ),
                                                label: Text(
                                                  canResume
                                                      ? 'Resume'
                                                      : 'Play Now',
                                                ),
                                              ),
                                              OutlinedButton.icon(
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  18,
                                                                ),
                                                          ),
                                                    ),
                                                    builder: (context) {
                                                      final entries = item
                                                          .entries
                                                          .where(
                                                            (e) =>
                                                                e.value !=
                                                                    null &&
                                                                e.value
                                                                    is! Map &&
                                                                e.value
                                                                    is! List,
                                                          )
                                                          .toList();
                                                      return Padding(
                                                        padding: MediaQuery.of(
                                                          context,
                                                        ).viewInsets,
                                                        child: SizedBox(
                                                          height:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.height *
                                                              0.65,
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Container(
                                                                width: 40,
                                                                height: 5,
                                                                margin:
                                                                    const EdgeInsets.symmetric(
                                                                      vertical:
                                                                          10,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .grey[400],
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                              ),
                                                              const Text(
                                                                'Technical Info',
                                                                style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                              const Divider(),
                                                              Expanded(
                                                                child: ListView.builder(
                                                                  itemCount:
                                                                      entries
                                                                          .length,
                                                                  itemBuilder: (context, i) {
                                                                    final e =
                                                                        entries[i];
                                                                    return ListTile(
                                                                      title: Text(
                                                                        e.key,
                                                                        style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                      subtitle: Text(
                                                                        e.value
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                          fontSize:
                                                                              15,
                                                                        ),
                                                                      ),
                                                                    );
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
                                                icon: const Icon(
                                                  Icons.info_outline_rounded,
                                                ),
                                                label: const Text(
                                                  'Technical Info',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionCard(
                                    context: context,
                                    title: 'Overview',
                                    subtitle:
                                        item['Taglines'] is List &&
                                            (item['Taglines'] as List)
                                                .isNotEmpty
                                        ? '${(item['Taglines'] as List).first}'
                                        : null,
                                    child: Text(
                                      item['Overview'] ??
                                          'No description available.',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _buildSectionCard(
                                    context: context,
                                    title: 'Cast & Crew',
                                    subtitle:
                                        'Directors, writers, and top cast',
                                    child: Builder(
                                      builder: (context) {
                                        if (people.isEmpty) {
                                          return const Text(
                                            'No cast or crew data available.',
                                          );
                                        }
                                        final directors = people
                                            .where(
                                              (p) => p['Type'] == 'Director',
                                            )
                                            .toList();
                                        final writers = people
                                            .where((p) => p['Type'] == 'Writer')
                                            .toList();
                                        final actors = people
                                            .where((p) => p['Type'] == 'Actor')
                                            .take(8)
                                            .toList();
                                        final displayPeople = [
                                          ...directors,
                                          ...writers,
                                          ...actors,
                                        ];
                                        final seenIds = <dynamic>{};
                                        final filteredPeople =
                                            <Map<String, dynamic>>[];
                                        for (final p in displayPeople) {
                                          if (p['Id'] == null ||
                                              seenIds.contains(p['Id']))
                                            continue;
                                          seenIds.add(p['Id']);
                                          filteredPeople.add(p);
                                        }
                                        return SizedBox(
                                          height: 118,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: filteredPeople.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 12),
                                            itemBuilder: (context, i) {
                                              final person = filteredPeople[i];
                                              final personId = person['Id'];
                                              final imgUrl = personId != null
                                                  ? '$server/Items/$personId/Images/Primary'
                                                  : null;
                                              return SizedBox(
                                                width: 78,
                                                child: Column(
                                                  children: [
                                                    ClipOval(
                                                      child: imgUrl != null
                                                          ? Image.network(
                                                              imgUrl,
                                                              headers: {
                                                                'X-Emby-Token':
                                                                    token,
                                                              },
                                                              width: 58,
                                                              height: 58,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    _,
                                                                    __,
                                                                    ___,
                                                                  ) => Container(
                                                                    width: 58,
                                                                    height: 58,
                                                                    color: Colors
                                                                        .grey[300],
                                                                    child: const Icon(
                                                                      Icons
                                                                          .person,
                                                                      size: 32,
                                                                      color: Colors
                                                                          .white54,
                                                                    ),
                                                                  ),
                                                            )
                                                          : Container(
                                                              width: 58,
                                                              height: 58,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: const Icon(
                                                                Icons.person,
                                                                size: 32,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                            ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      person['Name'] ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      person['Type'] ?? '',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _buildSectionCard(
                                    context: context,
                                    title: 'Technical',
                                    subtitle: 'File and stream metadata',
                                    child: Wrap(
                                      spacing: 24,
                                      runSpacing: 12,
                                      children: [
                                        if (item['Container'] != null)
                                          _buildInfoTile(
                                            'CONTAINER',
                                            '${item['Container']}',
                                          ),
                                        if (item['VideoType'] != null)
                                          _buildInfoTile(
                                            'VIDEO TYPE',
                                            '${item['VideoType']}',
                                          ),
                                        if (item['Width'] != null &&
                                            item['Height'] != null)
                                          _buildInfoTile(
                                            'RESOLUTION',
                                            '${item['Width']} × ${item['Height']}',
                                          ),
                                        if (mediaSources.isNotEmpty &&
                                            mediaSources.first is Map &&
                                            mediaSources.first['Bitrate'] !=
                                                null)
                                          _buildInfoTile(
                                            'BITRATE',
                                            '${((mediaSources.first['Bitrate'] as num) / 1000000).toStringAsFixed(2)} Mbps',
                                          ),
                                        if (mediaSources.isNotEmpty &&
                                            mediaSources.first is Map &&
                                            mediaSources.first['VideoCodec'] !=
                                                null)
                                          _buildInfoTile(
                                            'VIDEO CODEC',
                                            '${mediaSources.first['VideoCodec']}',
                                          ),
                                        if (mediaSources.isNotEmpty &&
                                            mediaSources.first is Map &&
                                            mediaSources.first['AudioCodec'] !=
                                                null)
                                          _buildInfoTile(
                                            'AUDIO CODEC',
                                            '${mediaSources.first['AudioCodec']}',
                                          ),
                                        if (mediaSources.isNotEmpty &&
                                            mediaSources.first is Map &&
                                            mediaSources.first['VideoRange'] !=
                                                null)
                                          _buildInfoTile(
                                            'HDR',
                                            '${mediaSources.first['VideoRange']}',
                                          ),
                                        if (mediaSources.isNotEmpty &&
                                            mediaSources.first is Map &&
                                            mediaSources.first['Size'] != null)
                                          _buildInfoTile(
                                            'SIZE',
                                            '${((mediaSources.first['Size'] as num) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
                                          ),
                                        if (item['Path'] != null)
                                          _buildInfoTile(
                                            'PATH',
                                            '${item['Path']}',
                                            width: 460,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionCard(
                                    context: context,
                                    title: 'Details',
                                    subtitle:
                                        'Metadata, release info, and credits',
                                    child: Wrap(
                                      spacing: 24,
                                      runSpacing: 12,
                                      children: [
                                        if (studios.isNotEmpty &&
                                            studios.first is Map &&
                                            studios.first['Name'] != null)
                                          _buildInfoTile(
                                            'STUDIO',
                                            '${studios.first['Name']}',
                                          ),
                                        if (genres.isNotEmpty)
                                          _buildInfoTile(
                                            'GENRES',
                                            genres.join(', '),
                                          ),
                                        if (premiereDate.isNotEmpty)
                                          _buildInfoTile(
                                            'PREMIERE DATE',
                                            premiereDate,
                                          ),
                                        if (item['OriginalTitle'] != null)
                                          _buildInfoTile(
                                            'ORIGINAL TITLE',
                                            '${item['OriginalTitle']}',
                                          ),
                                        if (item['OfficialRating'] != null)
                                          _buildInfoTile(
                                            'OFFICIAL RATING',
                                            '${item['OfficialRating']}',
                                          ),
                                        if (item['CommunityRating'] != null)
                                          _buildInfoTile(
                                            'COMMUNITY RATING',
                                            (item['CommunityRating'] as num)
                                                .toStringAsFixed(1),
                                          ),
                                        if (item['CriticRating'] != null)
                                          _buildInfoTile(
                                            'CRITIC RATING',
                                            '${item['CriticRating']}',
                                          ),
                                        if (taglines.isNotEmpty)
                                          _buildInfoTile(
                                            'TAGLINE',
                                            '${taglines.first}',
                                          ),
                                        if (productionLocations.isNotEmpty)
                                          _buildInfoTile(
                                            'PRODUCTION LOCATIONS',
                                            productionLocations.join(', '),
                                          ),
                                        if (providerIds.isNotEmpty)
                                          _buildInfoTile(
                                            'PROVIDER IDS',
                                            providerIds.keys.join(', '),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  _buildSectionCard(
                                    context: context,
                                    title: 'Credits',
                                    subtitle: 'People attached to this title',
                                    child: Builder(
                                      builder: (context) {
                                        if (people.isEmpty) {
                                          return const Text(
                                            'No people data available.',
                                          );
                                        }
                                        final directors = people
                                            .where(
                                              (p) => p['Type'] == 'Director',
                                            )
                                            .map((p) => p['Name'])
                                            .whereType<String>()
                                            .toList();
                                        final writers = people
                                            .where((p) => p['Type'] == 'Writer')
                                            .map((p) => p['Name'])
                                            .whereType<String>()
                                            .toList();
                                        final actors = people
                                            .where((p) => p['Type'] == 'Actor')
                                            .map((p) => p['Name'])
                                            .whereType<String>()
                                            .take(8)
                                            .toList();
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (directors.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Text(
                                                  'Director: ${directors.join(', ')}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (writers.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Text(
                                                  'Writers: ${writers.join(', ')}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (actors.isNotEmpty)
                                              Text(
                                                'Cast: ${actors.join(', ')}',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionCard(
                              context: context,
                              title: 'Overview',
                              subtitle: taglines.isNotEmpty
                                  ? '${taglines.first}'
                                  : null,
                              child: Text(
                                item['Overview'] ?? 'No description available.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSectionCard(
                              context: context,
                              title: 'Details',
                              subtitle: 'Metadata, release info, and credits',
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 12,
                                children: [
                                  if (studios.isNotEmpty &&
                                      studios.first is Map &&
                                      studios.first['Name'] != null)
                                    _buildInfoTile(
                                      'STUDIO',
                                      '${studios.first['Name']}',
                                    ),
                                  if (genres.isNotEmpty)
                                    _buildInfoTile('GENRES', genres.join(', ')),
                                  if (premiereDate.isNotEmpty)
                                    _buildInfoTile(
                                      'PREMIERE DATE',
                                      premiereDate,
                                    ),
                                  if (item['OriginalTitle'] != null)
                                    _buildInfoTile(
                                      'ORIGINAL TITLE',
                                      '${item['OriginalTitle']}',
                                    ),
                                  if (item['OfficialRating'] != null)
                                    _buildInfoTile(
                                      'OFFICIAL RATING',
                                      '${item['OfficialRating']}',
                                    ),
                                  if (item['CommunityRating'] != null)
                                    _buildInfoTile(
                                      'COMMUNITY RATING',
                                      (item['CommunityRating'] as num)
                                          .toStringAsFixed(1),
                                    ),
                                  if (item['CriticRating'] != null)
                                    _buildInfoTile(
                                      'CRITIC RATING',
                                      '${item['CriticRating']}',
                                    ),
                                  if (taglines.isNotEmpty)
                                    _buildInfoTile(
                                      'TAGLINE',
                                      '${taglines.first}',
                                    ),
                                  if (productionLocations.isNotEmpty)
                                    _buildInfoTile(
                                      'PRODUCTION LOCATIONS',
                                      productionLocations.join(', '),
                                    ),
                                  if (providerIds.isNotEmpty)
                                    _buildInfoTile(
                                      'PROVIDER IDS',
                                      providerIds.keys.join(', '),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSectionCard(
                              context: context,
                              title: 'Cast & Crew',
                              subtitle: 'Directors, writers, and top cast',
                              child: Builder(
                                builder: (context) {
                                  if (people.isEmpty) {
                                    return const Text(
                                      'No cast or crew data available.',
                                    );
                                  }
                                  final directors = people
                                      .where((p) => p['Type'] == 'Director')
                                      .toList();
                                  final writers = people
                                      .where((p) => p['Type'] == 'Writer')
                                      .toList();
                                  final actors = people
                                      .where((p) => p['Type'] == 'Actor')
                                      .take(8)
                                      .toList();
                                  final displayPeople = [
                                    ...directors,
                                    ...writers,
                                    ...actors,
                                  ];
                                  final seenIds = <dynamic>{};
                                  final filteredPeople =
                                      <Map<String, dynamic>>[];
                                  for (final p in displayPeople) {
                                    if (p['Id'] == null ||
                                        seenIds.contains(p['Id']))
                                      continue;
                                    seenIds.add(p['Id']);
                                    filteredPeople.add(p);
                                  }
                                  return SizedBox(
                                    height: 118,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: filteredPeople.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, i) {
                                        final person = filteredPeople[i];
                                        final personId = person['Id'];
                                        final imgUrl = personId != null
                                            ? '$server/Items/$personId/Images/Primary'
                                            : null;
                                        return SizedBox(
                                          width: 78,
                                          child: Column(
                                            children: [
                                              ClipOval(
                                                child: imgUrl != null
                                                    ? Image.network(
                                                        imgUrl,
                                                        headers: {
                                                          'X-Emby-Token': token,
                                                        },
                                                        width: 58,
                                                        height: 58,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              width: 58,
                                                              height: 58,
                                                              color: Colors
                                                                  .grey[300],
                                                              child: const Icon(
                                                                Icons.person,
                                                                size: 32,
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                            ),
                                                      )
                                                    : Container(
                                                        width: 58,
                                                        height: 58,
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 32,
                                                          color: Colors.white54,
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                person['Name'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                person['Type'] ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSectionCard(
                              context: context,
                              title: 'Technical',
                              subtitle: 'File and stream metadata',
                              child: Wrap(
                                spacing: 24,
                                runSpacing: 12,
                                children: [
                                  if (item['Container'] != null)
                                    _buildInfoTile(
                                      'CONTAINER',
                                      '${item['Container']}',
                                    ),
                                  if (item['VideoType'] != null)
                                    _buildInfoTile(
                                      'VIDEO TYPE',
                                      '${item['VideoType']}',
                                    ),
                                  if (item['Width'] != null &&
                                      item['Height'] != null)
                                    _buildInfoTile(
                                      'RESOLUTION',
                                      '${item['Width']} × ${item['Height']}',
                                    ),
                                  if (mediaSources.isNotEmpty &&
                                      mediaSources.first is Map &&
                                      mediaSources.first['Bitrate'] != null)
                                    _buildInfoTile(
                                      'BITRATE',
                                      '${((mediaSources.first['Bitrate'] as num) / 1000000).toStringAsFixed(2)} Mbps',
                                    ),
                                  if (mediaSources.isNotEmpty &&
                                      mediaSources.first is Map &&
                                      mediaSources.first['VideoCodec'] != null)
                                    _buildInfoTile(
                                      'VIDEO CODEC',
                                      '${mediaSources.first['VideoCodec']}',
                                    ),
                                  if (mediaSources.isNotEmpty &&
                                      mediaSources.first is Map &&
                                      mediaSources.first['AudioCodec'] != null)
                                    _buildInfoTile(
                                      'AUDIO CODEC',
                                      '${mediaSources.first['AudioCodec']}',
                                    ),
                                  if (mediaSources.isNotEmpty &&
                                      mediaSources.first is Map &&
                                      mediaSources.first['VideoRange'] != null)
                                    _buildInfoTile(
                                      'HDR',
                                      '${mediaSources.first['VideoRange']}',
                                    ),
                                  if (mediaSources.isNotEmpty &&
                                      mediaSources.first is Map &&
                                      mediaSources.first['Size'] != null)
                                    _buildInfoTile(
                                      'SIZE',
                                      '${((mediaSources.first['Size'] as num) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
                                    ),
                                  if (item['Path'] != null)
                                    _buildInfoTile(
                                      'PATH',
                                      '${item['Path']}',
                                      width: 460,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

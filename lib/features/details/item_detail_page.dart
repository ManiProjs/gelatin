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
            expandedHeight: 500,
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
                        // Poster image with shadow and border
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
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.movie, size: 80),
                            ),
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
                              // Chips for year, runtime, official rating, and media type as custom pills
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (item['ProductionYear'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        '${item['ProductionYear']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (item['RunTimeTicks'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        '${((item['RunTimeTicks'] as int) ~/ 600000000)} min',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (item['OfficialRating'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        '${item['OfficialRating']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (item['Type'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        '${item['Type']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Taglines and genres subtle display
                              if ((item['Taglines'] != null &&
                                      item['Taglines'] is List &&
                                      (item['Taglines'] as List).isNotEmpty) ||
                                  (item['Genres'] != null &&
                                      item['Genres'] is List &&
                                      (item['Genres'] as List).isNotEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 2,
                                  ),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 2,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (item['Taglines'] != null &&
                                          item['Taglines'] is List &&
                                          (item['Taglines'] as List).isNotEmpty)
                                        Text(
                                          (item['Taglines'] as List).first,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white70,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      if (item['Genres'] != null &&
                                          item['Genres'] is List &&
                                          (item['Genres'] as List).isNotEmpty)
                                        Text(
                                          (item['Genres'] as List).join(', '),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white54,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              if (item['CommunityRating'] != null) ...[
                                const SizedBox(height: 8),
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
                              // --- Begin Resume/Play Button Area ---
                              Builder(
                                builder: (context) {
                                  final playbackPositionTicks =
                                      item['UserData']?['PlaybackPositionTicks'] ??
                                      0;
                                  final canResume = playbackPositionTicks > 0;
                                  final runTimeTicks =
                                      item['RunTimeTicks'] ?? 0;
                                  double progress = 0.0;
                                  if (runTimeTicks is int &&
                                      runTimeTicks > 0 &&
                                      playbackPositionTicks is int) {
                                    progress =
                                        playbackPositionTicks / runTimeTicks;
                                    if (progress < 0) progress = 0.0;
                                    if (progress > 1) progress = 1.0;
                                  }
                                  String formatTicks(int ticks) {
                                    final seconds = (ticks / 10000000).floor();
                                    final h = (seconds ~/ 3600)
                                        .toString()
                                        .padLeft(2, '0');
                                    final m = ((seconds % 3600) ~/ 60)
                                        .toString()
                                        .padLeft(2, '0');
                                    final s = (seconds % 60).toString().padLeft(
                                      2,
                                      '0',
                                    );
                                    return '$h:$m:$s';
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (canResume) ...[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                backgroundColor: Colors.white12,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.amber),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Resume from ${formatTicks(playbackPositionTicks)}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      Wrap(
                                        spacing: 12,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () async {
                                              try {
                                                final id = item['Id']
                                                    .toString();
                                                final type = item['Type'];

                                                String streamUrl;

                                                if (type == 'Audio') {
                                                  // direct music stream (no PlaybackInfo)
                                                  streamUrl =
                                                      '$server/Audio/$id/stream';
                                                } else {
                                                  try {
                                                    final controller =
                                                        PlaybackController(
                                                          playback,
                                                        );
                                                    streamUrl = await controller
                                                        .resolve(id);
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
                                                      headers: {
                                                        'X-Emby-Token': token,
                                                      },
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
                                            icon: Icon(
                                              canResume
                                                  ? Icons.play_circle_fill
                                                  : Icons.play_arrow,
                                            ),
                                            label: Text(
                                              canResume ? 'Resume' : 'Play Now',
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  18,
                                                                ),
                                                          ),
                                                    ),
                                                builder: (context) {
                                                  final entries = item.entries
                                                      .where(
                                                        (e) =>
                                                            e.value != null &&
                                                            e.value is! Map &&
                                                            e.value is! List,
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
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 5,
                                                            margin:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 10,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .grey[400],
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        12,
                                                                      ),
                                                                ),
                                                          ),
                                                          const Text(
                                                            "Technical Info",
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
                                                              itemCount: entries
                                                                  .length,
                                                              itemBuilder: (context, i) {
                                                                final e =
                                                                    entries[i];
                                                                return ListTile(
                                                                  title: Text(
                                                                    e.key,
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
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
                                            label: const Text("Technical Info"),
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
                              // --- End Resume/Play Button Area ---
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
                  // --- Overview section in Card ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Overview",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item['Overview'] ?? 'No description available.',
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // --- Cast & Crew section in Card ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Cast & Crew",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final people = (item['People'] is List)
                                  ? (item['People'] as List)
                                  : [];
                              if (people.isEmpty) {
                                return const Text(
                                  'No cast or crew data available.',
                                );
                              }
                              // Prioritize: directors, writers, then top 5 actors
                              final directors = people
                                  .where((p) => (p['Type'] == 'Director'))
                                  .toList();
                              final writers = people
                                  .where((p) => (p['Type'] == 'Writer'))
                                  .toList();
                              final actors = people
                                  .where((p) => (p['Type'] == 'Actor'))
                                  .take(5)
                                  .toList();
                              final displayPeople = [
                                ...directors,
                                ...writers,
                                ...actors,
                              ];
                              // Remove duplicates by Id
                              final seenIds = <dynamic>{};
                              final filteredPeople = <Map<String, dynamic>>[];
                              for (final p in displayPeople) {
                                if (p['Id'] != null &&
                                    !seenIds.contains(p['Id'])) {
                                  seenIds.add(p['Id']);
                                  filteredPeople.add(p as Map<String, dynamic>);
                                }
                              }
                              return SizedBox(
                                height: 110,
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
                                      width: 70,
                                      child: Column(
                                        children: [
                                          ClipOval(
                                            child: imgUrl != null
                                                ? Image.network(
                                                    imgUrl,
                                                    headers: {
                                                      'X-Emby-Token': token,
                                                    },
                                                    width: 54,
                                                    height: 54,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          _,
                                                          __,
                                                          ___,
                                                        ) => Container(
                                                          width: 54,
                                                          height: 54,
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.person,
                                                            size: 32,
                                                            color:
                                                                Colors.white54,
                                                          ),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 54,
                                                    height: 54,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 32,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(height: 4),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // --- Details section in Card ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Details",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              if (item['Studios'] != null &&
                                  item['Studios'] is List &&
                                  (item['Studios'] as List).isNotEmpty &&
                                  (item['Studios'][0]['Name'] != null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'STUDIOS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['Studios'][0]['Name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['Genres'] != null &&
                                  item['Genres'] is List &&
                                  (item['Genres'] as List).isNotEmpty)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'GENRES',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['Genres'] as List).join(', '),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['CommunityRating'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'COMMUNITY RATING',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['CommunityRating'] as num)
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['OriginalTitle'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'ORIGINAL TITLE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['OriginalTitle'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['PremiereDate'] != null &&
                                  (item['PremiereDate'] as String).length >= 10)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PREMIERE DATE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['PremiereDate'] as String)
                                            .substring(0, 10),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // --- Additional info cards ---
                              if (item['Taglines'] != null &&
                                  item['Taglines'] is List &&
                                  (item['Taglines'] as List).isNotEmpty)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'TAGLINE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['Taglines'] as List).first,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['ProductionLocations'] != null &&
                                  item['ProductionLocations'] is List &&
                                  (item['ProductionLocations'] as List)
                                      .isNotEmpty)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PRODUCTION LOCATIONS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['ProductionLocations'] as List)
                                            .join(', '),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['CriticRating'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CRITIC RATING',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['CriticRating'].toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['ProviderIds'] != null &&
                                  item['ProviderIds'] is Map &&
                                  (item['ProviderIds'] as Map).isNotEmpty)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PROVIDER IDS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (item['ProviderIds'] as Map).keys.join(
                                          ', ',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['People'] != null &&
                                  item['People'] is List &&
                                  (item['People'] as List).isNotEmpty)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PEOPLE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final people =
                                              (item['People'] as List)
                                                  .cast<Map<String, dynamic>>();
                                          final directors = people
                                              .where(
                                                (p) => p['Type'] == 'Director',
                                              )
                                              .map((p) => p['Name'])
                                              .toList();
                                          final writers = people
                                              .where(
                                                (p) => p['Type'] == 'Writer',
                                              )
                                              .map((p) => p['Name'])
                                              .toList();
                                          final actors = people
                                              .where(
                                                (p) => p['Type'] == 'Actor',
                                              )
                                              .map((p) => p['Name'])
                                              .take(5)
                                              .toList();
                                          final roles = <String>[];
                                          if (directors.isNotEmpty) {
                                            roles.add(
                                              'Director: ${directors.join(', ')}',
                                            );
                                          }
                                          if (writers.isNotEmpty) {
                                            roles.add(
                                              'Writer: ${writers.join(', ')}',
                                            );
                                          }
                                          if (actors.isNotEmpty) {
                                            roles.add(
                                              'Actors: ${actors.join(', ')}',
                                            );
                                          }
                                          return Text(
                                            roles.join('\n'),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // --- Technical section in Card ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              "Technical",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 24,
                            runSpacing: 12,
                            children: [
                              if (item['Container'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CONTAINER',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['Container'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['VideoType'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VIDEO TYPE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['VideoType'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['Path'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PATH',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['Path'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // --- Additional technical cards ---
                              if (item['Width'] != null &&
                                  item['Height'] != null)
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RESOLUTION',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['Width']} x ${item['Height']}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['MediaSources'] != null &&
                                  item['MediaSources'] is List &&
                                  (item['MediaSources'] as List).isNotEmpty &&
                                  (item['MediaSources'][0]['Bitrate'] != null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'BITRATE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${((item['MediaSources'][0]['Bitrate'] as num) / 1000000).toStringAsFixed(2)} Mbps',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['MediaSources'] != null &&
                                  item['MediaSources'] is List &&
                                  (item['MediaSources'] as List).isNotEmpty &&
                                  (item['MediaSources'][0]['VideoCodec'] !=
                                      null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VIDEO CODEC',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['MediaSources'][0]['VideoCodec']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['MediaSources'] != null &&
                                  item['MediaSources'] is List &&
                                  (item['MediaSources'] as List).isNotEmpty &&
                                  (item['MediaSources'][0]['AudioCodec'] !=
                                      null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'AUDIO CODEC',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['MediaSources'][0]['AudioCodec']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['MediaSources'] != null &&
                                  item['MediaSources'] is List &&
                                  (item['MediaSources'] as List).isNotEmpty &&
                                  (item['MediaSources'][0]['VideoRange'] !=
                                      null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'HDR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['MediaSources'][0]['VideoRange']
                                            .toString(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (item['MediaSources'] != null &&
                                  item['MediaSources'] is List &&
                                  (item['MediaSources'] as List).isNotEmpty &&
                                  (item['MediaSources'][0]['Size'] != null))
                                SizedBox(
                                  width: 220,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SIZE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${((item['MediaSources'][0]['Size'] as num) / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // --- Similar to This section in Card ---
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              "Similar to This",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            "Based on genres and media type.",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final similarItems = item['SimilarItems'];
                              if (similarItems != null &&
                                  similarItems is List &&
                                  similarItems.isNotEmpty) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: List.generate(similarItems.length, (
                                      i,
                                    ) {
                                      final similar =
                                          similarItems[i]
                                              as Map<String, dynamic>;
                                      final posterUrl =
                                          '$server/Items/${similar['Id']}/Images/Primary';
                                      return Padding(
                                        padding: EdgeInsets.only(right: 16),
                                        child: SizedBox(
                                          width: 150,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ItemDetailPage(
                                                        server: server,
                                                        token: token,
                                                        item: similar,
                                                        playback: playback,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: AspectRatio(
                                                    aspectRatio: 2 / 3,
                                                    child: Image.network(
                                                      posterUrl,
                                                      headers: {
                                                        'X-Emby-Token': token,
                                                      },
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) =>
                                                          Container(
                                                            color: Colors
                                                                .grey[900],
                                                            child: const Icon(
                                                              Icons.movie,
                                                              size: 48,
                                                              color: Colors
                                                                  .white24,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  similar['Name'] ?? '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              } else {
                                return const Text(
                                  'No similar titles available.',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
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

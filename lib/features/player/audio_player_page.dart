import 'dart:async';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:media_kit/media_kit.dart';

class AudioPlayerPage extends StatefulWidget {
  final String url;
  final String title;
  final String? artist;
  final String? album;
  final Map<String, String>? headers;
  final Duration? startPosition;
  final String? artworkUrl;

  const AudioPlayerPage({
    super.key,
    required this.url,
    required this.title,
    this.artist,
    this.album,
    this.headers,
    this.startPosition,
    this.artworkUrl,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage>
    with SingleTickerProviderStateMixin {
  late final Player _player;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = true;
  bool _didInitialSeek = false;
  bool _isScrubbing = false;
  double? _scrubSeconds;
  bool _didPopWithResult = false;
  bool _hasOpenedMedia = false;
  late final AnimationController _gradientController;
  late final Animation<double> _gradientT;
  List<Color>? _artworkGradientColors;

  List<Color> get _backgroundGradientColors {
    return _artworkGradientColors ??
        const [Color(0xFF1C2430), Color(0xFF090909)];
  }

  Color _toneForBackground(
    Color color, {
    double targetLightness = 0.18,
    double maxSaturation = 0.42,
  }) {
    final hsl = HSLColor.fromColor(color);

    final isNearNeutral = hsl.saturation < 0.12 || hsl.lightness < 0.12;
    if (isNearNeutral) {
      final neutralLightness = targetLightness.clamp(0.08, 0.24);
      return HSLColor.fromAHSL(1, 0, 0, neutralLightness).toColor();
    }

    final saturation = hsl.saturation.clamp(0.16, maxSaturation);
    final lightness = targetLightness.clamp(0.10, 0.28);
    return hsl.withSaturation(saturation).withLightness(lightness).toColor();
  }

  Future<void> _loadArtworkGradient() async {
    final artworkUrl = widget.artworkUrl?.trim();
    if (artworkUrl == null || artworkUrl.isEmpty) {
      return;
    }

    try {
      final palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(artworkUrl),
        maximumColorCount: 18,
      );

      final candidates = <Color>[];
      void addColor(Color? color) {
        if (color != null) candidates.add(color);
      }

      addColor(palette.dominantColor?.color);
      addColor(palette.vibrantColor?.color);
      addColor(palette.darkVibrantColor?.color);
      addColor(palette.mutedColor?.color);
      addColor(palette.darkMutedColor?.color);
      candidates.addAll(palette.colors);

      if (candidates.isEmpty) return;

      final primary = _toneForBackground(
        candidates.first,
        targetLightness: 0.20,
        maxSaturation: 0.36,
      );
      Color secondary = _toneForBackground(
        candidates.last,
        targetLightness: 0.11,
        maxSaturation: 0.28,
      );

      for (final color in candidates.skip(1)) {
        final toned = _toneForBackground(
          color,
          targetLightness: 0.11,
          maxSaturation: 0.28,
        );
        final distance =
            (primary.red - toned.red).abs() +
            (primary.green - toned.green).abs() +
            (primary.blue - toned.blue).abs();
        if (distance > 72) {
          secondary = toned;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _artworkGradientColors = [primary, secondary];
      });
    } catch (_) {
      // Ignore artwork palette failures and keep the fallback gradient.
    }
  }

  @override
  void initState() {
    super.initState();
    _player = Player();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
    _gradientT = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );

    _positionSub = _player.stream.position.listen((position) {
      if (!mounted || _isScrubbing) return;
      setState(() {
        _position = position;
      });
    });

    _durationSub = _player.stream.duration.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration;
      });
    });

    _playingSub = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
        if (playing) {
          _isBuffering = false;
        }
      });
    });

    _completedSub = _player.stream.completed.listen((completed) {
      if (!mounted || !completed) return;
      setState(() {
        _position = _duration;
        _isPlaying = false;
      });
    });
    _player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      setState(() {
        _isBuffering = buffering;
      });
    });

    unawaited(_open());
    unawaited(_loadArtworkGradient());
  }

  Future<void> _open() async {
    if (mounted) {
      setState(() {
        _isBuffering = true;
      });
    }

    print(widget.url);

    try {
      await _player.open(
        Media(widget.url, httpHeaders: widget.headers ?? const {}),
        play: true,
      );
      if (mounted) {
        setState(() {
          _hasOpenedMedia = true;
          _isBuffering = false;
        });
      }
      final startPosition = widget.startPosition;
      if (!_didInitialSeek &&
          startPosition != null &&
          startPosition > Duration.zero) {
        _didInitialSeek = true;
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await _player.seek(startPosition);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBuffering = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to play audio.')));
    }
  }

  Future<void> _finishAndPop() async {
    if (_didPopWithResult || !mounted) return;
    _didPopWithResult = true;
    Navigator.of(context).pop(_position);
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (!_hasOpenedMedia) {
          await _open();
          return;
        }
        await _player.play();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBuffering = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to control playback.')),
      );
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final target = _position + delta;
    final maxPosition = _duration > Duration.zero ? _duration : target;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > maxPosition ? maxPosition : target);
    await _player.seek(clamped);
    if (!mounted) return;
    setState(() {
      _position = clamped;
      _scrubSeconds = null;
      _isScrubbing = false;
    });
  }

  String get _remainingLabel {
    if (_duration <= Duration.zero) return '--:--';
    final remaining = _duration - _position;
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
    return '-${_formatDuration(safeRemaining)}';
  }

  Future<void> _seekToSeconds(double seconds) async {
    final clamped = seconds.clamp(0.0, _sliderMax);
    final target = Duration(milliseconds: (clamped * 1000).round());
    await _player.seek(target);
    if (!mounted) return;
    setState(() {
      _position = target;
      _scrubSeconds = null;
      _isScrubbing = false;
    });
  }

  double get _sliderMax {
    final seconds = _duration.inMilliseconds / 1000.0;
    return seconds <= 0 ? 1.0 : seconds;
  }

  double get _sliderValue {
    if (_scrubSeconds != null) {
      return _scrubSeconds!.clamp(0.0, _sliderMax);
    }
    final seconds = _position.inMilliseconds / 1000.0;
    return seconds.clamp(0.0, _sliderMax);
  }

  String _formatDuration(Duration value) {
    final totalSeconds = value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artistText = widget.artist?.trim() ?? '';
    final albumText = widget.album?.trim() ?? '';
    final detailParts = <String>[];
    if (_duration > Duration.zero) {
      detailParts.add(_formatDuration(_duration));
    }
    if (albumText.isNotEmpty) {
      detailParts.add(albumText);
    }
    final detailText = detailParts.join(' • ');

    return PopScope(
      canPop: !_didPopWithResult,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _didPopWithResult) return;
        unawaited(_finishAndPop());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Now Playing'),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _gradientT,
              builder: (context, child) {
                final t = _gradientT.value;
                final begin = Alignment.lerp(
                  Alignment.topLeft,
                  Alignment.topCenter,
                  t,
                )!;
                final end = Alignment.lerp(
                  Alignment.bottomRight,
                  Alignment.bottomLeft,
                  t,
                )!;
                final colors = _backgroundGradientColors;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: begin,
                      end: end,
                      colors: [
                        colors[0],
                        Color.lerp(colors[0], colors[1], 0.55)!,
                        colors[1],
                      ],
                      stops: const [0.0, 0.52, 1.0],
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(
                                    (0.28 * 255).toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(
                                      (0.10 * 255).toInt(),
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(
                                        (0.28 * 255).toInt(),
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(22),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 164,
                                            height: 164,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(
                                                    (0.30 * 255).toInt(),
                                                  ),
                                                  blurRadius: 28,
                                                  offset: const Offset(0, 16),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              child:
                                                  widget.artworkUrl != null &&
                                                      widget
                                                          .artworkUrl!
                                                          .isNotEmpty
                                                  ? Image.network(
                                                      widget.artworkUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return _ArtworkPlaceholder(
                                                              title:
                                                                  widget.title,
                                                            );
                                                          },
                                                    )
                                                  : _ArtworkPlaceholder(
                                                      title: widget.title,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    widget.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      height: 1.08,
                                                    ),
                                                  ),
                                                  if (artistText
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 14),
                                                    Text(
                                                      artistText,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 19,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ],
                                                  if (detailText
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      detailText,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white54,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 18),
                                                  Wrap(
                                                    spacing: 10,
                                                    runSpacing: 10,
                                                    children: [
                                                      _InfoChip(
                                                        icon: Icons
                                                            .music_note_rounded,
                                                        label:
                                                            _duration >
                                                                Duration.zero
                                                            ? _formatDuration(
                                                                _duration,
                                                              )
                                                            : 'Unknown length',
                                                      ),
                                                      _InfoChip(
                                                        icon:
                                                            Icons.album_rounded,
                                                        label:
                                                            albumText.isNotEmpty
                                                            ? albumText
                                                            : 'Single',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 5,
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white
                                              .withAlpha((0.18 * 255).toInt()),
                                          thumbColor: Colors.white,
                                          overlayColor: Colors.white.withAlpha(
                                            (0.12 * 255).toInt(),
                                          ),
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                enabledThumbRadius: 6,
                                              ),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                overlayRadius: 14,
                                              ),
                                        ),
                                        child: Slider(
                                          value: _sliderValue,
                                          max: _sliderMax,
                                          onChanged: (value) {
                                            setState(() {
                                              _isScrubbing = true;
                                              _scrubSeconds = value;
                                            });
                                          },
                                          onChangeEnd: _seekToSeconds,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(
                                                Duration(
                                                  milliseconds:
                                                      (_sliderValue * 1000)
                                                          .round(),
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _remainingLabel,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _ControlButton(
                                            icon: Icons.skip_previous_rounded,
                                            onPressed: null,
                                          ),
                                          const SizedBox(width: 10),
                                          _ControlButton(
                                            icon: Icons.replay_10_rounded,
                                            onPressed: () => _seekBy(
                                              const Duration(seconds: -10),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Container(
                                            width: 84,
                                            height: 84,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(
                                                (0.10 * 255).toInt(),
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withAlpha(
                                                    (0.20 * 255).toInt(),
                                                  ),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: _togglePlayback,
                                                  iconSize: 46,
                                                  color: Colors.white,
                                                  icon: Icon(
                                                    _isPlaying
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                              .play_arrow_rounded,
                                                  ),
                                                ),
                                                if (_isBuffering)
                                                  const SizedBox(
                                                    width: 84,
                                                    height: 84,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          _ControlButton(
                                            icon: Icons.forward_10_rounded,
                                            onPressed: () => _seekBy(
                                              const Duration(seconds: 10),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          _ControlButton(
                                            icon: Icons.skip_next_rounded,
                                            onPressed: null,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          _UtilityChip(
                                            icon: Icons.shuffle_rounded,
                                            label: 'Shuffle',
                                          ),
                                          SizedBox(width: 10),
                                          _UtilityChip(
                                            icon: Icons.repeat_rounded,
                                            label: 'Repeat',
                                          ),
                                          SizedBox(width: 10),
                                          _UtilityChip(
                                            icon: Icons.speed_rounded,
                                            label: '1.0×',
                                          ),
                                        ],
                                      ),
                                      if (_isBuffering) ...[
                                        const SizedBox(height: 18),
                                        const Text(
                                          'Buffering audio…',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final String title;

  const _ArtworkPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A2A), Color(0xFF111111)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.music_note_rounded,
                size: 72,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((enabled ? 0.08 : 0.04 * 255).toInt()),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: enabled ? Colors.white : Colors.white38,
        iconSize: 26,
      ),
    );
  }
}

class _UtilityChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _UtilityChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.06 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha((0.08 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.06 * 255).toInt()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withAlpha((0.08 * 255).toInt())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

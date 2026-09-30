import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - IN-APP MEDIA
///
/// Images open inside Ivory, pinch-zoomable and full screen.
/// Video and audio play inside Ivory with a gold player built on the
/// Flutter team's video_player (ExoPlayer on Android, which handles
/// mp3/m4a/aac as happily as mp4).
///
/// ASPECT RATIO POLICY
/// ASPECT RATIO POLICY
///   Ivory is portrait-first. 9:16 is the house shape: it is what the
///   player assumes before a file reports anything, and what a card
///   reserves while artwork loads.
///
///   A landscape file is never squeezed into it. The real ratio is read
///   from the decoder (or from the image itself) and the frame adjusts
///   to it, clamped between 9:16 and 16:9 so nothing can distort the
///   layout. Anything wider or taller than those bounds is letterboxed
///   onto a warm panel instead of being stretched.
/// ============================================================

/// The house shape: vertical.
const double kIvoryPortraitAspect = 9 / 16;

/// The widest a frame is allowed to get.
const double kIvoryWideAspect = 16 / 9;

/// Keeps any file inside the layout, however odd its dimensions.
double ivoryClampAspect(double? raw) {
  if (raw == null || raw.isNaN || raw <= 0.01) return kIvoryPortraitAspect;
  return raw.clamp(kIvoryPortraitAspect, kIvoryWideAspect);
}

// =====================================================================
// IMAGE
// =====================================================================
class IvoryImageView extends StatelessWidget {
  const IvoryImageView({super.key, required this.url, this.heroTag});

  final String url;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) {
        if (p == null) return child;
        final double? value = p.expectedTotalBytes == null
            ? null
            : p.cumulativeBytesLoaded / p.expectedTotalBytes!;
        return AspectRatio(
          aspectRatio: kIvoryPortraitAspect,
          child: Container(
            color: IvoryColors.surfaceWarm,
            child: Center(
              child: CircularProgressIndicator(
                value: value,
                color: IvoryColors.amber,
                strokeWidth: 2.4,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const _MediaError(
        message: 'This image could not be loaded.',
      ),
    );

    return GestureDetector(
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _FullScreenImage(url: url),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 560),
              color: IvoryColors.surfaceWarm,
              child: image,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.zoom_out_map_rounded,
                  size: 15, color: IvoryColors.textFaint),
              const SizedBox(width: 6),
              Text(
                'Tap to view full screen',
                style: TextStyle(fontSize: 12.5, color: IvoryColors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IvoryColors.burgundy,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const _MediaError(
                      message: 'This image could not be loaded.',
                      onDark: true,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: IvoryColors.ivory,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.close_rounded,
                        color: IvoryColors.burgundy, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// VIDEO + AUDIO
// =====================================================================
class IvoryPlayer extends StatefulWidget {
  const IvoryPlayer({
    super.key,
    required this.url,
    this.audioOnly = false,
    this.posterUrl,
  });

  final String url;
  final bool audioOnly;
  final String? posterUrl;

  @override
  State<IvoryPlayer> createState() => _IvoryPlayerState();
}

class _IvoryPlayerState extends State<IvoryPlayer> {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _failed = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final VideoPlayerController c =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c = c;
    try {
      await c.initialize();
      c.addListener(_tick);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final int h = d.inHours;
    final String m = (d.inMinutes % 60).toString().padLeft(h > 0 ? 2 : 1, '0');
    final String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _toggle() {
    final VideoPlayerController? c = _c;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _MediaError(
        message: widget.audioOnly
            ? 'This audio could not be played.'
            : 'This video could not be played.',
      );
    }

    final VideoPlayerController? c = _c;
    if (!_ready || c == null) {
      return AspectRatio(
        aspectRatio: widget.audioOnly ? 4.2 : kIvoryPortraitAspect,
        child: Container(
          decoration: BoxDecoration(
            gradient: IvoryColors.warmGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: IvoryColors.burgundy, strokeWidth: 2.4),
          ),
        ),
      );
    }

    final VideoPlayerValue v = c.value;
    final Duration total = v.duration;
    final Duration pos = v.position;
    // The file's own ratio wins; 9:16 only when it reports nothing.
    // Clamped so an extreme file letterboxes rather than breaks the page.
    final double ratio = ivoryClampAspect(v.aspectRatio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!widget.audioOnly)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GestureDetector(
              onTap: _toggle,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: ratio,
                    child: Container(
                      color: IvoryColors.surfaceWarm,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: v.size.width <= 0 ? 9 : v.size.width,
                          height: v.size.height <= 0 ? 16 : v.size.height,
                          child: VideoPlayer(c),
                        ),
                      ),
                    ),
                  ),
                  if (!v.isPlaying)
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: IvoryColors.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: IvoryTheme.softShadow(blur: 18, y: 6),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: IvoryColors.burgundy, size: 38),
                    ),
                ],
              ),
            ),
          ),
        if (widget.audioOnly) _AudioFace(playing: v.isPlaying),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            _RoundButton(
              icon: v.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onTap: _toggle,
              big: widget.audioOnly,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: IvoryColors.gold,
                  inactiveTrackColor: IvoryColors.hairlineStrong,
                  thumbColor: IvoryColors.burgundy,
                  overlayColor: IvoryColors.amber.withValues(alpha: 0.18),
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: pos.inMilliseconds
                      .clamp(0, total.inMilliseconds == 0
                          ? 1
                          : total.inMilliseconds)
                      .toDouble(),
                  max: total.inMilliseconds == 0
                      ? 1
                      : total.inMilliseconds.toDouble(),
                  onChanged: (double ms) =>
                      c.seekTo(Duration(milliseconds: ms.round())),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${_fmt(pos)} / ${_fmt(total)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: IvoryColors.plum,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() {
                  _muted = !_muted;
                  c.setVolume(_muted ? 0 : 1);
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: 20,
                  color: IvoryColors.textSoft,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The face of the audio player: a warm band with a pulsing bar motif,
/// so a voice note still feels like something, not an empty rectangle.
class _AudioFace extends StatelessWidget {
  const _AudioFace({required this.playing});

  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: IvoryColors.warmGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IvoryColors.gold, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List<Widget>.generate(21, (int i) {
          final double h = 14 + ((i * 37) % 47).toDouble() * (playing ? 1 : .5);
          return Container(
            width: 4,
            height: h,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: IvoryColors.burgundy.withValues(alpha: playing ? .7 : .35),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.big = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final double size = big ? 52 : 42;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: IvoryColors.goldGradient,
          shape: BoxShape.circle,
          boxShadow: IvoryTheme.softShadow(blur: 12, y: 4),
        ),
        child: Icon(icon, color: IvoryColors.burgundy, size: big ? 30 : 24),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.message, this.onDark = false});

  final String message;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: onDark
            ? IvoryColors.burgundy
            : IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            color: onDark ? IvoryColors.gold : IvoryColors.plum,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: onDark ? IvoryColors.ivory : IvoryColors.textSoft,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/ivory_media_view.dart

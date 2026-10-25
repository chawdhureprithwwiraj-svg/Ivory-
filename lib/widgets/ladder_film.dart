import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'premium_assets.dart';

/// ============================================================
/// IVORY - THE LADDER FILM
///
/// A short cinematic film of a young woman climbing a weathered
/// wooden ladder on an old haveli wall at golden hour. The camera
/// circles from behind her, round to her side, then pulls back over
/// the city and the setting sun. It plays on a loop, silent, at the
/// top of the Ivory Ladder page.
///
/// The film is the owner's file `ladder_film.mp4` in
/// `assets/premium/`. If it is not there, or the phone cannot play
/// it, this draws nothing at all and the page looks as it did
/// before. Nothing here can throw. Tap the film to pause or play.
/// It also pauses when the app goes to the background.
/// ============================================================
class LadderFilm extends StatefulWidget {
  const LadderFilm({super.key});

  @override
  State<LadderFilm> createState() => _LadderFilmState();
}

class _LadderFilmState extends State<LadderFilm> with WidgetsBindingObserver {
  VideoPlayerController? _c;
  bool _ready = false;
  bool _failed = false;
  bool _userPaused = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _start() async {
    try {
      final String? path = await PremiumAssets.find(
        'ladder_film',
        const <String>['ladder', 'film'],
        const <String>['.mp4'],
      );
      if (path == null || _disposed) {
        if (mounted && !_disposed) setState(() => _failed = true);
        return;
      }
      final VideoPlayerController c = VideoPlayerController.asset(
        path,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _c = c;
      await c.initialize();
      if (_disposed) {
        await c.dispose();
        return;
      }
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted && !_disposed) setState(() => _failed = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final VideoPlayerController? c = _c;
    if (c == null || !_ready) return;
    try {
      if (state == AppLifecycleState.resumed) {
        if (!_userPaused) c.play();
      } else {
        c.pause();
      }
    } catch (_) {}
  }

  void _toggle() {
    final VideoPlayerController? c = _c;
    if (c == null || !_ready) return;
    try {
      if (c.value.isPlaying) {
        c.pause();
        _userPaused = true;
      } else {
        c.play();
        _userPaused = false;
      }
      setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    try {
      _c?.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      // CC.215: even a film that cannot play keeps its seat. Collapsing
      // to nothing mid-scroll was one of the ladder's jumps; this golden
      // frame holds the same 16:9 space on every device, forever.
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFFFE2B0), Color(0xFFE8A86A)],
                ),
              ),
              child: Center(
                child: Text(
                  'The ladder film rests on this device.',
                  style: TextStyle(
                    color: const Color(0xFF8F5B00).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final VideoPlayerController? c = _c;
    final bool playing = _ready && c != null && c.value.isPlaying;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFFFC85A).withValues(alpha: 0.22),
                blurRadius: 26,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFFFE2B0), Color(0xFFE8A86A)],
                      ),
                    ),
                  ),
                  if (_ready && c != null)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: c.value.size.width,
                        height: c.value.size.height,
                        child: VideoPlayer(c),
                      ),
                    )
                  else
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF8F5B00),
                        ),
                      ),
                    ),
                  // A soft golden edge, like the glow around a cinema screen.
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFFE9B0).withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  if (_ready && !playing)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 58,
                        color: Color(0xCCFFF7E0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/ladder_film.dart

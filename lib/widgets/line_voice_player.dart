import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/line_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - IVORY'S VOICE REPLY
///
/// A small player for a voice note in the private store. The link is
/// fetched only when the member taps play (it lasts an hour), then the
/// note plays through the same player the app already uses for
/// stories. If it cannot be fetched, it says so kindly.
/// ============================================================
class LineVoicePlayer extends StatefulWidget {
  const LineVoicePlayer({super.key, required this.path});

  final String path;

  @override
  State<LineVoicePlayer> createState() => _LineVoicePlayerState();
}

class _LineVoicePlayerState extends State<LineVoicePlayer> {
  VideoPlayerController? _c;
  bool _loading = false;
  String? _problem;

  @override
  void dispose() {
    _c?.removeListener(_tick);
    _c?.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    final VideoPlayerController? c = _c;
    if (c != null &&
        c.value.isInitialized &&
        c.value.position >= c.value.duration &&
        c.value.isPlaying) {
      c.pause();
    }
    setState(() {});
  }

  Future<void> _toggle() async {
    final VideoPlayerController? c = _c;
    if (c != null && c.value.isInitialized) {
      if (c.value.isPlaying) {
        await c.pause();
      } else {
        if (c.value.position >= c.value.duration) {
          await c.seekTo(Duration.zero);
        }
        await c.play();
      }
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
      _problem = null;
    });
    final String? url = await LineService.instance.voiceUrl(widget.path);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _loading = false;
        _problem = 'The voice note could not be fetched. Please try again.';
      });
      return;
    }
    try {
      final VideoPlayerController n =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await n.initialize();
      if (!mounted) {
        await n.dispose();
        return;
      }
      n.addListener(_tick);
      _c = n;
      setState(() => _loading = false);
      await n.play();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _problem = 'The voice note could not be played. Please try again.';
      });
    }
  }

  String _clock(Duration d) {
    final int s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? c = _c;
    final bool ready = c != null && c.value.isInitialized;
    final bool playing = ready && c.value.isPlaying;
    final double total =
        ready ? c.value.duration.inMilliseconds.toDouble() : 1;
    final double at = ready
        ? c.value.position.inMilliseconds.clamp(0, total.toInt()).toDouble()
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: IvoryColors.emeraldWash,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: IvoryColors.emerald,
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: IvoryColors.emerald,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Ivory\u2019s voice',
                    style: TextStyle(
                      color: IvoryColors.emeraldWash,
                      fontFamily: IvoryTheme.displayFont,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: ready ? (at / total).clamp(0.0, 1.0) : 0,
                      color: IvoryColors.emeraldWash,
                      backgroundColor:
                          IvoryColors.emeraldWash.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ready
                  ? '${_clock(c.value.position)} / ${_clock(c.value.duration)}'
                  : 'Tap to listen',
              style: TextStyle(
                color: IvoryColors.emeraldWash.withValues(alpha: 0.8),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (_problem != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _problem!,
            style: const TextStyle(
              color: IvoryColors.emeraldWash,
              fontSize: 12.5,
            ),
          ),
        ],
      ],
    );
  }
}

// END OF FILE - lib/widgets/line_voice_player.dart

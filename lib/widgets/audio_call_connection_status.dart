import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/audio_call_beat_meter.dart';
import '../theme/ivory_theme.dart';

/// A single, high-contrast call state at the top of the identity stage.
/// The supplied looping GIF stays visible for the whole connected call;
/// the jewel-toned waveform lifts when either microphone detects speech.
class AudioCallConnectionStatus extends StatefulWidget {
  const AudioCallConnectionStatus({
    super.key,
    required this.connected,
    required this.waitingText,
  });

  final bool connected;
  final String waitingText;

  @override
  State<AudioCallConnectionStatus> createState() =>
      _AudioCallConnectionStatusState();
}

class _AudioCallConnectionStatusState
    extends State<AudioCallConnectionStatus>
    with SingleTickerProviderStateMixin {
  static const String _beatAsset =
      'assets/premium/ivory_audio_call_music_beat.gif';
  static const int _barCount = 9;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant AudioCallConnectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connected != widget.connected) _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.of(context).disableAnimations) {
      if (_motion.isAnimating) _motion.stop();
      _motion.value = 0;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double width =
        math.min(286.0, MediaQuery.sizeOf(context).width - 44).toDouble();
    final bool motionOff = MediaQuery.of(context).disableAnimations;

    return ValueListenableBuilder<AudioCallBeatLevels>(
      valueListenable: AudioCallBeatMeter.instance.levels,
      builder: (BuildContext context, AudioCallBeatLevels levels, Widget? _) {
        return AnimatedBuilder(
          animation: _motion,
          builder: (BuildContext context, Widget? _) {
            final double phase = motionOff ? 0 : _motion.value;
            return Semantics(
              label: widget.connected
                  ? 'Audio call connected'
                  : widget.waitingText,
              child: _frame(
                width: width,
                phase: phase,
                voice: widget.connected ? levels.peak : 0,
              ),
            );
          },
        );
      },
    );
  }

  Widget _frame({
    required double width,
    required double phase,
    required double voice,
  }) {
    final BorderRadius radius = BorderRadius.circular(23);
    final double glow = widget.connected ? 0.2 + voice * 0.42 : 0.16;
    return Container(
      width: width,
      padding: const EdgeInsets.all(1.7),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: widget.connected
            ? SweepGradient(
                colors: const <Color>[
                  IvoryColors.gold,
                  Color(0xFFB756FF),
                  Color(0xFFFF4FA2),
                  Color(0xFF5CE8DF),
                  IvoryColors.gold,
                ],
                transform: GradientRotation(phase * math.pi * 2),
              )
            : const LinearGradient(
                colors: <Color>[
                  IvoryColors.gold,
                  Color(0xFF8D6330),
                  Color(0xFFE9C979),
                ],
              ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (widget.connected
                    ? const Color(0xFFB756FF)
                    : IvoryColors.gold)
                .withValues(alpha: glow),
            blurRadius: widget.connected ? 22 + voice * 14 : 16,
            spreadRadius: 0.4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: widget.connected
            ? _connected(width - 3.4, voice)
            : _waiting(width - 3.4, phase),
      ),
    );
  }

  Widget _waiting(double width, double phase) => Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 78),
        color: const Color(0xFF10070C),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 42,
              height: 42,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: IvoryColors.gold.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: phase * math.pi * 2,
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: IvoryColors.gold,
                      size: 22,
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: IvoryColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: IvoryColors.gold.withValues(alpha: 0.75),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.waitingText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: IvoryColors.ivory,
                  fontSize: 16,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _waitingDots(phase),
          ],
        ),
      );

  Widget _waitingDots(double phase) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(3, (int index) {
          final double lift =
              (math.sin(phase * math.pi * 2 + index * 1.05) + 1) / 2;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 5,
              height: 5 + lift * 4,
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFF9A6C2E),
                  IvoryColors.gold,
                  lift,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          );
        }),
      );

  Widget _connected(double width, double voice) {
    final double height = width * 0.56;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            _beatAsset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
                const ColoredBox(
              color: Color(0xFF08030C),
              child: Center(
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: IvoryColors.gold,
                  size: 44,
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xC9000000),
                  Color(0x28000000),
                  Color(0xC9000000),
                ],
                stops: <double>[0, 0.52, 1],
              ),
            ),
          ),
          Positioned(
            top: 11,
            left: 13,
            right: 13,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Connected',
                  style: TextStyle(
                    color: IvoryColors.ivory,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    shadows: <Shadow>[
                      Shadow(color: Color(0xCC000000), blurRadius: 8),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xB20A0710),
                    border: Border.all(
                      color: const Color(0xFFFF78CE).withValues(alpha: 0.65),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.circle, color: Color(0xFFFF78CE), size: 7),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: IvoryColors.ivory,
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(child: _wave(voice)),
          ),
        ],
      ),
    );
  }

  Widget _wave(double voice) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(_barCount, (int index) {
          final double sway =
              (math.sin(_motion.value * math.pi * 8 + index * 0.72).abs());
          final double idle = 0.12 + sway * 0.12;
          final double speech = voice < 0.035
              ? idle
              : voice * (0.58 + sway * 0.42);
          final double height = 5 + speech * 27;
          final Color color = index.isEven
              ? IvoryColors.gold
              : const Color(0xFFDA93FF);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: color.withValues(alpha: 0.68),
                    blurRadius: 7 + voice * 5,
                  ),
                ],
              ),
            ),
          );
        }),
      );
}

// END OF FILE - lib/widgets/audio_call_connection_status.dart

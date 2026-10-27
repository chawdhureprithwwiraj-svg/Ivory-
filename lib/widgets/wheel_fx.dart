import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// The Wheel of Fans — atmosphere and sound.
///
/// Gold dust that falls and twinkles, confetti that bursts, coins that
/// fly home to the purse, the dust ring that blooms where the wheel
/// lands, and the seven house sounds of the wheel. The sounds ride the
/// same bench as the house sound bank: video_player on wav assets, so no
/// new package ever enters the build. Every recording carries its own
/// lingering tail; nothing ends on a beep.
class WofSound {
  static const List<String> names = <String>[
    'descent', 'spin', 'win', 'coin', 'rest', 'salon', 'petal'
  ];
  static final Map<String, VideoPlayerController> _c =
      <String, VideoPlayerController>{};
  static final Set<String> _failed = <String>{};
  static bool _loading = false;

  /// Open the players two at a time, like the house sound bank, so the
  /// first tap of the ceremony is instant.
  static Future<void> preload() async {
    if (_loading) return;
    _loading = true;
    for (int i = 0; i < names.length; i += 2) {
      await Future.wait(<Future<void>>[
        _open(names[i]),
        if (i + 1 < names.length) _open(names[i + 1]),
      ]);
    }
    _loading = false;
  }

  static Future<void> _open(String n) async {
    if (_c[n] != null) return;
    const List<String> homes = <String>[
      'assets/wheels/sounds/wof_',
      'assets/wheels/wof_',
    ];
    for (final String home in homes) {
      final VideoPlayerController c =
          VideoPlayerController.asset('$home$n.wav');
      try {
        await c.initialize();
        c.setVolume(0.85);
        _c[n] = c;
        return;
      } catch (e) {
        await c.dispose();
      }
    }
    _failed.add(n);
  }

  /// Play from the top; the recording's own tail does the fading.
  static void play(String n) {
    if (_failed.contains(n)) return;
    final VideoPlayerController? c = _c[n];
    if (c == null || !c.value.isInitialized) {
      _open(n).then((_) => play(n));
      return;
    }
    c.seekTo(Duration.zero).then((_) => c.play());
  }

  static void stopAll() {
    for (final VideoPlayerController c in _c.values) {
      c.pause();
    }
  }
}

/// Falling, twinkling gold dust — the house sprinkles it wherever the
/// wheel rests its eye: around the medallion, behind the ceremony.
class GoldDust extends StatefulWidget {
  const GoldDust({super.key, this.count = 26, this.color = const Color(0xFFE7B14C)});
  final int count;
  final Color color;

  @override
  State<GoldDust> createState() => _GoldDustState();
}

class _GoldDustState extends State<GoldDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(seconds: 9))..repeat();
  late final List<List<double>> _p = List<List<double>>.generate(
      widget.count,
      (int i) => <double>[
            math.Random(i + 7).nextDouble(),
            math.Random(i + 31).nextDouble(),
            0.4 + math.Random(i + 91).nextDouble() * 0.9,
            math.Random(i + 53).nextDouble(),
          ]);

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _t,
        builder: (BuildContext context, Widget? _) => CustomPaint(
          painter: _DustPainter(_p, _t.value, widget.color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  _DustPainter(this.p, this.t, this.color);
  final List<List<double>> p;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final List<double> q in p) {
      final double y = ((q[1] + t * q[2]) % 1.0) * size.height;
      final double x = (q[0] + 0.02 * math.sin(6.28 * (t * 2 + q[3]))) *
          size.width;
      final double tw = 0.35 + 0.65 * math.pow(
          math.sin(6.28 * (t * 3 + q[3])) * 0.5 + 0.5, 2).toDouble();
      final double r = 1.1 + q[3] * 1.9;
      final Paint pt = Paint()
        ..color = color.withOpacity(0.28 * tw + 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(x, y), r, pt);
    }
  }

  @override
  bool shouldRepaint(_DustPainter o) => o.t != t;
}

/// A festival burst when the feather lands on a gift — and the living
/// bridge when the film folds into light: [t] is 0..1 of the moment,
/// driven by a controller so the burst MOVES (it once stood frozen).
class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({super.key, required this.t, this.seed = 3});
  final double t; // 0..1 progress
  final int seed;

  static const List<Color> hues = <Color>[
    Color(0xFFFFB300), Color(0xFFFF7A00), Color(0xFF00C853),
    Color(0xFFD50000), Color(0xFFFF4081), Color(0xFFE7B14C),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfPainter(t, seed),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfPainter extends CustomPainter {
  _ConfPainter(this.t, this.seed);
  final double t;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final Offset c = Offset(size.width / 2, size.height * 0.42);
    final math.Random rnd = math.Random(seed);
    final double fade = t < 0.75 ? 1.0 : (1 - t) / 0.25;
    for (int i = 0; i < 64; i++) {
      final double a = rnd.nextDouble() * 6.283;
      final double sp = 90 + rnd.nextDouble() * 300;
      final double x = c.dx + math.cos(a) * sp * t;
      final double y = c.dy + math.sin(a) * sp * t + 240 * t * t;
      final double w = 3 + rnd.nextDouble() * 5;
      final Paint p = Paint()
        ..color = ConfettiBurst.hues[i % 6].withOpacity(0.9 * fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(a + t * 7);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.6), p);
      canvas.restore();
    }
    // a gold heart of light opening at the centre of the burst
    final Paint heart = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFF3C9).withOpacity(0.55 * fade),
          const Color(0xFFE7B14C).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: 40 + 190 * t));
    canvas.drawCircle(c, 40 + 190 * t, heart);
  }

  @override
  bool shouldRepaint(_ConfPainter o) => o.t != t;
}

/// The dust ring that blooms where the wheel lands: a gold shockwave
/// with fourteen motes thrown out and falling back. [t] is 0..1 of the
/// settle, so the ring opens exactly as the wheel squashes on its velvet.
class DustRing extends StatelessWidget {
  const DustRing({super.key, required this.t});
  final double t; // 0..1 of the settle

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _RingPainter(t), size: Size.infinite),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2;
    final double e = 1 - math.pow(1 - t, 3).toDouble();
    final double fade = 1 - t;
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 + 3 * fade
      ..color = const Color(0xFFE7B14C).withOpacity(0.45 * fade);
    canvas.drawCircle(c, r * (0.62 + 0.72 * e), ring);
    final math.Random rnd = math.Random(4);
    for (int i = 0; i < 14; i++) {
      final double a = rnd.nextDouble() * 6.283;
      final double sp = r * (0.5 + rnd.nextDouble() * 0.7);
      final Offset m = c +
          Offset(math.cos(a) * sp * e,
              math.sin(a) * sp * e * 0.55 + 60 * t * t);
      final Paint p = Paint()
        ..color = const Color(0xFFFFE9B8).withOpacity(0.7 * fade);
      canvas.drawCircle(m, 1.4 + rnd.nextDouble() * 2.2, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.t != t;
}

/// Five gold coins arcing from the wheel's hub to the purse corner —
/// real weight, real spin, a soft glint on each face.
class CoinFlight extends StatelessWidget {
  const CoinFlight({super.key, required this.t});
  final double t; // 0..1

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _CoinPainter(t), size: Size.infinite),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final Offset from = Offset(size.width / 2, size.height * 0.42);
    final Offset to = Offset(size.width - 46, 74);
    for (int i = 0; i < 5; i++) {
      final double lt = (t - i * 0.06).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final double e = 1 - math.pow(1 - lt, 3).toDouble();
      final Offset mid = Offset((from.dx + to.dx) / 2, from.dy - 130 - i * 18);
      final double x = (1 - e) * (1 - e) * from.dx +
          2 * (1 - e) * e * mid.dx + e * e * to.dx;
      final double y = (1 - e) * (1 - e) * from.dy +
          2 * (1 - e) * e * mid.dy + e * e * to.dy;
      final double sq = math.cos(e * 9 + i).abs() * 0.8 + 0.2;
      final Paint coin = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF6D98A), Color(0xFFE7B14C), Color(0xFF8A5E1C)],
        ).createShader(Rect.fromCenter(center: Offset(x, y), width: 22, height: 22));
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(sq, 1);
      canvas.drawCircle(Offset.zero, 11, coin);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CoinPainter o) => o.t != t;
}

// END OF FILE - lib/widgets/wheel_fx.dart

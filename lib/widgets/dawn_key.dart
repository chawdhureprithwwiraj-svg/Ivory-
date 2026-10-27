import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE DAWN DOOR ART KIT (CC.229)
/// The dawn sky, the member's brass key with their rank, the rank chip,
/// the keyhole teaser, the premium band, the First Screening's verdict
/// desk, the Seer chip and the forever members' glimpse of the room.
/// ============================================================

/// The dawn sky: indigo to rose-gold with a breathing seam of light.
class DawnSky extends StatefulWidget {
  const DawnSky({super.key, this.seam = 0.5});
  final double seam; // 0..1 height of the door-seam light

  @override
  State<DawnSky> createState() => _DawnSkyState();
}

class _DawnSkyState extends State<DawnSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
      vsync: this, duration: const Duration(seconds: 9))
    ..repeat();

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (BuildContext c, Widget? _) => CustomPaint(
        painter: _DawnPainter(t: _t.value, seam: widget.seam),
      ),
    );
  }
}

class _DawnPainter extends CustomPainter {
  _DawnPainter({required this.t, required this.seam});
  final double t;
  final double seam;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    final Paint bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF191036), Color(0xFF3A1650), Color(0xFF7A2A4A), Color(0xFFC4633F)],
        stops: <double>[0, 0.45, 0.78, 1],
      ).createShader(full);
    canvas.drawRect(full, bg);

    // the seam of light: a horizontal glow that breathes
    final double y = size.height * seam;
    final double breath = 0.55 + 0.45 * math.sin(t * 6.283);
    final Paint seamP = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          const Color(0xFFFFD98A).withOpacity(0),
          const Color(0xFFFFD98A).withOpacity(0.10 + 0.22 * breath),
          const Color(0xFFFFF3C4).withOpacity(0.16 + 0.30 * breath),
          const Color(0xFFFFD98A).withOpacity(0.10 + 0.22 * breath),
          const Color(0xFFFFD98A).withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 26, size.width, 52));
    canvas.drawRect(Rect.fromLTWH(0, y - 26, size.width, 52), seamP);

    // drifting motes, rising slowly
    for (int i = 0; i < 18; i++) {
      final double seed = i * 0.61803398875;
      final double x = ((seed * 823) % 1) * size.width;
      final double sp = 0.04 + ((seed * 37) % 1) * 0.07;
      final double yy = size.height * (1 - ((t * sp + seed) % 1));
      final double tw = 0.5 + 0.5 * math.sin(t * 6.283 * 1.4 + i * 2.2);
      final Paint p = Paint()
        ..color = (i % 3 == 0 ? const Color(0xFFFFE9A8) : const Color(0xFFFFB3C4))
            .withOpacity(0.08 + 0.26 * tw);
      canvas.drawCircle(
          Offset(x + math.sin(t * 4 + i) * 10, yy), 0.9 + 1.4 * tw, p);
    }
  }

  @override
  bool shouldRepaint(_DawnPainter old) => old.t != t;
}

/// The member's brass key, engraved with their Dawn Circle rank.
class BrassKey extends StatelessWidget {
  const BrassKey({super.key, this.rank = '', this.glow = false, this.size = 64});
  final String rank;
  final bool glow;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow
            ? const <BoxShadow>[
                BoxShadow(color: Color(0xAAFFD98A), blurRadius: 22, spreadRadius: 2),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _KeyPainter(rank: rank),
      ),
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter({required this.rank});
  final String rank;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.shortestSide / 2;
    final Offset c = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.6);
    final Paint brass = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF6D98A), Color(0xFFB9822B), Color(0xFF8A5E1C)],
      ).createShader(Rect.fromLTWH(-r, -r, r * 2, r * 2));
    // bow: a ring
    canvas.drawCircle(Offset(-r * 0.42, 0), r * 0.30,
        Paint()..style = PaintingStyle.stroke..strokeWidth = r * 0.13..shader = brass.shader);
    // shaft
    canvas.drawRect(
        Rect.fromLTWH(-r * 0.16, -r * 0.07, r * 0.92, r * 0.14), brass);
    // teeth
    canvas.drawRect(Rect.fromLTWH(r * 0.42, r * 0.07, r * 0.10, r * 0.22), brass);
    canvas.drawRect(Rect.fromLTWH(r * 0.62, r * 0.07, r * 0.10, r * 0.30), brass);
    canvas.restore();
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: rank,
        style: TextStyle(
          color: const Color(0xFFFFF3C4),
          fontSize: r * 0.24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          shadows: const <Shadow>[Shadow(color: Color(0xAA191036), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, size.height - tp.height - 2));
  }

  @override
  bool shouldRepaint(_KeyPainter old) => old.rank != rank;
}

/// The rank chip: a small brass-bordered pill for card and profile.
class DawnRankChip extends StatelessWidget {
  const DawnRankChip({super.key, required this.rank, this.streak = 0});
  final String rank;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7B14C), width: 1.2),
        gradient: const LinearGradient(
          colors: <Color>[Color(0x33FFD98A), Color(0x11FFD98A)],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.key, size: 13, color: Color(0xFFFFD98A)),
          const SizedBox(width: 6),
          Text(rank,
              style: const TextStyle(
                  color: Color(0xFFFFF3C4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1)),
          if (streak > 0) ...<Widget>[
            const SizedBox(width: 8),
            Text('$streak dawn${streak == 1 ? '' : 's'}',
                style: const TextStyle(
                    color: Color(0xCCFFE9A8), fontSize: 10.5)),
          ],
        ],
      ),
    );
  }
}

/// The keyhole teaser: forty words, and the rest kept for the hour.
class KeyholeTeaser extends StatelessWidget {
  const KeyholeTeaser({super.key, required this.teaser});
  final String teaser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF0FFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB9822B), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.circle, size: 10, color: Color(0xFF4A0E17)),
              SizedBox(width: 8),
              Text('THROUGH THE KEYHOLE',
                  style: TextStyle(
                      color: Color(0xFF8A5E1C),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6)),
            ],
          ),
          const SizedBox(height: 6),
          Text(teaser,
              style: const TextStyle(
                  color: Color(0xFF3A2318),
                  fontSize: 13.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          const Text('…the door keeps the rest for its hour.',
              style: TextStyle(color: Color(0x807A5216), fontSize: 11)),
        ],
      ),
    );
  }
}

/// The quiet band that turns devotion into the premium ladder.
class PremiumDawnBand extends StatelessWidget {
  const PremiumDawnBand({
    super.key,
    required this.discount,
    required this.cap,
    required this.streak,
    this.onTap,
  });
  final int discount;
  final int cap;
  final int streak;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF3E1570), Color(0xFF6A25B0)],
          ),
          border: Border.all(color: const Color(0x66FFE9A8), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('THE DOOR OPENS FULLY FOR PREMIUM',
                style: TextStyle(
                    color: Color(0xFFFFE9A8),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8)),
            const SizedBox(height: 7),
            Text(
              'Every story, the whole early period, the moment it is shared. '
              'And your dawns count: each streak dawn takes ₹${_per()} off your '
              'first premium month, to ₹$cap. This streak: ₹$discount.',
              style: const TextStyle(
                  color: Color(0xF0F3E6FF), fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFFFD98A)),
                const SizedBox(width: 8),
                Text(streak > 0 ? 'carry your $streak dawn${streak == 1 ? '' : 's'} to the tiers' : 'see the membership tiers',
                    style: const TextStyle(
                        color: Color(0xFFFFD98A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _per() => streak > 0 ? discount ~/ streak : 7;
}

/// The First Screening's desk: verdict, note, call, submit.
class VerdictDesk extends StatefulWidget {
  const VerdictDesk({
    super.key,
    required this.onSubmit,
    this.verdict = 'release',
    this.hype = 'super',
    this.note = '',
    this.busy = false,
  });
  final Future<void> Function(String verdict, String note, String hype) onSubmit;
  final String verdict;
  final String hype;
  final String note;
  final bool busy;

  @override
  State<VerdictDesk> createState() => _VerdictDeskState();
}

class _VerdictDeskState extends State<VerdictDesk> {
  late String _v = widget.verdict;
  late String _h = widget.hype;
  late final TextEditingController _n =
      TextEditingController(text: widget.note);

  @override
  void dispose() {
    _n.dispose();
    super.dispose();
  }

  Widget _pill(String label, String value, String group, Color on) {
    final bool sel = group == 'v' ? _v == value : _h == value;
    return GestureDetector(
      onTap: widget.busy
          ? null
          : () => setState(() {
                if (group == 'v') {
                  _v = value;
                } else {
                  _h = value;
                }
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: sel ? on : const Color(0x22FFE9A8),
          border: Border.all(
              color: sel ? on : const Color(0x88FFE9A8), width: 1.1),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? const Color(0xFF2A1033) : const Color(0xFFFFE9A8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x26191036),
        border: Border.all(color: const Color(0x66FFE9A8), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('THE VERDICT',
              style: TextStyle(
                  color: Color(0xFFFFE9A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill('RELEASE IT', 'release', 'v', const Color(0xFF7ED99A)),
              _pill('HOLD FOR NOTES', 'notes', 'v', const Color(0xFFFFB300)),
            ],
          ),
          if (_v == 'notes') ...<Widget>[
            const SizedBox(height: 10),
            TextField(
              controller: _n,
              maxLength: 750,
              maxLines: 4,
              style: const TextStyle(color: Color(0xFFFFF6E5), fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'what would you move in the cut? Ivory reads '
                    'every line.',
                hintStyle: TextStyle(color: Color(0x80FFE9A8)),
                counterStyle: TextStyle(color: Color(0x66FFE9A8), fontSize: 10),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Text('THE CALL',
              style: TextStyle(
                  color: Color(0xFFFFE9A8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill('SUPER HIT', 'super', 'h', const Color(0xFFFF6FA5)),
              _pill('SLOW BURN', 'slow', 'h', const Color(0xFFFF9A1F)),
              _pill('SLEEPER', 'sleeper', 'h', const Color(0xFF9A55E6)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: widget.busy
                ? null
                : () => widget.onSubmit(_v, _n.text.trim(), _h),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF0C060), Color(0xFFC98A2E)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8A5E1C)),
              ),
              alignment: Alignment.center,
              child: const Text('SEAL MY VERDICT',
                  style: TextStyle(
                      color: Color(0xFF3E1570),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Seer chip: how many calls, how many true.
class SeerChip extends StatelessWidget {
  const SeerChip({super.key, required this.calls, required this.seer, required this.taken});
  final int calls;
  final int seer;
  final int taken;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x88FF6FA5), width: 1.1),
      ),
      child: Text(
        taken > 0
            ? '$seer of $calls calls true · $taken note${taken == 1 ? '' : 's'} moved the cut'
            : '$seer of $calls calls true',
        style: const TextStyle(
            color: Color(0xFFFFB3C6), fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The forever members' glimpse of the room: seats, never a vote.
class ScreeningTease extends StatelessWidget {
  const ScreeningTease({super.key, required this.seats, required this.superCount});
  final int seats;
  final int superCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
            colors: <Color>[Color(0x339A55E6), Color(0x119A55E6)]),
        border: Border.all(color: const Color(0x669A55E6), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('THE FIRST SCREENING',
              style: TextStyle(
                  color: Color(0xFFE3C7FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text(
            seats > 0
                ? '${seats} seat${seats == 1 ? '' : 's'} taken tonight'
                    '${superCount > 0 ? ' · the jury is calling it a SUPER HIT ×$superCount' : ''}. '
                    'Premium reads the cut before the world, votes the '
                    'verdict, and its notes reach Ivory\'s own desk.'
                : 'Tonight the premium jury sits in judgement on the held '
                    'cut - verdicts, predictions, and notes that reach '
                    'Ivory\'s own desk. The door to the room is a tier.',
            style: const TextStyle(
                color: Color(0xD9F3E6FF), fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/dawn_key.dart

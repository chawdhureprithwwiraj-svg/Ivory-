import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/wheel_service.dart';
import 'wheel_fx.dart';
import 'wheel_painter.dart';
import 'wheel_salon.dart';

/// The Wheel of Fans room.
///
/// Inside the Gilded Hours, opened for the first time that window: the
/// owner's film plays with its own sound — tap skips, the house never
/// gates — then a burst of gold, the descent sound, and the wheel falls
/// from the top of the sky onto its velvet. At rest the wheel never
/// sits: it turns slowly and regally under the living sky, names and
/// rupees riding round like a court jewel. Outside the hours the room
/// is the salon instead.
class WheelRoom extends StatefulWidget {
  const WheelRoom({super.key, this.ceremony = false});
  final bool ceremony;

  static Route<void> route({bool ceremony = false}) {
    return PageRouteBuilder<void>(
      opaque: false,
      transitionsBuilder: (BuildContext c, Animation<double> a,
              Animation<double> b, Widget ch) =>
          FadeTransition(opacity: a, child: ch),
      pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) =>
          WheelRoom(ceremony: ceremony),
    );
  }

  @override
  State<WheelRoom> createState() => _WheelRoomState();
}

class _WheelRoomState extends State<WheelRoom> with TickerProviderStateMixin {
  String _phase = 'load'; // load film burst drop idle spin result
  VideoPlayerController? _film;
  Map<String, dynamic> _state = <String, dynamic>{};
  Map<String, dynamic> _prize = <String, dynamic>{};
  late final AnimationController _drop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150));
  late final AnimationController _spinC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4600));
  late final AnimationController _fxC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _shineC = AnimationController(
      vsync: this, duration: const Duration(seconds: 6))
    ..repeat();
  // the regal idle turn: one full revolution every 44 seconds
  late final AnimationController _idleC = AnimationController(
      vsync: this, duration: const Duration(seconds: 44))
    ..repeat();
  double _baseAngle = 0.0;
  double _targetAngle = 0.0;
  bool _useToken = false;
  bool _busy = false;

  static const List<List<dynamic>> _segs = <List<dynamic>>[
    <dynamic>['₹3', 0xFFFFB300, 'rupee'],
    <dynamic>['WORD', 0xFFFF4081, 'word'],
    <dynamic>['₹7', 0xFFFF7A00, 'rupee'],
    <dynamic>['RESTS', 0xFFC0B7A6, 'rest'],
    <dynamic>['₹15', 0xFF00C853, 'rupee'],
    <dynamic>['IMAGE', 0xFF7C4DFF, 'image'],
    <dynamic>['₹21', 0xFFD50000, 'rupee'],
    <dynamic>['LETTER', 0xFFE91E63, 'letter'],
    <dynamic>['RESTS', 0xFFB0A692, 'rest'],
    <dynamic>['VOICE', 0xFFAD1457, 'voice'],
    <dynamic>['CHOICE', 0xFFE7B14C, 'choice'],
    <dynamic>['MOMENT', 0xFFFF6E40, 'moment'],
  ];

  List<WheelSeg> get _wheelSegs => _segs
      .map((List<dynamic> s) =>
          WheelSeg(s[0] as String, Color(s[1] as int), s[2] as String))
      .toList();

  @override
  void initState() {
    super.initState();
    WheelService.instance.state(force: true).then((Map<String, dynamic> m) {
      if (!mounted) return;
      setState(() => _state = m);
      final bool open = m['open'] == true;
      if (!open) {
        setState(() => _phase = 'salon');
        return;
      }
      if (widget.ceremony) {
        _startFilm();
      } else {
        setState(() => _phase = 'idle');
      }
    });
    _spinC.addListener(() {
      if (mounted) setState(() {});
    });
    _drop.addListener(() {
      if (mounted) setState(() {});
    });
    _fxC.addListener(() {
      if (mounted) setState(() {});
    });
    _idleC.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _startFilm() {
    setState(() => _phase = 'film');
    final VideoPlayerController c = VideoPlayerController.asset(
        'assets/wheels/opening_film_wheel_of_fans.mp4');
    _film = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(1.0);
      c.play();
      c.addListener(() {
        if (c.value.position >= c.value.duration &&
            _phase == 'film' &&
            mounted) {
          _burst();
        }
      });
    }).catchError((Object e) {
      if (mounted) _burst();
    });
  }

  void _burst() {
    _film?.pause();
    WofSound.play('descent');
    setState(() => _phase = 'burst');
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _phase = 'drop');
      _drop.forward();
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _phase = 'idle');
      });
    });
  }

  Future<void> _doSpin() async {
    if (_busy) return;
    _busy = true;
    final Map<String, dynamic> st =
        await WheelService.instance.state(force: true);
    if (st['open'] != true) {
      setState(() => _phase = 'salon');
      _busy = false;
      return;
    }
    if (_useToken && (st['tokens'] as int? ?? 0) < 1) _useToken = false;
    WofSound.play('spin');
    _idleC.stop();
    setState(() => _phase = 'spin');
    final Map<String, dynamic> r =
        await WheelService.instance.spin(useToken: _useToken);
    if (r['ok'] != true) {
      setState(() {
        _phase = 'salon';
        _prize = r;
      });
      _busy = false;
      return;
    }
    final int seg = (r['seg'] as int? ?? 0).clamp(0, 11).toInt();
    final double jitter = (math.Random().nextDouble() - 0.5) * 0.35;
    final double segCenter =
        -(seg * (6.283185307 / 12)) - (6.283185307 / 24);
    _baseAngle = _currentAngle();
    _targetAngle = _baseAngle + 5 * 6.283185307 +
        (_norm(segCenter + jitter) - _norm(_baseAngle));
    _spinC.forward(from: 0).then((_) => _land(r));
  }

  double _norm(double a) => a % 6.283185307;

  double _currentAngle() {
    if (_phase == 'spin') {
      final double e = 1 - math.pow(1 - _spinC.value, 4).toDouble();
      return _baseAngle + (_targetAngle - _baseAngle) * e;
    }
    return _targetAngle + _idleC.value * 6.283185307;
  }

  void _land(Map<String, dynamic> r) {
    _idleC.repeat(); // resumes from the frozen angle: no jump at the landing
    _prize = r;
    final Map<String, dynamic> p =
        Map<String, dynamic>.from(r['prize'] as Map? ?? <dynamic, dynamic>{});
    final String kind = (p['kind'] ?? '').toString();
    if (kind == 'rest') {
      WofSound.play('rest');
    } else {
      WofSound.play('win');
      if (kind == 'rupee' || kind == 'choice') {
        Future<void>.delayed(const Duration(milliseconds: 420),
            () => WofSound.play('coin'));
        _fxC.forward(from: 0);
      }
    }
    setState(() {
      _phase = 'result';
      _state['purse'] = r['purse'];
      _state['streak'] = r['streak'];
      _state['tokens'] = r['tokens'];
    });
    _busy = false;
  }

  @override
  void dispose() {
    _film?.dispose();
    _drop.dispose();
    _spinC.dispose();
    _fxC.dispose();
    _shineC.dispose();
    _idleC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'salon') return const WheelSalon();
    return Material(
      color: const Color(0xFF241033),
      child: Stack(
        children: <Widget>[
          const WheelSky(dense: true),
          SafeArea(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_phase == 'load') {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE7B14C)));
    }
    if (_phase == 'film') {
      return GestureDetector(
        onTap: _burst,
        child: Center(
          child: AspectRatio(
            aspectRatio: _film != null && _film!.value.isInitialized
                ? _film!.value.aspectRatio
                : 0.5625,
            child: _film != null && _film!.value.isInitialized
                ? VideoPlayer(_film!)
                : const CircularProgressIndicator(
                    color: Color(0xFFE7B14C)),
          ),
        ),
      );
    }
    final double dropY = _phase == 'drop'
        ? -1 + _drop.value
        : (_phase == 'burst' ? -1 : 0);
    return Column(
      children: <Widget>[
        WheelCrest(onClose: () => Navigator.pop(context)),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (_phase == 'burst') ConfettiBurst(t: 0.35, seed: 11),
              if (_phase == 'result' &&
                  (_prize['prize']?['kind'] == 'rupee' ||
                      _prize['prize']?['kind'] == 'choice')) ...<Widget>[
                ConfettiBurst(t: _fxC.value, seed: 5),
                CoinFlight(t: _fxC.value),
              ],
              Transform.translate(
                offset: Offset(0, dropY * MediaQuery.of(context).size.height),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: WheelPainter(
                      segs: _wheelSegs,
                      angle: _currentAngle(),
                      shine: _shineC.value,
                    ),
                  ),
                ),
              ),
              // the golden feather pointer, seated at the top notch
              Positioned(
                top: 2,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Image.asset(
                    'assets/wheels/wheel_feather.png',
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (BuildContext c, Object e, StackTrace? st) =>
                        CustomPaint(
                      size: const Size(30, 34),
                      painter: _FeatherPointer(),
                    ),
                  ),
                ),
              ),
              if (_phase == 'result') _resultCard(),
            ],
          ),
        ),
        if (_phase == 'idle' || _phase == 'spin') _footer(),
        if (_phase == 'result')
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ENTER THE HOUSE',
                        style: TextStyle(
                            color: Color(0xFFFFD98A), letterSpacing: 1.6)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => _phase = 'salon'),
                    child: const Text('MY PURSE',
                        style: TextStyle(
                            color: Color(0xFFF3E3C6), letterSpacing: 1.6)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _footer() {
    final int tokens = (_state['tokens'] as int? ?? 0);
    final bool spinning = _phase == 'spin';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Column(
        children: <Widget>[
          if (tokens > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Switch(
                  value: _useToken,
                  onChanged: spinning ? null : (bool v) => setState(() => _useToken = v),
                  activeColor: const Color(0xFFE7B14C),
                ),
                const Flexible(
                  child: Text(
                    'spend a Gilded Spin token (a rest becomes ₹3)',
                    style: TextStyle(color: Color(0xFFFFE9B8), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          Opacity(
            opacity: spinning ? 0.6 : 1,
            child: GestureDetector(
              onTap: spinning ? null : _doSpin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF0C060), Color(0xFFC98A2E)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF8A5E1C), width: 1.4),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                        color: Color(0x80E7B14C),
                        blurRadius: 18,
                        offset: Offset(0, 6)),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  spinning ? 'THE FEATHER DECIDES…' : 'SPIN',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Color(0xFF4A0E17)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'purse ₹${_state['purse'] ?? 0} · streak ${_state['streak'] ?? 0} · '
            'fortunes declared in the salon',
            style: const TextStyle(color: Color(0xCCFFE9B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final Map<String, dynamic> p = Map<String, dynamic>.from(
        _prize['prize'] as Map? ?? <dynamic, dynamic>{});
    final String kind = (p['kind'] ?? '').toString();
    String title = 'THE FEATHER RESTS';
    String body =
        'Nothing this turn — and nothing lost. She returns at the next '
        'Gilded Hour.';
    if (kind == 'rupee') {
      title = '${p['value']} RUPEES TO YOUR PURSE';
      body = 'Your Fortune Purse now holds ₹${_prize['purse']}.';
    } else if (kind == 'word') {
      title = 'A WORD FROM IVORY';
      body = '“${p['word']}” — ${p['line']}';
    } else if (kind == 'image') {
      title = 'AN IMAGE FROM IVORY';
      body = '“${p['title']}” is yours; find it in your inbox.';
    } else if (kind == 'voice') {
      title = 'A VOICE FROM IVORY';
      body = '“${p['title']}” is yours; find it in your inbox.';
    } else if (kind == 'letter') {
      title = 'A LETTER FROM IVORY';
      body = 'Ivory writes first this time. It reaches you within seven '
          'days — the house keeps its promises on a clock.';
    } else if (kind == 'moment') {
      title = 'A MOMENT FROM IVORY';
      body = 'A live moment with your name on it, within seven days.';
    } else if (kind == 'choice') {
      final String got = (p['got'] ?? '').toString();
      title = "THE FEATHER'S CHOICE";
      body = got == 'token'
          ? 'A Gilded Spin token joins your purse.'
          : got == 'rupee'
              ? 'Eleven rupees, chosen by the house itself.'
              : 'Your name rides the ticker — with Ivory\'s nod.';
    }
    final String note = (_prize['note'] ?? '').toString();
    final int petals = (_prize['petals'] as int? ?? 0);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(34),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xF2FFF6E5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7B14C), width: 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Color(0x80200A10), blurRadius: 26, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF4A0E17),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4)),
            const SizedBox(height: 10),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF3A2318), fontSize: 14, height: 1.5)),
            if (note.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF8A5E1C),
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic)),
            ],
            if (petals > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                  'Your unspent fortune bloomed into $petals laurel petal(s) '
                  'owed to you.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF8A5E1C), fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pointer: a golden feather, painted — the owner's own feather art
/// sits here in the release; the painted stand-in keeps the shape honest
/// until then.
class _FeatherPointer extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.45, size.width / 2, 0)
      ..quadraticBezierTo(size.width, size.height * 0.45, size.width / 2, size.height);
    final Paint f = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFFF6D98A), Color(0xFFB9822B)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(p, f);
    final Paint spine = Paint()
      ..color = const Color(0xFF7A5216)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(size.width / 2, 2),
        Offset(size.width / 2, size.height - 2), spine);
  }

  @override
  bool shouldRepaint(_FeatherPointer o) => false;
}

// END OF FILE - lib/widgets/wheel_room.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../services/wheel_service.dart';
import 'wheel_crown.dart';
import 'wheel_fx.dart';
import 'wheel_painter.dart';
import 'wheel_salon.dart';

/// The Wheel of Fans room.
///
/// Inside the Gilded Hours, opened for the first time that window: the
/// owner's film rises out of black in a gold-framed window, its voice
/// entering a beat after its picture so sound never runs ahead; tap
/// skips, the house never gates. Then the film folds into a point of
/// light while a gold burst blooms (moving, never frozen), and the wheel
/// falls from the sky with real weight — fast fall, a squash on its
/// velvet, a dust ring and a tremor — the descent sound riding impact. At rest the wheel never sits: it turns slowly and
/// regally under the living sky, the golden feather breathing at its
/// notch. When the fortune is declared the wheel freezes on its winner,
/// the feather leans to it and glows, the winning segment gilds, and the
/// jewel card rises at the foot of the sky. Outside the hours the room
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
  int _landSeg = -1;
  late final AnimationController _drop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _spinC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4600));
  late final AnimationController _fxC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _burstC = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _filmFade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
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
    for (final AnimationController c in <AnimationController>[
      _spinC, _drop, _fxC, _idleC, _burstC
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  void _startFilm() {
    setState(() => _phase = 'film');
    final VideoPlayerController c = VideoPlayerController.asset(
        'assets/wheels/opening_film_wheel_of_fans.mp4');
    _film = c;
    c.initialize().then((_) {
      if (!mounted) return;
      // the voice enters a beat after the picture: sound never leads
      c.setVolume(0.0);
      c.play();
      _filmFade.forward();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted && _phase == 'film') c.setVolume(1.0);
      });
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
    _burstC.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _phase = 'drop');
      _drop.forward(from: 0).then((_) {
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
    setState(() {
      _phase = 'spin';
      _landSeg = -1;
    });
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
    // the wheel freezes on its winner: the verdict stays readable
    _idleC.stop();
    _landSeg = (r['seg'] as int? ?? 0).clamp(0, 11).toInt();
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

  double _eic(double t) => t * t * t;

  double get _lean {
    if (_landSeg < 0) return 0;
    final double a = (_landSeg * 30 + 15) * math.pi / 180;
    return math.sin(a);
  }

  @override
  void dispose() {
    _film?.dispose();
    _drop.dispose();
    _spinC.dispose();
    _fxC.dispose();
    _burstC.dispose();
    _filmFade.dispose();
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

  /// The film window: black base, gold hairline frame, curtains above
  /// and below, and a fade up out of the dark.
  Widget _filmView() {
    final bool ready = _film != null && _film!.value.isInitialized;
    return Stack(
      children: <Widget>[
        Container(color: const Color(0xFF0B0610)),
        Center(
          child: AspectRatio(
            aspectRatio: ready ? _film!.value.aspectRatio : 0.5625,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0x66E7B14C), width: 1.2),
                ),
                child: ready
                    ? FadeTransition(
                        opacity: _filmFade, child: VideoPlayer(_film!))
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFE7B14C))),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xCC0B0610),
                  Color(0x000B0610),
                  Color(0x000B0610),
                  Color(0xCC0B0610),
                ],
                stops: <double>[0, 0.22, 0.78, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (_phase == 'load') {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE7B14C)));
    }
    if (_phase == 'film') {
      return GestureDetector(onTap: _burst, child: _filmView());
    }
    final double v = _drop.value;
    final double fall = v < 0.6 ? _eic(v / 0.6) : 1.0;
    final double settle = v <= 0.6 ? 0.0 : (v - 0.6) / 0.4;
    final double bv = _burstC.value;
    final double dropY = _phase == 'drop'
        ? -1.15 + 1.15 * fall
        : (_phase == 'burst' ? -1.15 : 0);
    final double squash =
        _phase == 'drop' ? math.sin(3.14159 * settle) * 0.05 * (1 - settle) : 0;
    final double shakeX =
        _phase == 'drop' ? math.sin(settle * 36) * 3 * (1 - settle) : 0;
    final double h = MediaQuery.of(context).size.height;
    return Column(
      children: <Widget>[
        WheelCrest(onClose: () => Navigator.pop(context)),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext c, BoxConstraints con) {
              final double side = math.min(con.maxWidth, con.maxHeight);
              final double top = (con.maxHeight - side) / 2;
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (_phase == 'burst') ...<Widget>[
                    Opacity(
                      opacity: (1 - bv).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 1 - 0.45 * bv,
                        child: _filmView(),
                      ),
                    ),
                    ConfettiBurst(t: bv, seed: 11),
                    DustRing(t: bv),
                  ],
                  if (_phase == 'result' &&
                      (_prize['prize']?['kind'] == 'rupee' ||
                          _prize['prize']?['kind'] == 'choice')) ...<Widget>[
                    ConfettiBurst(t: _fxC.value, seed: 5),
                    CoinFlight(t: _fxC.value),
                  ],
                  Transform.translate(
                    offset: Offset(shakeX, dropY * h),
                    child: Transform.scale(
                      scaleX: 1 + squash,
                      scaleY: 1 - squash,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: WheelPainter(
                            segs: _wheelSegs,
                            angle: _currentAngle(),
                            shine: _shineC.value,
                            highlight:
                                _phase == 'result' ? _landSeg : -1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_phase == 'drop' && settle > 0) DustRing(t: settle),
                  // the living feather, seated at the wheel's top notch
                  Positioned(
                    top: top - 34,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: LivingFeather(
                        mode: _phase == 'spin'
                            ? 'spin'
                            : (_phase == 'result' ? 'land' : 'idle'),
                        lean: _lean,
                        size: 64,
                      ),
                    ),
                  ),
                  if (_phase == 'result')
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedBuilder(
                        animation: _fxC,
                        builder: (BuildContext c, Widget? w) {
                          final double dy =
                              (1 - math.min(1, _fxC.value * 2.5)) * 90;
                          return Transform.translate(
                              offset: Offset(0, dy), child: w);
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                          child: FortuneCard.fromPrize(_prize),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (_phase == 'idle' || _phase == 'spin') _footer(),
        if (_phase == 'result') _resultRow(),
      ],
    );
  }

  Widget _resultRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFFF0C060), Color(0xFFC98A2E)],
                  ),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFF8A5E1C), width: 1.2),
                ),
                alignment: Alignment.center,
                child: const Text('ENTER THE HOUSE',
                    style: TextStyle(
                        color: Color(0xFF4A0E17),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _phase = 'salon'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFE7B14C), width: 1.4),
                ),
                alignment: Alignment.center,
                child: const Text('MY PURSE',
                    style: TextStyle(
                        color: Color(0xFFFFD98A),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6)),
              ),
            ),
          ),
        ],
      ),
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

}

// END OF FILE - lib/widgets/wheel_room.dart

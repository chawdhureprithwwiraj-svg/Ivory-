import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/wheel_service.dart';
import 'wheel_fx.dart';
import 'wheel_painter.dart';

/// The Wheel of Fans salon — the room a member finds when they tap the
/// medallion outside the Gilded Hours. It teaches: what the wheel is,
/// when it turns next, what the house declares (rupees only, never a
/// percentage), what the member's purse holds and what today's fortunes
/// were. Rebuilt in the royale hand: the living sky behind, cream cards
/// with gold borders and jewel bars, cocoa text at reading size, gold
/// gradient buttons and a claim field you can actually see. Nothing
/// here sells; it only invites.
class WheelSalon extends StatefulWidget {
  const WheelSalon({super.key});

  @override
  State<WheelSalon> createState() => _WheelSalonState();
}

class _WheelSalonState extends State<WheelSalon> {
  Map<String, dynamic> _s = <String, dynamic>{};
  String _giftMsg = '';
  final TextEditingController _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    WofSound.play('salon');
    WheelService.instance.state(force: true).then((Map<String, dynamic> m) {
      if (mounted) setState(() => _s = m);
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _str(String k) => (_s[k] ?? '').toString();
  int _int(String k) => (_s[k] is int) ? _s[k] as int : 0;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> weights =
        (_s['weights'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> ledger =
        (_s['ledger'] as List<dynamic>?) ?? <dynamic>[];
    return Material(
      color: const Color(0xFF241033),
      child: Stack(
        children: <Widget>[
          const WheelSky(dense: true),
          SafeArea(
            child: Column(
              children: <Widget>[
                WheelCrest(onClose: () => Navigator.pop(context)),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                    children: <Widget>[
                      _card(
                        'When fortune turns',
                        const Color(0xFFFFB300),
                        'Twice a day the wheel descends for two hours — '
                        '9:07 to 11:07 in the morning, 2:07 to 4:07 in the '
                        'afternoon — and on Sunday mornings a rare Sunrise '
                        'Turn at 7:07. Next opening: ${_str('next_at')}. '
                        'Come inside those hours and the wheel falls from '
                        'the air for you, turning slowly even at rest.',
                      ),
                      _card(
                        'Your Fortune Purse',
                        const Color(0xFF00C853),
                        '₹${_int('purse')} gathered · the cycle closes on '
                        '${_str('cycle_closes_at')} · streak '
                        '${_int('streak')} day(s) · Gilded Spin tokens: '
                        '${_int('tokens')}'
                        '${_int('petals_owed') > 0 ? ' · laurel petals owed to you: ${_int('petals_owed')}' : ''}. '
                        'The purse spends whole on any membership, session, '
                        'gift or single post whose price is greater than '
                        'it — one instrument per bill, the house rule.',
                      ),
                      _card(
                        'What the house declares',
                        const Color(0xFFFF4081),
                        null,
                        extra: weights.isEmpty
                            ? const Text(
                                'The wheel keeps twelve segments; every '
                                'fortune is published here, always.',
                                style: TextStyle(
                                    color: Color(0xFF3A2318),
                                    fontSize: 14.5,
                                    height: 1.5),
                              )
                            : Column(
                                children: weights
                                    .map((dynamic w) => _declRow(w))
                                    .toList(),
                              ),
                      ),
                      _card(
                        'Gift-a-Spin',
                        const Color(0xFF7C4DFF),
                        'Mint one waiting gift and send it to a friend; '
                        'whoever carries the code home gains a Gilded Spin '
                        '— and so do you, when they claim it.'
                        '${_giftMsg.isEmpty ? '' : '\n\n$_giftMsg'}',
                        extra: Column(
                          children: <Widget>[
                            const SizedBox(height: 12),
                            _goldButton('MINT & SHARE A SPIN', () async {
                              final Map<String, dynamic> m =
                                  await WheelService.instance.giftMint();
                              if (m['ok'] == true) {
                                setState(() => _giftMsg =
                                    'Your code: ${m['code']}');
                                Share.share(
                                    'A spin waits for you in Ivory\'s '
                                    'Wheel of Fans. Enter my gift code '
                                    '${m['code']} in the wheel salon — '
                                    'the Gilded Hours are 9:07–11:07 and '
                                    '2:07–4:07, and Sunday sunrise.');
                              } else {
                                setState(() =>
                                    _giftMsg = 'The house said no.');
                              }
                            }),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    controller: _code,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    style: const TextStyle(
                                        color: Color(0xFF4A0E17),
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      hintText: 'a gift code, WOF-…',
                                      hintStyle: const TextStyle(
                                          color: Color(0x807A5216),
                                          fontWeight: FontWeight.w500),
                                      filled: true,
                                      fillColor: const Color(0xFFFFFDF6),
                                      contentPadding:
                                          const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFC9A05A),
                                            width: 1.4),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFC9A05A),
                                            width: 1.4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 96,
                                  child: _goldButton('CLAIM', () async {
                                    final Map<String, dynamic> m =
                                        await WheelService.instance
                                            .giftClaim(_code.text.trim());
                                    setState(() => _giftMsg = m['ok'] == true
                                        ? (m['note'] ?? 'Claimed.').toString()
                                        : 'That code would not open — '
                                            '${m['why']}.');
                                  }, compact: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_int('spins_today') > 0)
                        _card(
                          'Today so far',
                          const Color(0xFF00BFA5),
                          '${_int('spins_today')} turn(s) taken · biggest '
                          'rupee today ₹${_int('biggest_today')}. The next '
                          'window is waiting for you.',
                        )
                      else
                        _card(
                          'If you missed today',
                          const Color(0xFF00BFA5),
                          'Nothing is lost and nothing punishes you. The '
                          'wheel simply waits for its hour — and your '
                          'streak ribbon begins again the day you return.',
                        ),
                      if (ledger.isNotEmpty)
                        _card(
                          'Your last fortunes',
                          const Color(0xFFE7B14C),
                          ledger
                              .map((dynamic l) =>
                                  '${l['at']} — ${l['label']}'
                                  '${(l['value'] as int? ?? 0) > 0 ? ' · ₹${l['value']}' : ''}')
                              .join('\n'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _declRow(dynamic w) {
    final String label = (w['label'] ?? '').toString();
    final Color gem = Color(int.parse(
        'FF${(w['color'] ?? '#E7B14C').toString().replaceFirst('#', '')}',
        radix: 16));
    final bool rupee = label.startsWith('₹');
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: <Widget>[
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: <Color>[
                  WheelPainter.shade(gem, 0.6),
                  gem,
                  WheelPainter.shade(gem, -0.4),
                ],
              ),
              border: Border.all(color: const Color(0x667A5216), width: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label.replaceFirst(' · the crown', ' — the crown'),
              style: const TextStyle(
                  color: Color(0xFF3A2318),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600),
            ),
          ),
          if (rupee)
            Text(label.split(' ').first,
                style: const TextStyle(
                    color: Color(0xFF7A1626),
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _goldButton(String label, VoidCallback onTap,
      {bool compact = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: compact ? 13 : 14, horizontal: compact ? 10 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFF0C060), Color(0xFFC98A2E)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF8A5E1C), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Color(0x668A5E1C), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Color(0xFF4A0E17),
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6),
        ),
      ),
    );
  }

  Widget _card(String title, Color jewel, String? body, {Widget? extra}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFBFFF6E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7B14C), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x66140A18), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 5,
                height: 18,
                decoration: BoxDecoration(
                  color: jewel,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Color(0xFF6B1220),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 9),
          if (body != null && body.isNotEmpty)
            Text(body,
                style: const TextStyle(
                    color: Color(0xFF3A2318), fontSize: 14.5, height: 1.55)),
          if (extra != null) extra,
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/wheel_salon.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/wheel_service.dart';
import 'wheel_fx.dart';

/// The Wheel of Fans salon — the room a member finds when they tap the
/// medallion outside the Gilded Hours. It teaches: what the wheel is,
/// when it turns next, what the house declares, what the member's purse
/// holds and what today's fortunes were — so the hour settles into the
/// mind like tea time. Nothing here sells; it only invites.
class WheelSalon extends StatefulWidget {
  const WheelSalon({super.key});

  @override
  State<WheelSalon> createState() => _WheelSalonState();
}

class _WheelSalonState extends State<WheelSalon> {
  Map<String, dynamic> _s = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    WofSound.play('salon');
    WheelService.instance.state(force: true).then((Map<String, dynamic> m) {
      if (mounted) setState(() => _s = m);
    });
  }

  String _giftMsg = '';
  final TextEditingController _code = TextEditingController();

  String _str(String k) => (_s[k] ?? '').toString();
  int _int(String k) => (_s[k] is int) ? _s[k] as int : 0;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> weights =
        (_s['weights'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> ledger =
        (_s['ledger'] as List<dynamic>?) ?? <dynamic>[];
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF2A1B3D), Color(0xFF4A0E17)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          const GoldDust(count: 18, color: Color(0x80E7B14C)),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 10, 0),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'THE WHEEL OF FANS',
                          style: TextStyle(
                              color: Color(0xFFFFE9B8),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.4),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close,
                            color: Color(0xFFE7B14C)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 26),
                    children: <Widget>[
                      _card(
                        'When fortune turns',
                        'Twice a day the wheel descends for two hours — '
                        '9:07 to 11:07 in the morning, 2:07 to 4:07 in the '
                        'afternoon — and on Sunday mornings a rare Sunrise '
                        'Turn at 7:07. Next opening: ${_str('next_at')}. '
                        'Come inside those hours and the wheel falls from '
                        'the air for you.',
                      ),
                      _card(
                        'Your Fortune Purse',
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
                        weights.isEmpty
                            ? 'The wheel keeps twelve segments; every odds '
                                'card is published here, always.'
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: weights
                                    .map((dynamic w) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: <Widget>[
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Color(int.parse(
                                                      'FF${(w['color'] ?? '#E7B14C').toString().replaceFirst('#', '')}',
                                                      radix: 16)),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${w['label']}  ·  ${w['pct']}%',
                                                  style: const TextStyle(
                                                      color: Color(0xFFF3E3C6),
                                                      fontSize: 13.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ),
                      _card(
                        'Gift-a-Spin',
                        'Mint one waiting gift and send it to a friend; '
                        'whoever carries the code home gains a Gilded Spin '
                        '- and so do you, when they claim it.'
                        '${_giftMsg.isEmpty ? '' : '\n$_giftMsg'}',
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  final Map<String, dynamic> m =
                                      await WheelService.instance.giftMint();
                                  if (m['ok'] == true) {
                                    setState(() => _giftMsg =
                                        'Your code: ${m['code']}');
                                    Share.share(
                                        'A spin waits for you in Ivory\'s '
                                        'Wheel of Fans. Enter my gift code '
                                        '${m['code']} in the wheel salon - '
                                        'the Gilded Hours are 9:07-11:07 and '
                                        '2:07-4:07, and Sunday sunrise.');
                                  } else {
                                    setState(() =>
                                        _giftMsg = 'The house said no.');
                                  }
                                },
                                child: const Text('MINT & SHARE A SPIN'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _code,
                                style: const TextStyle(
                                    color: Color(0xFFF3E3C6)),
                                decoration: const InputDecoration(
                                  hintText: 'a gift code, WOF-…',
                                  hintStyle:
                                      TextStyle(color: Color(0x80F3E3C6)),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final Map<String, dynamic> m = await WheelService
                                    .instance
                                    .giftClaim(_code.text.trim());
                                setState(() => _giftMsg = m['ok'] == true
                                    ? (m['note'] ?? 'Claimed.').toString()
                                    : 'That code would not open - '
                                        '${m['why']}.');
                              },
                              child: const Text('CLAIM'),
                            ),
                          ],
                        ),
                      ),
                      if (_int('spins_today') > 0)
                        _card(
                          'Today so far',
                          '${_int('spins_today')} turn(s) taken · biggest '
                          'rupee today ₹${_int('biggest_today')}. The next '
                          'window is waiting for you.',
                        )
                      else
                        _card(
                          'If you missed today',
                          'Nothing is lost and nothing punishes you. The '
                          'wheel simply waits for its hour — and your '
                          'streak ribbon begins again the day you return.',
                        ),
                      if (ledger.isNotEmpty)
                        _card(
                          'Your last fortunes',
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

  Widget _card(String title, Object body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x26FFF6E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x40E7B14C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFE7B14C),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6)),
          const SizedBox(height: 8),
          if (body is String && body.isNotEmpty)
            Text(body,
                style: const TextStyle(
                    color: Color(0xFFF3E3C6), fontSize: 14, height: 1.5)),
          if (body is Widget) body,
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/wheel_salon.dart

// ============================================================
// IVORY - THE DAWN HOUSE SURFACES (CC.230)
// The Dawn Door leaves the sheet and enters the house: a rank chip
// for the profile, a whisper for the tier screen, and the IST clock
// law that decides when the door creaks (06:07 to 06:37, every dawn).
// Everything here reads dawn_report and stays quiet when it cannot.
// ============================================================
import 'package:flutter/material.dart';

import '../services/early_service.dart';
import 'dawn_key.dart';

/// The house clock: IST, whatever the phone believes.
DateTime dawnIstNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

/// The creak window: 06:07 to 06:37 IST, once every dawn.
bool dawnInCreak([DateTime? at]) {
  final DateTime n = at ?? dawnIstNow();
  final int mins = n.hour * 60 + n.minute;
  return mins >= 6 * 60 + 7 && mins < 6 * 60 + 37;
}

int _i(Map<String, dynamic> d, String k) =>
    (d[k] is int) ? d[k] as int : (d[k] is num ? (d[k] as num).toInt() : 0);

/// The profile's dawn row: the member's Dawn Circle rank on their own
/// brass key, their streak, their footsteps, and - for the jury - their
/// Seer marks. One quiet card under the identity card.
class ProfileDawnChip extends StatefulWidget {
  const ProfileDawnChip({super.key});

  @override
  State<ProfileDawnChip> createState() => _ProfileDawnChipState();
}

class _ProfileDawnChipState extends State<ProfileDawnChip> {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic> m = await EarlyService.instance.dawnReport();
    if (mounted) setState(() => _d = m);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d = _d ?? <String, dynamic>{};
    if (d['ok'] != true) return const SizedBox.shrink();
    final int streak = _i(d, 'streak');
    final int reads = _i(d, 'reads');
    final int calls = _i(d, 'calls');
    final int seer = _i(d, 'seer');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF2A1650), Color(0xFF1B0E38)],
        ),
        border: Border.all(color: const Color(0x66FFE9A8), width: 1.1),
      ),
      child: Row(
        children: <Widget>[
          BrassKey(rank: d['rank']?.toString() ?? 'Before the dawn',
              glow: reads > 0, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DawnRankChip(rank: d['rank']?.toString() ?? 'Before the dawn'),
                const SizedBox(height: 6),
                Text(
                  streak > 0
                      ? '$streak dawn${streak == 1 ? '' : 's'} in a row · '
                          '$reads early read${reads == 1 ? '' : 's'} all told'
                      : '$reads early read${reads == 1 ? '' : 's'} all told',
                  style: const TextStyle(
                      color: Color(0xD9FFF6E5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700),
                ),
                if (calls > 0)
                  Text('$seer of $calls First Screening calls true',
                      style: const TextStyle(
                          color: Color(0xCCFFB3C6), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The tier screen's whisper: what the dawn practice has already earned,
/// and what waits behind the door. For members already premium, it names
/// their seat in tonight's Screening instead.
class PaywallWhisper extends StatefulWidget {
  const PaywallWhisper({super.key, required this.paid});
  final bool paid;

  @override
  State<PaywallWhisper> createState() => _PaywallWhisperState();
}

class _PaywallWhisperState extends State<PaywallWhisper> {
  Map<String, dynamic>? _d;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, dynamic> m = await EarlyService.instance.dawnReport();
    if (mounted) setState(() => _d = m);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> d = _d ?? <String, dynamic>{};
    if (d['ok'] != true) return const SizedBox.shrink();
    final int discount = _i(d, 'discount');
    final int streak = _i(d, 'streak');
    final int seats = _i(d, 'seats_today');
    final String text = widget.paid
        ? (seats > 0
            ? 'Tonight the jury sits: $seats seat${seats == 1 ? '' : 's'} '
                'taken so far. Your verdict is waiting in the Early Door.'
            : 'Your seat in the First Screening is kept warm every dawn - '
                'the held cuts read whole for you before the world.')
        : (discount > 0
            ? 'Your $streak dawn${streak == 1 ? '' : 's'} have already taken '
                '\u20B9$discount off your first premium month. On the other '
                'side of the door, the jury reads every held story whole '
                'before the world - and their notes reach Ivory\u2019s desk.'
            : 'Every dawn you keep takes \u20B9${_i(d, 'per_dawn')} off your '
                'first premium month, up to \u20B9${_i(d, 'cap')}. And behind '
                'the door sits the First Screening - the held cuts, read '
                'whole before the world, by the jury alone.');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0x26191036),
        border: Border.all(color: const Color(0x559A55E6), width: 1.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.mode_night_outlined,
              color: Color(0xFFE3C7FF), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xE6F3E6FF),
                    fontSize: 12,
                    height: 1.5,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}
// END OF FILE - lib/widgets/dawn_house.dart

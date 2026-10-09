import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import '../services/gift_service.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';
import '../widgets/admin_post_chips.dart';
import 'live_screen.dart';

/// ============================================================
/// ADMIN STUDIO - GOING LIVE
///
/// The rare one: a broadcast a whole tier may watch, where only you
/// speak and members write. Set a title, choose who may watch, and
/// the moment you tap GO LIVE every entitled member gets a push and
/// the gold banner appears on their Home screen.
/// ============================================================
class AdminLiveTab extends StatefulWidget {
  const AdminLiveTab({super.key});

  @override
  State<AdminLiveTab> createState() => _AdminLiveTabState();
}

class _AdminLiveTabState extends State<AdminLiveTab> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _subtitle = TextEditingController();
  final TextEditingController _price = TextEditingController(text: '499');

  /// Exact tiers that may watch. Empty = nobody, all pay.
  Set<int> _who = <int>{0, 1, 2, 3, 4};
  bool _payPerView = false;
  bool _busy = false;
  String? _note;

  List<LiveSession> _sessions = <LiveSession>[];
  List<GiftSend> _gifts = <GiftSend>[];
  Map<String, String> _giftSets = <String, String>{};
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _load();
    // The on-air card counts up while you are broadcasting.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _onAir != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _title.dispose();
    _subtitle.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<LiveSession> rows =
          await LiveService.instance.fetchSessions();
      final List<GiftSend> gifts =
          await LiveService.instance.listGiftSends();
      final Map<String, String> sets =
          await LiveService.instance.giftSurfaces();
      if (!mounted) return;
      setState(() {
        _sessions = rows;
        _gifts = gifts;
        _giftSets = sets;
      });
    } catch (_) {}
  }

  LiveSession? get _onAir {
    for (final LiveSession s in _sessions) {
      if (s.isLive) return s;
    }
    return null;
  }

  Future<void> _goLive() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _note = 'Give the broadcast a title first.');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final int id = await LiveService.instance.startLive(
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim().isEmpty
            ? null
            : _subtitle.text.trim(),
        access: 'tier',
        minTier: _who.isEmpty ? 9 : _who.reduce((a, b) => a < b ? a : b),
        priceInr: _payPerView ? (int.tryParse(_price.text.trim()) ?? 0) : 0,
      );
      await Supabase.instance.client
          .from('live_sessions')
          .update(<String, dynamic>{
        'allowed_tiers': (List<int>.from(_who)..sort()).toList(),
      }).eq('id', id);
      if (!mounted) return;
      setState(() => _busy = false);
      await _load();
      await _open(id, _title.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _note = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _open(int id, String title, [DateTime? startedAt]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveScreen(
          sessionId: id,
          title: title,
          mode: LiveMode.host,
          // The clock in the room must read the same as the
          // clock on this tab, and as every member's.
          startedAt: startedAt,
        ),
      ),
    );
    _load();
  }

  Future<void> _end(LiveSession s) async {
    setState(() => _busy = true);
    try {
      await LiveService.instance.endLive(s.id);
      if (!mounted) return;
      setState(() => _note = 'The broadcast has ended.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _note = e.toString().replaceFirst('Exception: ', ''));
    }
    setState(() => _busy = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final LiveSession? live = _onAir;

    return RefreshIndicator(
      color: IvoryColors.amber,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: <Widget>[
          if (live != null) _onAirCard(live) else _setupCard(),
          const SizedBox(height: 22),
          if (_gifts.isNotEmpty) ...<Widget>[
            const AdminLabel('Gifts'),
            ..._gifts.take(20).map(_giftRow),
            const SizedBox(height: 18),
          ],
          if (_sessions.length > (live == null ? 0 : 1)) ...<Widget>[
            const AdminLabel('Earlier broadcasts'),
            ..._sessions
                .where((LiveSession s) => !s.isLive)
                .map(_historyRow),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  Widget _onAirCard(LiveSession s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: IvoryColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: IvoryTheme.softShadow(blur: 20, y: 7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'YOU ARE ON AIR',
            style: TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            s.title,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_elapsed(s)}  -  ${s.viewerCount} watching, only you',
            style: TextStyle(
              color: IvoryColors.burgundy.withValues(alpha: 0.78),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IvoryColors.burgundy,
                    foregroundColor: IvoryColors.cream,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => _open(s.id, s.title, s.startedAt),
                  icon: const Icon(Icons.videocam_rounded, size: 19),
                  label: const Text('OPEN THE ROOM'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: IvoryColors.burgundy,
                    side: const BorderSide(
                        color: IvoryColors.burgundy, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _busy ? null : () => _end(s),
                  child: const Text('END'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _setupCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: IvoryTheme.card(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('A broadcast, not a call',
              icon: Icons.podcasts_rounded),
          const SizedBox(height: 10),
          Text(
            'Everyone entitled may watch, nobody but you speaks, and they '
            'take part by writing to you on screen.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: IvoryColors.textSoft,
            ),
          ),
          const SizedBox(height: 18),
          const AdminLabel('Title'),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              hintText: 'Tonight, only for you',
            ),
          ),
          const SizedBox(height: 14),
          const AdminLabel('A line underneath (optional)'),
          TextField(
            controller: _subtitle,
            decoration: const InputDecoration(
              hintText: 'Stay as long as you like',
            ),
          ),
          const SizedBox(height: 18),
          const AdminLabel('Who may watch'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ...audienceMixChips(
                who: _who,
                tiers: <Map<String, dynamic>>[
                  for (int i = 1; i <= 4; i++)
                    <String, dynamic>{'level': i, 'name': 'Tier $i'},
                ],
                onChange: (Set<int> v) => setState(() => _who = v),
              ),
              AdminSelectChip(
                label: 'Pay per view',
                icon: Icons.currency_rupee_rounded,
                selected: _payPerView,
                onTap: () => setState(() => _payPerView = !_payPerView),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pick any mix - free members, one tier, several tiers, or '
            'nobody at all. Pay per view adds a paid way in for everyone '
            'not picked.',
            style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
          ),
          if (_payPerView) ...<Widget>[
            const SizedBox(height: 16),
            const AdminLabel('Price in rupees'),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '499'),
            ),
          ],
          if (_note != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              _note!,
              style: TextStyle(fontSize: 13, color: IvoryColors.plum),
            ),
          ],
          const SizedBox(height: 20),
          IvoryGradientButton(
            label: _busy ? 'GOING LIVE...' : 'GO LIVE NOW',
            icon: Icons.sensors_rounded,
            onPressed: _busy ? null : _goLive,
          ),
          const SizedBox(height: 10),
          Text(
            'Everyone entitled is pushed the moment you tap this, and the '
            'gold banner appears on their Home screen.',
            style: TextStyle(fontSize: 12, color: IvoryColors.textFaint),
          ),
        ],
      ),
    );
  }

  /// WHICH SET THIS GIFT CAME FROM.
  ///
  /// There are two catalogues now and they mean different
  /// things, so a row in this list that does not say which is
  /// a row she has to guess at. The tag answers it at a glance
  /// and never needs reading twice.
  ///
  /// The words are kept apart on purpose. A post gift is about
  /// something she MADE, so it says ON A POST. A live gift
  /// arrived while she was on air, so it says ON AIR. Neither
  /// borrows the other's language, and neither borrows the
  /// session words - a call is a third thing entirely and has
  /// no gifts at all.
  ///
  /// An unknown name shows nothing rather than a wrong guess.
  Widget _setTag(String? surface) {
    if (surface != 'post' && surface != 'live') {
      return const SizedBox.shrink();
    }
    final bool post = surface == 'post';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: post
            ? IvoryColors.plum.withValues(alpha: 0.10)
            : IvoryColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: post
              ? IvoryColors.plum.withValues(alpha: 0.45)
              : IvoryColors.gold,
        ),
      ),
      child: Text(
        post ? 'ON A POST' : 'ON AIR',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
          color: post ? IvoryColors.plum : IvoryColors.burgundy,
        ),
      ),
    );
  }

  Widget _giftRow(GiftSend g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: IvoryTheme.card(highlighted: g.isPending),
      child: Row(
        children: <Widget>[
          Text(g.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        '${g.name} - Rs.${g.amountInr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _setTag(_giftSets[g.name]),
                  ],
                ),
                Text(
                  '${g.sender ?? 'A member'}'
                  '${g.utr == null ? ' - no reference yet' : ' - ' + g.utr!}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: IvoryColors.textFaint,
                  ),
                ),
                if (g.note != null && g.note!.trim().isNotEmpty)
                  Text(
                    '"${g.note}"',
                    style: TextStyle(
                      fontSize: 12.3,
                      fontStyle: FontStyle.italic,
                      color: IvoryColors.textSoft,
                    ),
                  ),
              ],
            ),
          ),
          if (g.isPending)
            TextButton(
              onPressed: () async {
                await LiveService.instance.confirmGift(g.id);
                _load();
              },
              child: const Text('CONFIRM'),
            )
          else
            Icon(
              g.isConfirmed
                  ? Icons.verified_rounded
                  : Icons.block_rounded,
              size: 19,
              color: g.isConfirmed
                  ? IvoryColors.gold
                  : IvoryColors.textFaint,
            ),
        ],
      ),
    );
  }

  String _elapsed(LiveSession s) {
    final DateTime? start = s.startedAt;
    if (start == null) return 'on air';
    final Duration d = DateTime.now().difference(start);
    final String h = d.inHours > 0 ? '${d.inHours}:' : '';
    final String m = (d.inMinutes % 60)
        .toString()
        .padLeft(d.inHours > 0 ? 2 : 1, '0');
    final String sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return 'on air $h$m:$sec';
  }

  Widget _historyRow(LiveSession s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(),
      child: Row(
        children: <Widget>[
          Icon(Icons.history_rounded,
              size: 19, color: IvoryColors.textFaint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.title,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.status == 'ended' ? 'Ended' : 'Scheduled',
                  style: TextStyle(
                    fontSize: 12,
                    color: IvoryColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_live_tab.dart

import '../widgets/admin_stat_grid.dart';
import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/reward_models.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/gold_fx.dart';
import '../widgets/reward_badge.dart';
import 'admin_gift_reminder.dart';
import 'reward_editor.dart';

/// ============================================================
/// ADMIN STUDIO - THE REWARDS STUDIO
///
/// Create badges and access keys, choose what earns each one, switch
/// them on and off, and see how many members hold each. A treasure is
/// never deleted: switching it off stops new members earning it and
/// members who already have it keep it. Nothing here can be bought.
/// ============================================================
class AdminRewardsTab extends StatefulWidget {
  const AdminRewardsTab({super.key});

  @override
  State<AdminRewardsTab> createState() => _AdminRewardsTabState();
}

class _AdminRewardsTabState extends State<AdminRewardsTab> {
  List<Map<String, dynamic>> _defs = <Map<String, dynamic>>[];
  Map<String, dynamic> _sum = <String, dynamic>{};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<Map<String, dynamic>> d = await RewardService.instance
          .adminDefs();
      final Map<String, dynamic> s = await RewardService.instance
          .adminSummary();
      if (!mounted) return;
      setState(() {
        _defs = d;
        _sum = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = adminDetail(e);
        _loading = false;
      });
    }
  }

  int _n(String k) => ((_sum[k] as num?) ?? 0).toInt();

  int _earnedBy(Map<String, dynamic> d) {
    final dynamic per = _sum['per_reward'];
    if (per is Map) return ((per['${d['id']}'] as num?) ?? 0).toInt();
    return 0;
  }

  Future<void> _edit([Map<String, dynamic>? d]) async {
    final bool? saved = await showRewardEditor(context, def: d);
    if (saved == true) _load();
  }

  Future<void> _toggle(Map<String, dynamic> d, bool on) async {
    try {
      await RewardService.instance.adminSaveDef(
        d['id'] as int,
        <String, dynamic>{'is_active': on},
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(adminDetail(e))));
    }
  }

  Widget _tile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: IvoryColors.plum,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: IvoryColors.burgundy,
              fontFamily: IvoryTheme.displayFont,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> d) {
    final bool on = d['is_active'] == true;
    final bool access = d['kind'] == 'access';
    final int n = ((d['trigger_value'] as num?) ?? 1).toInt();
    final int? days = (d['valid_days'] as num?)?.toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: IvoryTheme.card(highlighted: on, radius: 18),
      child: Row(
        children: <Widget>[
          Opacity(
            opacity: on ? 1 : 0.5,
            child: RewardBadge(
              shape: '${d['shape']}',
              metal: '${d['metal']}',
              size: 62,
              animate: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${d['name']}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                Text(
                  '${access ? 'ACCESS KEY \u00B7 ${d['access_key']}' : 'BADGE'}'
                  '${access ? (days == null ? ' \u00B7 no end date' : ' \u00B7 $days days') : ''}',
                  style: const TextStyle(
                    color: IvoryColors.plum,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rewardGoalText('${d['trigger_type']}', n),
                  style: TextStyle(
                    color: IvoryColors.plum.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                if (d['prize_kind'] != null)
                  Text(
                    'Gives a code: ${discountOffText('${d['prize_kind']}', ((d['prize_value'] as num?) ?? 0).toInt(), (d['prize_max_off'] as num?)?.toInt())}',
                    style: const TextStyle(
                      color: GoldTones.deep,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Text(
                  'Held by ${_earnedBy(d)} ${_earnedBy(d) == 1 ? 'member' : 'members'}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: <Widget>[
              Switch(
                value: on,
                activeThumbColor: IvoryColors.burgundy,
                onChanged: (bool v) => _toggle(d, v),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: IvoryColors.plum,
                onPressed: () => _edit(d),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.burgundy),
      );
    }
    final int active = _defs
        .where((Map<String, dynamic> d) => d['is_active'] == true)
        .length;
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: <Widget>[
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _error!,
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
              ),
            ),
          const Text(
            'THE REWARDS STUDIO',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 12),
          AdminStatGrid(
            children: <Widget>[
              _tile('TREASURES MADE', '${_defs.length}'),
              _tile('SWITCHED ON', '$active'),
              _tile('EARNED IN ALL', '${_n('earned_total')}'),
              _tile('MEMBERS HOLDING', '${_n('holders')}'),
            ],
          ),
          const SizedBox(height: 16),
          IvoryGradientButton(
            label: 'NEW TREASURE',
            icon: Icons.add,
            onPressed: () => _edit(),
          ),
          const SizedBox(height: 16),
          const AdminGiftReminder(),
          for (final Map<String, dynamic> d in _defs) _row(d),
          const SizedBox(height: 8),
          Text(
            'Treasures are earned by what a member does: lighting the Golden '
            'Heart, a glow of so many days, opening a Ten-Day Vault, a perfect '
            '10 in the Knock-off. A badge is a keepsake and stays for ever. An '
            'access key can last a number of days; once it ends, the member '
            'keeps it on their shelf but it no longer opens anything. '
            'Treasures cannot be deleted: switch one off and members who '
            'already earned it keep it. The starter ideas are switched off '
            'until you turn them on. Nothing here can be bought.',
            style: TextStyle(
              color: IvoryColors.plum.withValues(alpha: 0.82),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_rewards_tab.dart

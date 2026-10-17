import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/vault_models.dart';
import '../services/quiz_service.dart';
import '../services/vault_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ADMIN STUDIO - THE GOLDEN KNOCK-OFF AND THE TEN-DAY VAULT
///
/// What the quiz has done (plays, perfect tens, gold issued, spent
/// and faded) and the four dials the house may turn: open or shut,
/// days between quizzes, hours to spend the gold, seconds per
/// question and the least a member may pay. Prices live in Tiers;
/// the rupee bands live in the database and are not edited here.
/// Below it: the membership rule both quizzes share, what the
/// Ten-Day Vault has done, its dials, and two rehearsal buttons.
/// ============================================================
class AdminGoldTab extends StatefulWidget {
  const AdminGoldTab({super.key});

  @override
  State<AdminGoldTab> createState() => _AdminGoldTabState();
}

class _AdminGoldTabState extends State<AdminGoldTab> {
  Map<String, dynamic> _sum = <String, dynamic>{};
  bool _open = true;
  int _cool = 20;
  int _hours = 6;
  int _secs = 30;
  int _min = 0;
  int _renew = 10;
  bool _hasVault = false;
  bool _vOpen = true;
  int _vDays = 10;
  int _vGap = 6;
  int _vStart = 4;
  int _vRemind = 9;
  int _vLast = 22;
  Map<String, dynamic> _vsum = <String, dynamic>{};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _n(String k) => ((_sum[k] as num?) ?? 0).toInt();

  int _v(String k) => ((_vsum[k] as num?) ?? 0).toInt();

  int _cfgInt(Map<String, dynamic> cfg, String k, int d) =>
      ((cfg[k] as num?) ?? d).toInt();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> sum = await QuizService.instance
          .adminSummary();
      final Map<String, dynamic> cfg = await QuizService.instance
          .adminSettings();
      Map<String, dynamic> vsum = <String, dynamic>{};
      try {
        vsum = await VaultService.instance.adminSummary();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _vsum = vsum;
        _hasVault = cfg.containsKey('vault_days');
        _renew = _cfgInt(cfg, 'renew_window_days', 10);
        _vOpen = cfg['vault_open'] != false;
        _vDays = _cfgInt(cfg, 'vault_days', 10);
        _vGap = _cfgInt(cfg, 'vault_gap_hours', 6);
        _vStart = _cfgInt(cfg, 'vault_day_start_hour', 4);
        _vRemind = _cfgInt(cfg, 'vault_remind_hour', 9);
        _vLast = _cfgInt(cfg, 'vault_lastcall_hour', 22);
        _sum = sum;
        _open = cfg['is_open'] != false;
        _cool = ((cfg['cooldown_days'] as num?) ?? 20).toInt();
        _hours = ((cfg['credit_hours'] as num?) ?? 6).toInt();
        _secs = ((cfg['question_seconds'] as num?) ?? 30).toInt();
        _min = ((cfg['min_payable_inr'] as num?) ?? 0).toInt();
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await QuizService.instance.adminSaveSettings(<String, dynamic>{
        'is_open': _open,
        'cooldown_days': _cool,
        'credit_hours': _hours,
        'question_seconds': _secs,
        'min_payable_inr': _min,
        if (_hasVault) ...<String, dynamic>{
          'renew_window_days': _renew,
          'vault_open': _vOpen,
          'vault_days': _vDays,
          'vault_gap_hours': _vGap,
          'vault_day_start_hour': _vStart,
          'vault_remind_hour': _vRemind,
          'vault_lastcall_hour': _vLast,
        },
      });
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Saved. New quizzes and vaults follow these settings.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast(adminDetail(e));
    }
  }

  Future<void> _rehearsal(bool reset) async {
    try {
      if (reset) {
        await VaultService.instance.rehearsalReset();
      } else {
        await VaultService.instance.rehearsalNextDay();
      }
      if (!mounted) return;
      _toast(
        reset
            ? 'Your rehearsal vault is cleared. Open the Home card to begin.'
            : 'Your rehearsal moved to the next day. Open the Home card.',
      );
    } catch (e) {
      if (!mounted) return;
      _toast(adminDetail(e));
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _tile(String label, String value, {String? sub}) {
    return Container(
      width: 150,
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
          if (sub != null)
            Text(
              sub,
              style: TextStyle(color: IvoryColors.textFaint, fontSize: 11.5),
            ),
        ],
      ),
    );
  }

  Widget _stepper(
    String label,
    int v,
    int lo,
    int hi,
    int step,
    String unit,
    void Function(int) apply, {
    String Function(int)? fmt,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: v - step >= lo
                ? () => setState(() => apply(v - step))
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: IvoryColors.plum,
          ),
          SizedBox(
            width: 74,
            child: Text(
              fmt == null ? '$v $unit' : fmt(v),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: v + step <= hi
                ? () => setState(() => apply(v + step))
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: IvoryColors.plum,
          ),
        ],
      ),
    );
  }

  List<Widget> _vaultSection() {
    return <Widget>[
      const SizedBox(height: 26),
      const Text(
        'THE TEN-DAY VAULT',
        style: TextStyle(
          color: IvoryColors.plum,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: <Widget>[
          _tile('VAULTS STARTED', '${_v('started')}'),
          _tile('RUNNING NOW', '${_v('active')}'),
          _tile('VAULTS OPENED', '${_v('finished')}'),
          _tile('PERFECT VAULTS', '${_v('perfect')}'),
          _tile('MISSED A DAY', '${_v('broken')}', sub: 'started over'),
          _tile('ENDED BY A MEMBERSHIP', '${_v('ended')}'),
          _tile(
            'GOLD ISSUED',
            '\u20B9${_v('issued_inr')}',
            sub: '${_v('issued_n')} credits',
          ),
          _tile(
            'GOLD SPENT',
            '\u20B9${_v('used_inr')}',
            sub: '${_v('used_n')} memberships',
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '${_v('questions')} active vault questions.',
        style: TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
        decoration: IvoryTheme.card(),
        child: Column(
          children: <Widget>[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.burgundy,
              title: const Text(
                'Vault is open to members',
                style: TextStyle(
                  color: IvoryColors.burgundy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              value: _vOpen,
              onChanged: (bool v) => setState(() => _vOpen = v),
            ),
            _stepper(
              'Days in a vault',
              _vDays,
              3,
              30,
              1,
              'days',
              (int v) => _vDays = v,
            ),
            _stepper(
              'Wait before the next vault',
              _vGap,
              0,
              168,
              1,
              'hours',
              (int v) => _vGap = v,
            ),
            _stepper(
              'Each day turns over at',
              _vStart,
              0,
              23,
              1,
              '',
              (int v) => _vStart = v,
              fmt: vaultHour,
            ),
            _stepper(
              'Morning reminder from',
              _vRemind,
              0,
              23,
              1,
              '',
              (int v) => _vRemind = v,
              fmt: vaultHour,
            ),
            _stepper(
              'Last-call reminder from',
              _vLast,
              0,
              23,
              1,
              '',
              (int v) => _vLast = v,
              fmt: vaultHour,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rehearsal(false),
              child: const Text('REHEARSAL: NEXT DAY'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rehearsal(true),
              child: const Text('REHEARSAL: START OVER'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Times are India time. A vault already running keeps the number of '
        'days it started with. A rehearsal is for admins only: it never '
        'creates gold and never locks anything, and its days can be moved '
        'forward with the buttons above.',
        style: TextStyle(
          color: IvoryColors.textFaint,
          fontSize: 12.5,
          height: 1.5,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: IvoryColors.burgundy),
      );
    }
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
            'THE GOLDEN KNOCK-OFF',
            style: TextStyle(
              color: IvoryColors.plum,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _tile(
                'QUIZZES PLAYED',
                '${_n('attempts')}',
                sub: '${_n('attempts_7d')} in 7 days',
              ),
              _tile('MEMBERS PLAYING', '${_n('players')}'),
              _tile('PERFECT TENS', '${_n('perfect')}'),
              _tile(
                'GOLD ISSUED',
                '\u20B9${_n('issued_inr')}',
                sub: '${_n('issued_n')} credits',
              ),
              _tile(
                'GOLD SPENT',
                '\u20B9${_n('used_inr')}',
                sub: '${_n('used_n')} memberships',
              ),
              _tile(
                'GOLD FADED',
                '\u20B9${_n('expired_inr')}',
                sub: '${_n('expired_n')} credits',
              ),
              _tile('GOLD LIVE NOW', '${_n('live_n')}', sub: 'credits unspent'),
              _tile(
                'PAID AFTER KNOCK-OFF',
                '\u20B9${_n('paid_inr')}',
                sub: 'on those memberships',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_n('questions')} active questions across ${_n('topics')} topics.',
            style: TextStyle(color: IvoryColors.textFaint, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 16),
            decoration: IvoryTheme.card(),
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: IvoryColors.burgundy,
                  title: const Text(
                    'Quiz is open to members',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  value: _open,
                  onChanged: (bool v) => setState(() => _open = v),
                ),
                _stepper(
                  'Days between quizzes',
                  _cool,
                  0,
                  365,
                  1,
                  'days',
                  (int v) => _cool = v,
                ),
                _stepper(
                  'Hours to spend the gold',
                  _hours,
                  1,
                  168,
                  1,
                  'hours',
                  (int v) => _hours = v,
                ),
                _stepper(
                  'Seconds per question',
                  _secs,
                  5,
                  300,
                  5,
                  'sec',
                  (int v) => _secs = v,
                ),
                _stepper(
                  'Least a member may pay',
                  _min,
                  0,
                  5000,
                  50,
                  'rupees',
                  (int v) => _min = v,
                ),
                if (_hasVault)
                  _stepper(
                    'Membership days left to play again',
                    _renew,
                    0,
                    365,
                    1,
                    'days',
                    (int v) => _renew = v,
                  ),
              ],
            ),
          ),
          if (_hasVault) ..._vaultSection(),
          const SizedBox(height: 14),
          IvoryGradientButton(
            label: 'SAVE ALL SETTINGS',
            icon: Icons.check,
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 12),
          Text(
            'Changes apply to quizzes that start after you save. A quiz '
            'already open finishes under the settings it started with. '
            'Admins can rehearse the quiz from the Home card; a rehearsal '
            'never creates gold and never locks anything.',
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_gold_tab.dart

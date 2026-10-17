import '../widgets/admin_stat_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../models/reward_models.dart';
import '../services/code_service.dart';
import '../theme/ivory_theme.dart';
import 'code_editor.dart';

/// ============================================================
/// ADMIN - DISCOUNT CODES
///
/// Create codes members type at checkout, see how often each has been
/// used and how much has been given, and switch them on and off. One
/// code applies to one payment and never stacks with a Golden Knock-off.
/// Personal one-time codes that come with a treasure are made by the
/// treasure and are not listed here. Codes are never deleted.
/// ============================================================
class AdminCodesTab extends StatefulWidget {
  const AdminCodesTab({super.key});

  @override
  State<AdminCodesTab> createState() => _AdminCodesTabState();
}

class _AdminCodesTabState extends State<AdminCodesTab> {
  List<Map<String, dynamic>> _codes = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
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
      final List<Map<String, dynamic>> c = await CodeService.instance
          .adminCodes();
      final Map<String, dynamic> s = await CodeService.instance.adminSummary();
      final List<Map<String, dynamic>> t = await CodeService.instance
          .adminTiers();
      if (!mounted) return;
      setState(() {
        _codes = c;
        _sum = s;
        _tiers = t;
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

  int _usedBy(Map<String, dynamic> c) {
    final dynamic per = _sum['per_code'];
    if (per is Map) return ((per['${c['id']}'] as num?) ?? 0).toInt();
    return 0;
  }

  Future<void> _edit([Map<String, dynamic>? c]) async {
    final bool? saved = await showCodeEditor(context, def: c, tiers: _tiers);
    if (saved == true) _load();
  }

  Future<void> _toggle(Map<String, dynamic> c, bool on) async {
    try {
      await CodeService.instance.adminSave(c['id'] as int, <String, dynamic>{
        'is_active': on,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(adminDetail(e))));
    }
  }

  String _date(DateTime d) {
    const List<String> mo = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${mo[d.month - 1]} ${d.year}';
  }

  String _details(Map<String, dynamic> c) {
    final List<String> p = <String>[];
    final DateTime? u = c['valid_until'] == null
        ? null
        : DateTime.tryParse('${c['valid_until']}')?.toLocal();
    if (u == null) {
      p.add('no end date');
    } else if (u.isBefore(DateTime.now())) {
      p.add('ended ${_date(u)}');
    } else {
      p.add('until ${_date(u)}');
    }
    final int used = _usedBy(c);
    final int? max = (c['max_uses'] as num?)?.toInt();
    p.add(max == null ? 'used $used' : 'used $used of $max');
    p.add(c['once_per_member'] == true ? 'once per member' : 'repeat use');
    final dynamic ids = c['tier_ids'];
    if (ids is List && ids.isNotEmpty) {
      final List<String> names = <String>[];
      for (final Map<String, dynamic> t in _tiers) {
        if (ids.contains(t['id'])) names.add('${t['name']}');
      }
      p.add('only ${names.join(', ')}');
    } else {
      p.add('every membership');
    }
    return p.join(' \u00B7 ');
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

  Widget _row(Map<String, dynamic> c) {
    final bool on = c['is_active'] == true;
    final String off = discountOffText(
      '${c['kind']}',
      ((c['value'] as num?) ?? 0).toInt(),
      (c['max_off_inr'] as num?)?.toInt(),
    );
    final String label = '${c['label'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: IvoryTheme.card(highlighted: on, radius: 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Opacity(
              opacity: on ? 1 : 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${c['code']}',
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    label.isEmpty ? off : '$off \u00B7 $label',
                    style: const TextStyle(
                      color: IvoryColors.plum,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _details(c),
                    style: TextStyle(
                      color: IvoryColors.plum.withValues(alpha: 0.82),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Switch(
                value: on,
                activeThumbColor: IvoryColors.burgundy,
                onChanged: (bool v) => _toggle(c, v),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 19),
                    color: IvoryColors.plum,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: '${c['code']}'),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied.')),
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: IvoryColors.plum,
                    onPressed: () => _edit(c),
                  ),
                ],
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
            'DISCOUNT CODES',
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
              _tile('CODES MADE', '${_n('shared_codes')}'),
              _tile('SWITCHED ON', '${_n('shared_on')}'),
              _tile('TIMES USED', '${_n('used')}'),
              _tile('GIVEN OFF', '\u20B9${_n('saved_inr')}'),
            ],
          ),
          const SizedBox(height: 16),
          IvoryGradientButton(
            label: 'NEW CODE',
            icon: Icons.add,
            onPressed: () => _edit(),
          ),
          const SizedBox(height: 16),
          if (_codes.isEmpty)
            Text(
              'No codes yet. Tap NEW CODE to make the first.',
              style: TextStyle(
                color: IvoryColors.plum.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
          for (final Map<String, dynamic> c in _codes) _row(c),
          const SizedBox(height: 8),
          Text(
            'A member types a code at checkout and sees the new price at once. '
            'The house checks it again when the order is made. One code applies '
            'to one payment, and a code cannot be added to a Golden Knock-off: '
            'the member chooses one or the other. A used code is counted when '
            'the payment is approved. A rejected payment gives the code back. '
            'Percent codes can have a cap in rupees, and a code never takes a '
            'membership below the least a member must pay. '
            '${_n('personal_made')} one-time codes have been made for members '
            'by treasures; they are private to each member and not listed '
            'here. Codes cannot be deleted: switch one off.',
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

// END OF FILE - lib/screens/admin_codes_tab.dart

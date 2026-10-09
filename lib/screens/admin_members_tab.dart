import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_insets.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';

/// ============================================================
/// ADMIN STUDIO - MEMBERS
///
/// Everything a tier unlocks is decided by one question in the
/// database: does this member hold an active subscription row?
/// Nothing asks how that row appeared. So a tier you open by hand
/// behaves exactly like one somebody paid for - the same stories,
/// the same call minutes, the same badge - and it lasts until you
/// close it again or the days you chose run out.
/// ============================================================
class AdminMembersTab extends StatefulWidget {
  const AdminMembersTab({super.key});

  @override
  State<AdminMembersTab> createState() => _AdminMembersTabState();
}

class _AdminMembersTabState extends State<AdminMembersTab> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
  bool _loading = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dynamic rows = await _db.rpc<dynamic>(
        'list_members',
        params: <String, dynamic>{
          'search_in': _search.text.trim().isEmpty ? null : _search.text.trim(),
        },
      );
      final List<dynamic> tiers = await _db
          .from('subscription_tiers')
          .select('id, name, level')
          .order('level', ascending: true);

      if (!mounted) return;
      setState(() {
        _members = rows is List
            ? rows.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        _tiers = tiers.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _say(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  void _say(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open(Map<String, dynamic> m) async {
    final int current = ((m['tier_level'] as num?) ?? 0).toInt();
    int chosen = current;
    int days = 30;
    bool forever = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Container(
          padding: EdgeInsets.fromLTRB(
            22, 18, 22, ivorySheetFoot(c, extra: 28),
          ),
          decoration: const BoxDecoration(
            color: IvoryColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                (m['display_name'] as String?) ?? 'A member',
                style: Theme.of(c).textTheme.headlineMedium,
              ),
              if (m['email'] != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  m['email'] as String,
                  style: TextStyle(fontSize: 13, color: IvoryColors.textSoft),
                ),
              ],
              const SizedBox(height: 18),
              const AdminLabel('Open which tier'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  AdminSelectChip(
                    label: 'Free',
                    icon: Icons.lock_open_rounded,
                    selected: chosen == 0,
                    onTap: () => setSheet(() => chosen = 0),
                  ),
                  for (final Map<String, dynamic> t in _tiers)
                    AdminSelectChip(
                      label: t['name'] as String,
                      icon: Icons.workspace_premium_rounded,
                      selected: chosen == ((t['level'] as num).toInt()),
                      onTap: () => setSheet(
                          () => chosen = (t['level'] as num).toInt()),
                    ),
                ],
              ),
              if (chosen > 0) ...<Widget>[
                const SizedBox(height: 18),
                const AdminLabel('For how long'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final int d in <int>[7, 30, 90, 365])
                      AdminSelectChip(
                        label: '$d days',
                        icon: Icons.schedule_rounded,
                        selected: !forever && days == d,
                        onTap: () => setSheet(() {
                          forever = false;
                          days = d;
                        }),
                      ),
                    AdminSelectChip(
                      label: 'No end date',
                      icon: Icons.all_inclusive_rounded,
                      selected: forever,
                      onTap: () => setSheet(() => forever = true),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              IvoryGradientButton(
                label: chosen == 0
                    ? 'MOVE BACK TO FREE'
                    : 'OPEN THIS TIER',
                icon: chosen == 0
                    ? Icons.lock_outline_rounded
                    : Icons.card_giftcard_rounded,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await _grant(m, chosen, forever ? null : days);
                },
              ),
              const SizedBox(height: 10),
              Text(
                chosen == 0
                    ? 'They keep everything already sent to them.'
                    : 'They are told at once, and it behaves exactly like a '
                        'tier they paid for. You can close it any time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: IvoryColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _grant(
      Map<String, dynamic> m, int level, int? days) async {
    try {
      final dynamic res = await _db.rpc<dynamic>('grant_tier', params:
          <String, dynamic>{
        'member_in': m['id'],
        'level_in': level,
        'days_in': days,
        'note_in': 'Opened by hand from the admin console',
      });
      _say(level == 0
          ? 'Moved back to free.'
          : 'Opened ${res ?? 'the tier'}'
              '${days == null ? ' with no end date.' : ' for $days days.'}');
    } catch (e) {
      _say(e.toString().replaceFirst('Exception: ', ''));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search a name or an email',
              prefixIcon: Icon(Icons.search, color: IvoryColors.plum),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: IvoryColors.amber))
              : RefreshIndicator(
                  color: IvoryColors.amber,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                    itemCount: _members.length + 1,
                    itemBuilder: (BuildContext c, int i) {
                      if (i == _members.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(
                            _members.isEmpty
                                ? 'No members found.'
                                : '${_members.length} members',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: IvoryColors.textFaint,
                            ),
                          ),
                        );
                      }
                      return _row(_members[i]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _row(Map<String, dynamic> m) {
    final int level = ((m['tier_level'] as num?) ?? 0).toInt();
    final bool manual = (m['is_manual'] as bool?) ?? false;
    final bool isAdmin = (m['role'] as String?) == 'admin';
    final String tier = (m['tier_name'] as String?) ?? 'Free';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _open(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: IvoryTheme.card(highlighted: level > 0),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: level > 0
                    ? IvoryColors.goldGradient
                    : const LinearGradient(
                        colors: <Color>[
                          Color(0xFFFFFCF2),
                          Color(0xFFFDF1DC),
                        ],
                      ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: IvoryColors.hairlineStrong),
              ),
              child: Icon(
                isAdmin ? Icons.shield_moon_rounded : Icons.person_outline,
                size: 20,
                color: IvoryColors.burgundy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (m['display_name'] as String?) ?? 'A member',
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (m['email'] != null)
                    Text(
                      m['email'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: IvoryColors.textFaint,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    level == 0
                        ? 'Free member'
                        : '$tier${manual ? ' - opened by you' : ' - paid'}'
                            '${_until(m['expires_at'] as String?)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: level == 0
                          ? IvoryColors.textFaint
                          : IvoryColors.plum,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: IvoryColors.plum),
          ],
        ),
      ),
    );
  }

  String _until(String? iso) {
    if (iso == null) return ', no end date';
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return '';
    const List<String> mo = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final DateTime l = d.toLocal();
    return ' until ${l.day} ${mo[l.month - 1]}';
  }
}

// END OF FILE - lib/screens/admin_members_tab.dart

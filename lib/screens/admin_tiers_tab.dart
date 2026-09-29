import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/premium_badge.dart';

/// ============================================================
/// ADMIN STUDIO - THE TIER MANAGER
///
/// Rename a tier, rewrite its description, change its price in rupees,
/// edit its perk list, retire it, or add a brand new one. Nothing here
/// needs a new build: the Premium tab, the checkout and every tier lock
/// read the same table, so three tiers or seven behave identically.
///
/// Tiers are never deleted - a retired tier keeps old payments and
/// memberships intact. Switching one off simply hides it from the
/// Premium tab.
/// ============================================================
class AdminTiersTab extends StatefulWidget {
  const AdminTiersTab({super.key});

  @override
  State<AdminTiersTab> createState() => _AdminTiersTabState();
}

class _AdminTiersTabState extends State<AdminTiersTab> {
  List<Map<String, dynamic>> _tiers = <Map<String, dynamic>>[];
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
      final List<Map<String, dynamic>> t =
          await AdminService.instance.fetchAllTiers();
      if (!mounted) return;
      setState(() {
        _tiers = t;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toast(String m, {bool bad = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: bad ? IvoryColors.danger : IvoryColors.plum,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: <Widget>[
          Text('Membership tiers',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Prices are in rupees and take effect the moment you save. '
            'Retiring a tier hides it from the Premium tab without '
            'touching anyone who already paid for it.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: IvoryColors.textSoft),
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: IvoryColors.amber),
              ),
            )
          else ...<Widget>[
            if (_error != null) ...<Widget>[
              Text(_error!,
                  style: const TextStyle(color: IvoryColors.danger)),
              const SizedBox(height: 14),
            ],
            ..._tiers.map(_tierCard),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _editSheet(null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ADD A NEW TIER'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IvoryColors.burgundy,
                side: const BorderSide(color: IvoryColors.burgundy),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tierCard(Map<String, dynamic> t) {
    final int id = ((t['id'] as num?) ?? 0).toInt();
    final int level = ((t['level'] as num?) ?? 0).toInt();
    final int price = ((t['price_inr'] as num?) ?? 0).toInt();
    final int days = ((t['duration_days'] as num?) ?? 30).toInt();
    final bool active = t['is_active'] == true;
    final String name = (t['name'] as String?) ?? 'Tier';
    final List<String> perks =
        ((t['perks'] as List<dynamic>?) ?? <dynamic>[]).cast<String>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: IvoryTheme.card(highlighted: active, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              PremiumBadge.chip(tierName: name, level: level),
              const Spacer(),
              Text(
                '\u20B9$price',
                style: const TextStyle(
                  fontFamily: IvoryTheme.displayFont,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: IvoryColors.burgundy,
                ),
              ),
              Text(' / $days d',
                  style:
                      TextStyle(fontSize: 12, color: IvoryColors.textFaint)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (t['description'] as String?) ?? 'No description yet.',
            style: TextStyle(
                fontSize: 13, height: 1.45, color: IvoryColors.textSoft),
          ),
          if (perks.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: perks
                  .map((String p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: IvoryColors.surfaceWarm,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: IvoryColors.hairline),
                        ),
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: IvoryColors.textSoft)),
                      ))
                  .toList(),
            ),
          ],
          Divider(color: IvoryColors.hairline, height: 26),
          Row(
            children: <Widget>[
              Text('Level $level',
                  style:
                      TextStyle(fontSize: 12, color: IvoryColors.textFaint)),
              const Spacer(),
              Text(active ? 'On sale' : 'Retired',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        active ? IvoryColors.success : IvoryColors.textFaint,
                  )),
              Switch.adaptive(
                value: active,
                activeColor: IvoryColors.gold,
                onChanged: (bool v) async {
                  try {
                    await AdminService.instance.setTierActive(id, v);
                    await _load();
                    _toast(v
                        ? '$name is on sale again.'
                        : '$name is retired. Existing members keep it.');
                  } catch (e) {
                    _toast('Could not change that: $e', bad: true);
                  }
                },
              ),
              TextButton.icon(
                onPressed: () => _editSheet(t),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('EDIT'),
                style:
                    TextButton.styleFrom(foregroundColor: IvoryColors.burgundy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One sheet for both editing and creating. [existing] null means new.
  Future<void> _editSheet(Map<String, dynamic>? existing) async {
    final bool isNew = existing == null;
    final TextEditingController name =
        TextEditingController(text: (existing?['name'] as String?) ?? '');
    final TextEditingController price = TextEditingController(
        text: '${((existing?['price_inr'] as num?) ?? 0).toInt()}');
    final TextEditingController days = TextEditingController(
        text: '${((existing?['duration_days'] as num?) ?? 30).toInt()}');
    final TextEditingController level = TextEditingController(
        text: '${((existing?['level'] as num?) ?? _nextLevel()).toInt()}');
    final TextEditingController description = TextEditingController(
        text: (existing?['description'] as String?) ?? '');
    final TextEditingController perks = TextEditingController(
      text: ((existing?['perks'] as List<dynamic>?) ?? <dynamic>[])
          .cast<String>()
          .join('\n'),
    );
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(c).viewInsets.bottom + 22,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: IvoryColors.hairline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isNew ? 'New tier' : 'Edit tier',
                    style: Theme.of(c).textTheme.headlineMedium),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      const InputDecoration(labelText: 'Tier name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: price,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '\u20B9 ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: days,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Days'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: level,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Level'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description shown on the Premium tab',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: perks,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Perks - one per line',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Level decides what unlocks: a member on level 3 can open '
                  'everything locked at 3 and below. Keep levels in order, '
                  'starting at 1.',
                  style:
                      TextStyle(fontSize: 11.8, color: IvoryColors.textFaint),
                ),
                const SizedBox(height: 18),
                IvoryGradientButton(
                  label: saving ? 'SAVING...' : 'SAVE',
                  icon: Icons.check,
                  busy: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final String n = name.text.trim();
                          final int p = int.tryParse(price.text.trim()) ?? -1;
                          final int d = int.tryParse(days.text.trim()) ?? 30;
                          final int l = int.tryParse(level.text.trim()) ?? 0;
                          if (n.length < 2 || p < 0 || l < 1) {
                            _toast(
                              'Give it a name, a price and a level of 1 '
                              'or more.',
                              bad: true,
                            );
                            return;
                          }
                          setSheet(() => saving = true);
                          try {
                            final List<String> perkList = perks.text
                                .split('\n')
                                .map((String s) => s.trim())
                                .where((String s) => s.isNotEmpty)
                                .toList();
                            if (isNew) {
                              await AdminService.instance.createTier(
                                name: n,
                                level: l,
                                priceInr: p,
                                durationDays: d,
                                description: description.text,
                                perks: perkList,
                              );
                            } else {
                              await AdminService.instance.saveTier(
                                id: ((existing['id'] as num?) ?? 0).toInt(),
                                name: n,
                                level: l,
                                priceInr: p,
                                durationDays: d,
                                description: description.text,
                                perks: perkList,
                                isActive: existing['is_active'] == true,
                              );
                            }
                            if (c.mounted) Navigator.of(c).pop();
                            await _load();
                            _toast(isNew
                                ? '$n is live on the Premium tab.'
                                : '$n updated.');
                          } catch (e) {
                            setSheet(() => saving = false);
                            _toast('Could not save: $e', bad: true);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _nextLevel() {
    int max = 0;
    for (final Map<String, dynamic> t in _tiers) {
      final int l = ((t['level'] as num?) ?? 0).toInt();
      if (l > max) max = l;
    }
    return max + 1;
  }
}

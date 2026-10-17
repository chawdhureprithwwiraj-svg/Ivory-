import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/ivory_errors.dart';
import '../services/code_service.dart';
import '../theme/ivory_theme.dart';

/// Opens the editor. [def] is a row from discount_codes, or null for a
/// new code. Returns true when something was saved.
Future<bool?> showCodeEditor(
  BuildContext context, {
  Map<String, dynamic>? def,
  required List<Map<String, dynamic>> tiers,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext _) => _CodeEditor(def: def, tiers: tiers),
  );
}

/// ============================================================
/// ADMIN - ONE DISCOUNT CODE
///
/// The code members type, what it takes off (rupees, or a percent with
/// an optional cap), the last day, how many times in all, once per
/// member, and which tiers it works for. A code is never deleted:
/// switch it off. One code applies to one payment and never stacks
/// with a Golden Knock-off.
/// ============================================================
class _CodeEditor extends StatefulWidget {
  const _CodeEditor({this.def, required this.tiers});

  final Map<String, dynamic>? def;
  final List<Map<String, dynamic>> tiers;

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  late final bool _isNew = widget.def == null;
  late final TextEditingController _code = TextEditingController(
    text: '${widget.def?['code'] ?? ''}',
  );
  late final TextEditingController _label = TextEditingController(
    text: '${widget.def?['label'] ?? ''}',
  );
  late final TextEditingController _value = TextEditingController(
    text: '${widget.def?['value'] ?? ''}',
  );
  late final TextEditingController _cap = TextEditingController(
    text: '${widget.def?['max_off_inr'] ?? ''}',
  );
  late final TextEditingController _uses = TextEditingController(
    text: '${widget.def?['max_uses'] ?? ''}',
  );
  late String _kind = '${widget.def?['kind'] ?? 'fixed'}';
  late bool _once = widget.def?['once_per_member'] ?? true;
  late bool _active = widget.def?['is_active'] ?? true;
  late DateTime? _until = widget.def?['valid_until'] == null
      ? null
      : DateTime.tryParse('${widget.def!['valid_until']}')?.toLocal();
  late final Set<int> _tiers = <int>{
    if (widget.def?['tier_ids'] is List)
      for (final dynamic t in widget.def!['tier_ids'] as List)
        (t as num).toInt(),
  };
  late bool _allTiers = _tiers.isEmpty;
  bool _saving = false;
  String? _err;

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    _value.dispose();
    _cap.dispose();
    _uses.dispose();
    super.dispose();
  }

  void _make() {
    const String a = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random r = Random.secure();
    _code.text = List<String>.generate(
      8,
      (int _) => a[r.nextInt(a.length)],
    ).join();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _date(DateTime d) => '${d.day} ${_mo[d.month - 1]} ${d.year}';

  static const List<String> _mo = <String>[
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

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: (_until != null && _until!.isAfter(now))
          ? _until!
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 1500)),
    );
    if (d != null) setState(() => _until = d);
  }

  Future<void> _save() async {
    final String code = _code.text.trim().toUpperCase();
    final int v = int.tryParse(_value.text.trim()) ?? 0;
    final int? cap = int.tryParse(_cap.text.trim());
    final int? uses = int.tryParse(_uses.text.trim());
    String? bad;
    if (!RegExp(r'^[A-Z0-9][A-Z0-9_-]{2,23}$').hasMatch(code)) {
      bad = 'The code needs 3 to 24 letters, numbers, dashes or underscores.';
    } else if (v < 1) {
      bad = 'Enter how much it takes off (1 or more).';
    } else if (_kind == 'percent' && v > 100) {
      bad = 'A percent cannot be more than 100.';
    } else if (_uses.text.trim().isNotEmpty && (uses == null || uses < 1)) {
      bad = 'Total uses must be 1 or more, or leave it empty for no limit.';
    } else if (!_allTiers && _tiers.isEmpty) {
      bad = 'Choose at least one membership, or switch on all of them.';
    }
    if (bad != null) {
      setState(() => _err = bad);
      return;
    }
    final DateTime? u = _until;
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      await CodeService.instance
          .adminSave(widget.def?['id'] as int?, <String, dynamic>{
            if (_isNew) 'code': code,
            'label': _label.text.trim(),
            'kind': _kind,
            'value': v,
            'max_off_inr': _kind == 'percent' ? cap : null,
            'valid_until': u == null
                ? null
                : '${u.year}-${_two(u.month)}-${_two(u.day)}T23:59:59+05:30',
            'max_uses': uses,
            'once_per_member': _once,
            'tier_ids': _allTiers ? null : _tiers.toList(),
            'is_active': _active,
          });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _err = adminDetail(e);
      });
    }
  }

  Widget _label2(String t) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: IvoryColors.plum,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.96,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        gradient: IvoryColors.pageGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: IvoryColors.hairlineStrong),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                _isNew ? 'NEW DISCOUNT CODE' : 'EDIT DISCOUNT CODE',
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            _label2('THE CODE MEMBERS TYPE'),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _code,
                    enabled: _isNew,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9_-]'),
                      ),
                      LengthLimitingTextInputFormatter(24),
                    ],
                    decoration: const InputDecoration(
                      hintText: 'For example: DIWALI200',
                    ),
                  ),
                ),
                if (_isNew)
                  TextButton(
                    onPressed: () => setState(_make),
                    child: const Text('MAKE ONE'),
                  ),
              ],
            ),
            _label2('A NOTE FOR YOU (MEMBERS DO NOT SEE IT)'),
            TextField(
              controller: _label,
              maxLength: 60,
              decoration: const InputDecoration(
                hintText: 'For example: Diwali offer',
              ),
            ),
            _label2('WHAT IT TAKES OFF'),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'fixed',
                  label: Text('Rupees off'),
                ),
                ButtonSegment<String>(
                  value: 'percent',
                  label: Text('Percent off'),
                ),
              ],
              style: SegmentedButton.styleFrom(
                foregroundColor: IvoryColors.burgundy,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: IvoryColors.burgundy,
                side: BorderSide(
                  color: IvoryColors.plum.withValues(alpha: 0.5),
                ),
              ),
              selected: <String>{_kind},
              onSelectionChanged: (Set<String> s) =>
                  setState(() => _kind = s.first),
            ),
            TextField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _kind == 'percent' ? 'Percent (1 to 100)' : 'Rupees',
              ),
            ),
            if (_kind == 'percent')
              TextField(
                controller: _cap,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Most it can take off, in rupees (optional)',
                ),
              ),
            _label2('LAST DAY'),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _until == null ? 'No end date' : _date(_until!),
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('CHOOSE DAY'),
                ),
                if (_until != null)
                  TextButton(
                    onPressed: () => setState(() => _until = null),
                    child: const Text('NO END'),
                  ),
              ],
            ),
            _label2('LIMITS'),
            TextField(
              controller: _uses,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total uses by all members (empty = no limit)',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.burgundy,
              title: const Text('Each member can use it only once'),
              value: _once,
              onChanged: (bool v) => setState(() => _once = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.burgundy,
              title: const Text('Works for every membership'),
              value: _allTiers,
              onChanged: (bool v) => setState(() => _allTiers = v),
            ),
            if (!_allTiers)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Map<String, dynamic> t in widget.tiers)
                    FilterChip(
                      label: Text('${t['name']}'),
                      selected: _tiers.contains((t['id'] as num).toInt()),
                      selectedColor: IvoryColors.gold.withValues(alpha: 0.45),
                      onSelected: (bool on) => setState(() {
                        final int id = (t['id'] as num).toInt();
                        if (on) {
                          _tiers.add(id);
                        } else {
                          _tiers.remove(id);
                        }
                      }),
                    ),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.burgundy,
              title: const Text('Switched on (members can use it)'),
              value: _active,
              onChanged: (bool v) => setState(() => _active = v),
            ),
            if (_err != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _err!,
                  style: const TextStyle(
                    color: IvoryColors.danger,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            IvoryGradientButton(
              label: _isNew ? 'CREATE THE CODE' : 'SAVE CHANGES',
              icon: Icons.check,
              busy: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/code_editor.dart

import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../models/reward_models.dart';
import '../services/reward_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/reward_badge.dart';

/// Opens the editor. [def] is a row from reward_defs, or null for a
/// new treasure. Returns true when something was saved.
Future<bool?> showRewardEditor(
  BuildContext context, {
  Map<String, dynamic>? def,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext _) => _RewardEditor(def: def),
  );
}

/// ============================================================
/// ADMIN STUDIO - ONE TREASURE
///
/// Pick a badge or an access key, name it, choose its shape and
/// metal (with a live preview), say what earns it and, for an access
/// key, for how many days it lasts. A treasure is never deleted: switch
/// it off and members who earned it keep it.
/// ============================================================
class _RewardEditor extends StatefulWidget {
  const _RewardEditor({this.def});

  final Map<String, dynamic>? def;

  @override
  State<_RewardEditor> createState() => _RewardEditorState();
}

class _RewardEditorState extends State<_RewardEditor> {
  late final bool _isNew = widget.def == null;
  late final TextEditingController _name = TextEditingController(
    text: '${widget.def?['name'] ?? ''}',
  );
  late final TextEditingController _blurb = TextEditingController(
    text: '${widget.def?['blurb'] ?? ''}',
  );
  late final TextEditingController _key = TextEditingController(
    text: '${widget.def?['access_key'] ?? ''}',
  );
  late final TextEditingController _num = TextEditingController(
    text: '${widget.def?['trigger_value'] ?? 1}',
  );
  late final TextEditingController _days = TextEditingController(
    text: '${widget.def?['valid_days'] ?? 30}',
  );
  late final TextEditingController _pVal = TextEditingController(
    text: '${widget.def?['prize_value'] ?? ''}',
  );
  late final TextEditingController _pCap = TextEditingController(
    text: '${widget.def?['prize_max_off'] ?? ''}',
  );
  late final TextEditingController _pDays = TextEditingController(
    text: '${widget.def?['prize_valid_days'] ?? 30}',
  );
  late bool _prize = widget.def?['prize_kind'] != null;
  late String _pKind = '${widget.def?['prize_kind'] ?? 'fixed'}';
  late String _kind = '${widget.def?['kind'] ?? 'badge'}';
  late String _shape = '${widget.def?['shape'] ?? 'medal'}';
  late String _metal = '${widget.def?['metal'] ?? 'gold'}';
  late String _trigger = '${widget.def?['trigger_type'] ?? 'first_lit'}';
  late bool _active = widget.def?['is_active'] ?? true;
  late bool _forever = widget.def == null
      ? true
      : widget.def!['valid_days'] == null;
  bool _saving = false;
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    _blurb.dispose();
    _key.dispose();
    _num.dispose();
    _days.dispose();
    _pVal.dispose();
    _pCap.dispose();
    _pDays.dispose();
    super.dispose();
  }

  String _slug(String s) {
    final String x = s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return x.length > 40 ? x.substring(0, 40) : x;
  }

  Future<void> _save() async {
    final String name = _name.text.trim();
    final int n = int.tryParse(_num.text.trim()) ?? 0;
    final String key = _key.text.trim().isEmpty
        ? _slug(name)
        : _key.text.trim();
    final int? days = int.tryParse(_days.text.trim());
    final int pv = int.tryParse(_pVal.text.trim()) ?? 0;
    final int pd = int.tryParse(_pDays.text.trim()) ?? 0;
    String? bad;
    if (name.isEmpty) {
      bad = 'Give the treasure a name.';
    } else if (_trigger != 'first_lit' && n < 1) {
      bad = 'The goal number must be 1 or more.';
    } else if (_kind == 'access' &&
        !RegExp(r'^[a-z0-9_]{2,40}$').hasMatch(key)) {
      bad = 'The access key needs 2 to 40 letters, numbers or underscores.';
    } else if (_kind == 'access' && !_forever && (days == null || days < 1)) {
      bad = 'Enter how many days the access lasts (1 or more).';
    }
    if (bad == null && _prize) {
      if (pv < 1) {
        bad = 'Enter how much the discount code takes off (1 or more).';
      } else if (_pKind == 'percent' && pv > 100) {
        bad = 'A percent cannot be more than 100.';
      } else if (pd < 1) {
        bad = 'Enter how many days the code lasts (1 or more).';
      }
    }
    if (bad != null) {
      setState(() => _err = bad);
      return;
    }
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      await RewardService.instance.adminSaveDef(
        widget.def?['id'] as int?,
        <String, dynamic>{
          if (_isNew) 'kind': _kind,
          'name': name,
          'blurb': _blurb.text.trim(),
          'shape': _shape,
          'metal': _metal,
          'trigger_type': _trigger,
          'trigger_value': _trigger == 'first_lit' ? 1 : n,
          if (_kind == 'access') ...<String, dynamic>{
            if (_isNew) 'access_key': key,
            'valid_days': _forever ? null : days,
          },
          'is_active': _active,
          'prize_kind': _prize ? _pKind : null,
          'prize_value': _prize ? pv : null,
          if (_prize) ...<String, dynamic>{
            'prize_max_off': _pKind == 'percent'
                ? int.tryParse(_pCap.text.trim())
                : null,
            'prize_valid_days': pd,
          },
        },
      );
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

  Widget _label(String t) => Padding(
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

  Widget _chips(List<String> all, String cur, void Function(String) pick) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String s in all)
          ChoiceChip(
            label: Text(s[0].toUpperCase() + s.substring(1)),
            selected: s == cur,
            selectedColor: IvoryColors.gold.withValues(alpha: 0.45),
            onSelected: (_) => setState(() => pick(s)),
          ),
      ],
    );
  }

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
                _isNew ? 'NEW TREASURE' : 'EDIT TREASURE',
                style: const TextStyle(
                  color: IvoryColors.plum,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: RewardBadge(shape: _shape, metal: _metal, size: 130),
            ),
            if (_isNew) ...<Widget>[
              _label('WHAT IS IT'),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'badge', label: Text('Badge')),
                  ButtonSegment<String>(
                    value: 'access',
                    label: Text('Access key'),
                  ),
                ],
                selected: <String>{_kind},
                onSelectionChanged: (Set<String> v) =>
                    setState(() => _kind = v.first),
              ),
            ],
            _label('NAME'),
            TextField(
              controller: _name,
              maxLength: 40,
              decoration: const InputDecoration(
                hintText: 'For example: A Week of Gold',
              ),
            ),
            _label('A LINE MEMBERS READ'),
            TextField(
              controller: _blurb,
              maxLength: 140,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Seven lit days in a row.',
              ),
            ),
            _label('SHAPE'),
            _chips(kRewardShapes, _shape, (String s) => _shape = s),
            _label('METAL'),
            _chips(kRewardMetals, _metal, (String s) => _metal = s),
            _label('WHAT EARNS IT'),
            DropdownButtonFormField<String>(
              value: _trigger,
              isExpanded: true,
              items: <DropdownMenuItem<String>>[
                for (final MapEntry<String, String> e
                    in kRewardTriggers.entries)
                  DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (String? v) =>
                  setState(() => _trigger = v ?? _trigger),
            ),
            if (_trigger != 'first_lit')
              TextField(
                controller: _num,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'N (the goal number)',
                ),
              ),
            if (_kind == 'access') ...<Widget>[
              _label('ACCESS KEY'),
              TextField(
                controller: _key,
                enabled: _isNew,
                decoration: InputDecoration(
                  hintText: _isNew
                      ? 'Leave empty to make one from the name'
                      : '',
                  helperText:
                      'The short word the app checks, for example early_viewer.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: IvoryColors.cream,
                title: const Text('Access has no end date'),
                value: _forever,
                onChanged: (bool v) => setState(() => _forever = v),
              ),
              if (!_forever)
                TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Days the access lasts once earned',
                  ),
                ),
            ],
            _label('A DISCOUNT CODE AS A PRIZE'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.cream,
              title: const Text('Also give a one-time discount code'),
              subtitle: const Text(
                'Made for each member the moment they earn this. Only for members who earn it from now on.',
              ),
              value: _prize,
              onChanged: (bool v) => setState(() => _prize = v),
            ),
            if (_prize) ...<Widget>[
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
                selected: <String>{_pKind},
                onSelectionChanged: (Set<String> v) =>
                    setState(() => _pKind = v.first),
              ),
              TextField(
                controller: _pVal,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _pKind == 'percent'
                      ? 'Percent (1 to 100)'
                      : 'Rupees',
                ),
              ),
              if (_pKind == 'percent')
                TextField(
                  controller: _pCap,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Most it can take off, in rupees (optional)',
                  ),
                ),
              TextField(
                controller: _pDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days the code lasts once earned',
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: IvoryColors.cream,
              title: const Text('Switched on (members can earn it)'),
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
              label: _isNew ? 'CREATE THE TREASURE' : 'SAVE CHANGES',
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

// END OF FILE - lib/screens/reward_editor.dart

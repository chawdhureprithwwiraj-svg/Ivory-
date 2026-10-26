import '../services/line_service.dart';
import 'package:flutter/material.dart';

import '../core/ivory_errors.dart';
import '../services/early_service.dart';
import '../services/line_house_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_stat_grid.dart';
import 'admin_line_letter.dart';
import 'admin_line_settings.dart';

/// ============================================================
/// ADMIN STUDIO - THE PRIVATE LINE
///
/// Three views: LETTERS (the queue, longest-waiting and head-start
/// first; the held ones; the answered ones), SETTINGS (the switch,
/// the numbers, tiers and rungs) and TEMPLATES (reply lines you can
/// edit). A letter opens on its own screen to be read and answered.
/// ============================================================
class AdminLineTab extends StatefulWidget {
  const AdminLineTab({
    super.key,
    this.previewData,
    this.previewLetters,
    this.previewTemplates,
  });

  /// Fixed answers to show without asking the database (previews, tests).
  final Map<String, dynamic>? previewData;
  final List<Map<String, dynamic>>? previewLetters;
  final List<Map<String, dynamic>>? previewTemplates;

  @override
  State<AdminLineTab> createState() => _AdminLineTabState();
}

class _AdminLineTabState extends State<AdminLineTab> {
  final LineHouseService _svc = LineHouseService.instance;
  Map<String, dynamic> _data = <String, dynamic>{};
  List<Map<String, dynamic>> _letters = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _templates = <Map<String, dynamic>>[];
  String _view = 'letters';
  String _filter = 'waiting';
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    if (widget.previewData != null) {
      _data = widget.previewData!;
      _letters = widget.previewLetters ?? <Map<String, dynamic>>[];
      _templates = widget.previewTemplates ?? <Map<String, dynamic>>[];
      _loading = false;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    LineService.instance.adminReport(force: true).then((Map<String, dynamic>? r) {
      if (mounted) setState(() => _report = r);
    });
    if (widget.previewData != null) return;
    try {
      final Map<String, dynamic> d = await _svc.state();
      final List<Map<String, dynamic>> q = await _svc.queue(_filter);
      List<Map<String, dynamic>> t = _templates;
      try {
        t = await _svc.templates();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _data = d;
        _letters = q;
        _templates = t;
        _error = null;
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

  void _say(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _openLetter(int id) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AdminLineLetterScreen(id: id),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _editTemplate(Map<String, dynamic>? t) async {
    final TextEditingController title =
        TextEditingController(text: '${t?['title'] ?? ''}');
    final TextEditingController body =
        TextEditingController(text: '${t?['body'] ?? ''}');
    final String? act = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(t == null ? 'New reply line' : 'Edit reply line'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Short title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'The words'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          if (t != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('DELETE'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    if (act == null) return;
    try {
      if (act == 'delete') {
        _say(await _svc.deleteTemplate((t!['id'] as num).toInt()));
      } else {
        _say(
          await _svc.saveTemplate(
            (t?['id'] as num?)?.toInt(),
            title.text.trim(),
            body.text.trim(),
          ),
        );
      }
      await _load();
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Future<void> _takeDown() async {
    try {
      _say(await _svc.clearDaily());
    } catch (e) {
      _say(adminDetail(e));
    }
  }

  Widget _heading(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 10),
    child: Text(
      t,
      style: const TextStyle(
        color: IvoryColors.plum,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.4,
      ),
    ),
  );

  /// CC.220 - the steering wheel: draw history, the free board's
  /// top ten with their carried numbers, and the stamp census.
  /// Aggregates only - no bodies, no names.
  Widget _reportCard(Map<String, dynamic> r) {
    final List<dynamic> draws = r['draws'] as List? ?? <dynamic>[];
    final List<dynamic> board = r['board'] as List? ?? <dynamic>[];
    final Map<String, dynamic> st =
        Map<String, dynamic>.from(r['stamps'] as Map? ?? <String, dynamic>{});
    TextStyle small(bool bold) => TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: IvoryColors.burgundy.withValues(alpha: bold ? 1 : 0.78),
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Waiting: ${r['waiting_paid'] == 1 ? "1 member\'s letter" : "${r['waiting_paid']} members\' letters"} at the front, '
            '${r['waiting_free'] == 1 ? "1 free letter" : "${r['waiting_free']} free letters"} in the board behind them.',
            style: small(true),
          ),
          const SizedBox(height: 10),
          Text('SATURDAY DRAWS', style: small(true)),
          if (draws.isEmpty)
            Text('No Saturday letter has been drawn yet.', style: small(false))
          else
            ...draws.map((dynamic d) => Text(
              'Week of ${d['week_start']}: '
              '${d['answered'] == true ? 'answered by Ivory' : 'with Ivory now'}',
              style: small(false),
            )),
          const SizedBox(height: 10),
          Text('THE FREE BOARD (TOP TEN)', style: small(true)),
          if (board.isEmpty)
            Text('No free letter stands in the Line yet.', style: small(false))
          else
            ...board.map((dynamic b) => Text(
              '#${b['pos']} - carried by ${b['lit']} lit days, '
              '${b['bell']} bell days, ${b['wait']} days of waiting',
              style: small(false),
            )),
          const SizedBox(height: 10),
          Text(
            'Stamps across the house: Presence ${st['presence_n'] ?? 0} - '
            'Ring ${st['ring_n'] ?? 0} - Voice ${st['voice_n'] ?? 0} - '
            'Invitation ready ${st['invited_n'] ?? 0}.',
            style: small(true),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Container(
    padding: const EdgeInsets.all(14),
    decoration: IvoryTheme.card(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

  Widget _viewChip(String key, String label) => ChoiceChip(
    label: Text(label),
    selected: _view == key,
    selectedColor: IvoryColors.burgundy,
    labelStyle: TextStyle(
      color: _view == key ? IvoryColors.ivory : IvoryColors.burgundy,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
    onSelected: (_) => setState(() => _view = key),
  );

  Widget _filterChip(String key, String label) => ChoiceChip(
    label: Text(label),
    selected: _filter == key,
    selectedColor: IvoryColors.plum,
    labelStyle: TextStyle(
      color: _filter == key ? IvoryColors.ivory : IvoryColors.plum,
      fontWeight: FontWeight.w700,
    ),
    onSelected: (_) {
      setState(() => _filter = key);
      _load();
    },
  );

  Widget _tile(Map<String, dynamic> l) {
    final DateTime? t = DateTime.tryParse('${l['created_at']}')?.toLocal();
    final String status = '${l['status']}';
    final List<String> bits = <String>[
      '${l['tier_name'] ?? 'tier'}',
      'rung ${l['rung'] ?? 0}',
      if (t != null) earlyClock(t),
      if (status == 'read') 'read',
      if (status == 'held') 'held: ${l['hold_reason'] ?? ''}',
      if (l['muted'] == true) 'muted',
      if (l['allow_share'] == true) 'may be shared',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: IvoryTheme.card(),
      child: ListTile(
        onTap: () => _openLetter((l['id'] as num).toInt()),
        title: Text(
          '${l['name']}',
          style: const TextStyle(
            color: IvoryColors.burgundy,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              bits.join('  \u00B7  '),
              style: const TextStyle(color: IvoryColors.plum, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '${l['preview'] ?? ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: IvoryColors.plum),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: IvoryColors.plum),
      ),
    );
  }

  Widget _lettersView() {
    final String none = _filter == 'held'
        ? 'Nothing is held for a look.'
        : _filter == 'answered'
            ? 'No letters answered yet.'
            : 'No letters are waiting.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            _filterChip('waiting', 'WAITING'),
            _filterChip('held', 'HELD'),
            _filterChip('answered', 'ANSWERED'),
          ],
        ),
        const SizedBox(height: 12),
        if (_letters.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              none,
              style: const TextStyle(color: IvoryColors.plum),
            ),
          )
        else
          ..._letters.map(_tile),
        if (_filter == 'waiting')
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Order: the longest wait first, with a small head start for the '
              'member\u2019s tier and rung. Opening a letter tells the member '
              'it was read.',
              style: TextStyle(color: IvoryColors.plum, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _templatesView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _heading('REPLY LINES (TAP TO EDIT)'),
      ..._templates.map(
        (Map<String, dynamic> t) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: IvoryTheme.card(),
          child: ListTile(
            onTap: () => _editTemplate(t),
            title: Text(
              '${t['title']}',
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              '${t['body']}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: IvoryColors.plum),
            ),
            trailing: const Icon(Icons.edit_outlined, color: IvoryColors.plum),
          ),
        ),
      ),
      OutlinedButton.icon(
        onPressed: () => _editTemplate(null),
        icon: const Icon(Icons.add),
        label: const Text('NEW REPLY LINE'),
      ),
      _heading('LETTER OF THE DAY'),
      const Text(
        'Share an answered letter from its own screen (only if the member '
        'allowed it). It shows on every member\u2019s Home for two days, '
        'never with a name.',
        style: TextStyle(color: IvoryColors.plum),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: _takeDown,
        child: const Text('TAKE DOWN THE LETTER OF THE DAY'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _error!,
          style: const TextStyle(color: IvoryColors.burgundy),
        ),
      );
    }
    final int clear = (_data['days_to_clear'] as num?)?.toInt() ?? 0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: <Widget>[
          _heading('THE NUMBERS'),
          AdminStatGrid(
            children: <Widget>[
              _stat('Waiting', '${_data['waiting'] ?? 0}'),
              _stat('Held for a look', '${_data['held'] ?? 0}'),
              _stat('Answered today', '${_data['answered_today'] ?? 0}'),
              _stat('To clear the queue', clear <= 1 ? '1 day' : '$clear days'),
            ],
          ),
          if (_report != null) ...<Widget>[
            _heading('THE SATURDAY DRAW & THE FREE BOARD'),
            _reportCard(_report!),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _viewChip('letters', 'LETTERS'),
              _viewChip('settings', 'SETTINGS'),
              _viewChip('templates', 'REPLY LINES'),
            ],
          ),
          if (_view == 'letters') _lettersView(),
          if (_view == 'settings')
            AdminLineSettings(data: _data, onSaved: _load),
          if (_view == 'templates') _templatesView(),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_line_tab.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/legal_screen.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE QUIET DOOR
///
/// The only way a member sends word about a problem. It is a
/// form, never a message box: pick what it is about, add at most
/// four hundred characters of "what happened", and the house
/// answers with a receipt - never a conversation.
///
/// "Something else" is the trap door: it never opens a text box.
/// It asks "Is it me you want to reach?" and hands the member to
/// the paid doors, with the legal escape hatch one quiet tap away.
/// ============================================================

void showReportSheet(
  BuildContext context, {
  String? preset,
  void Function(String tab)? onOpenTab,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(preset: preset, onOpenTab: onOpenTab),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({this.preset, this.onOpenTab});

  final String? preset;
  final void Function(String tab)? onOpenTab;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const List<List<String>> _cats = <List<String>>[
    <String>['payment', 'A payment or refund'],
    <String>['missing', "Something I bought didn't arrive"],
    <String>['content', 'Something someone wrote'],
    <String>['explicit', 'Something off-limits, or impersonation'],
    <String>['privacy', 'My privacy'],
    <String>['data', 'My account or data'],
    <String>['other', 'Something else'],
  ];

  final TextEditingController _detail = TextEditingController();
  String? _cat;
  bool _busy = false;
  bool _done = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    if (widget.preset != null &&
        _cats.any((List<String> c) => c[0] == widget.preset)) {
      _cat = widget.preset;
    }
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _detail.text.trim();
    final String? uid =
        Supabase.instance.client.auth.currentUser?.id;
    if (_cat == null || uid == null) return;
    if (text.isEmpty) {
      setState(() => _note = 'A line or two about what happened helps.');
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      await Supabase.instance.client.from('reports').insert(<String, dynamic>{
        'user_id': uid,
        'category': _cat,
        'detail': text,
      });
      if (!mounted) return;
      setState(() => _done = true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _note = '$error'.contains('one open report')
            ? 'You already have something open with the house. '
                'One at a time keeps every promise readable.'
            : 'The door jammed for a moment - try once more.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askErasure() async {
    final String? uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final List<dynamic> open = await Supabase.instance.client
          .from('erasure_requests')
          .select('id')
          .eq('user_id', uid)
          .eq('status', 'open');
      if (open.isNotEmpty) {
        setState(() =>
            _note = 'Already asked - the 90-day clock is running.');
        return;
      }
      await Supabase.instance.client
          .from('erasure_requests')
          .insert(<String, dynamic>{'user_id': uid});
      if (!mounted) return;
      setState(() => _done = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _note = 'The door jammed for a moment - try once more.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _funnel(String tab) {
    Navigator.of(context).pop();
    widget.onOpenTab?.call(tab);
  }

  TextStyle get _soft =>
      TextStyle(color: IvoryColors.textSoft, fontSize: 13.5, height: 1.5);
  TextStyle get _faint =>
      TextStyle(color: IvoryColors.textFaint, fontSize: 12, height: 1.45);
  TextStyle get _serif => TextStyle(
        fontFamily: IvoryTheme.displayFont,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: IvoryColors.burgundy,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: IvoryColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (_done) ...<Widget>[
              const SizedBox(height: 8),
              Text('Thank you for telling me.', style: _serif),
              const SizedBox(height: 8),
              Text(
                "I've seen it. The serious things I deal with the "
                'same day.',
                style: _soft,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE'),
                ),
              ),
            ] else ...<Widget>[
              Text("Something's not right?", style: _serif),
              const SizedBox(height: 6),
              Text('Pick what it is about. The house reads everything.',
                  style: _faint),
              const SizedBox(height: 12),
              ..._cats.map((List<String> c) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() {
                      _cat = c[0];
                      _note = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _cat == c[0]
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 17,
                            color: _cat == c[0]
                                ? IvoryColors.burgundy
                                : IvoryColors.textFaint,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              c[1],
                              style: TextStyle(
                                color: _cat == c[0]
                                    ? IvoryColors.burgundy
                                    : IvoryColors.textSoft,
                                fontSize: 13.5,
                                fontWeight: _cat == c[0]
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 10),
              if (_cat == 'other')
                _trapDoor()
              else if (_cat == 'data')
                _dataPanel()
              else if (_cat != null) ...<Widget>[
                Text('What happened?', style: _serif),
                const SizedBox(height: 8),
                TextField(
                  controller: _detail,
                  maxLength: 400,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: IvoryColors.surfaceWarm,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_note != null) ...<Widget>[
                  Text(_note!, style: TextStyle(
                      color: IvoryColors.danger, fontSize: 12.5)),
                  const SizedBox(height: 6),
                ],
                SizedBox(
                  width: double.infinity,
                  child: IvoryGradientButton(
                    label: 'SEND QUIETLY',
                    icon: Icons.send_outlined,
                    busy: _busy,
                    onPressed: _busy ? null : _send,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _trapDoor() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Is it me you want to reach?', style: _serif),
          const SizedBox(height: 8),
          Text(
            "This door is for problems - payments, safety, your data. "
            "If you want to talk to me, that isn't a complaint, so "
            'please select out of these options.',
            style: _soft,
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _funnel('wish'),
                  child: const Text('MAKE A WISH',
                      style: TextStyle(fontSize: 10.5)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _funnel('premium'),
                  child: const Text('SEE THE PLANS',
                      style: TextStyle(fontSize: 10.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _funnel('wish'),
              child: const Text('BOOK A CALL',
                  style: TextStyle(fontSize: 10.5)),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push<void>(MaterialPageRoute<void>(
                  builder: (_) => const LegalScreen()));
            },
            child: Text(
              'still a genuine problem? privacy, safety & terms holds '
              "the officer's door.",
              style: _faint,
            ),
          ),
        ],
      );

  Widget _dataPanel() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Your account, your data.', style: _serif),
          const SizedBox(height: 8),
          Text(
            'Ask for erasure and the house forgets you within 90 days - '
            'everything, everywhere.',
            style: _soft,
          ),
          const SizedBox(height: 12),
          if (_note != null) ...<Widget>[
            Text(_note!, style: _faint),
            const SizedBox(height: 6),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy ? null : _askErasure,
              child: const Text('ASK FOR ERASURE'),
            ),
          ),
        ],
      );
}

// END OF FILE - lib/widgets/report_sheet.dart

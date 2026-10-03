import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/ivory_theme.dart';
import '../widgets/report_sheet.dart';

/// ============================================================
/// IVORY - THE QUIET PAGE
/// "privacy, safety & terms"
///
/// Everything the rules require, written in house manner: the
/// house rules, the refund policy, the officer's door and the
/// erasure path. One faint line in Profile leads here - reachable
/// in two taps, impossible to mistake for marketing.
/// ============================================================

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  Map<String, String> _pol = <String, String>{};
  bool _loaded = false;
  bool _busy = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<dynamic> rows = await Supabase.instance.client
          .from('app_policies')
          .select('key,value');
      if (!mounted) return;
      setState(() {
        _pol = <String, String>{
          for (final dynamic r in rows) r['key'] as String: r['value'] as String,
        };
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  bool get _officerSet {
    final String email = _pol['officer_email'] ?? '';
    return email.isNotEmpty && !email.startsWith('(to be set)');
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
        setState(() => _note = 'Already asked - the 90-day clock is running.');
        return;
      }
      await Supabase.instance.client
          .from('erasure_requests')
          .insert(<String, dynamic>{'user_id': uid});
      if (!mounted) return;
      setState(() => _note = 'Asked. The house forgets within 90 days.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _note = 'The door jammed for a moment - try once more.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  TextStyle get _serif => TextStyle(
        fontFamily: IvoryTheme.displayFont,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: IvoryColors.burgundy,
      );
  TextStyle get _soft =>
      TextStyle(color: IvoryColors.textSoft, fontSize: 13.5, height: 1.55);

  Widget _h(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(t, style: _serif),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IvoryColors.ivory,
      appBar: AppBar(
        backgroundColor: IvoryColors.ivory,
        elevation: 0,
        title: Text(
          'privacy, safety & terms',
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontStyle: FontStyle.italic,
            fontSize: 16,
            color: IvoryColors.burgundy,
          ),
        ),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
              children: <Widget>[
                _h('the house rules'),
                Text(
                  'Ivory is a private world, for adults only. Everything '
                  'shared here is adult, consensual and within the law. '
                  'What happens in Ivory stays in Ivory - no recording, '
                  'no screenshots, no sharing, from anyone, including me.',
                  style: _soft,
                ),
                _h('the quiet door'),
                Text(
                  'The house reads everything sent through it, and the '
                  'serious things are dealt with the same day.',
                  style: _soft,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => showReportSheet(context),
                  child: const Text("SOMETHING'S NOT RIGHT?"),
                ),
                _h('refunds - the ticket rule'),
                Text(
                  'A purchase in Ivory is a ticket to a private '
                  'performance. The moment it reaches you, it has been '
                  "performed - so change of mind isn't refundable. But "
                  'three things are always on the house: a ticket that '
                  'never arrived, a double charge, and a show pulled '
                  'before you stepped in. Tell the house within 72 hours '
                  "through the quiet door ('a payment or refund') and "
                  'quote your UPI reference; approved refunds ride back '
                  'to the original method in 5-7 business days.',
                  style: _soft,
                ),
                if (_officerSet) ...<Widget>[
                  _h('the officer'),
                  Text(
                    _pol['officer_name'] ?? '',
                    style: _soft,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri(
                      scheme: 'mailto',
                      path: _pol['officer_email'],
                    )),
                    child: Text(
                      _pol['officer_email'] ?? '',
                      style: TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 13.5,
                        decoration: TextDecoration.underline,
                        decorationColor: IvoryColors.hairline,
                      ),
                    ),
                  ),
                ],
                _h('your data'),
                Text(
                  'Ask for erasure and the house forgets you within 90 '
                  'days - everything, everywhere.',
                  style: _soft,
                ),
                const SizedBox(height: 10),
                if (_note != null) ...<Widget>[
                  Text(_note!, style: _soft),
                  const SizedBox(height: 6),
                ],
                OutlinedButton(
                  onPressed: _busy ? null : _askErasure,
                  child: const Text('ASK FOR ERASURE'),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Text(
                    'Ivory · house manner v1',
                    style: TextStyle(
                      fontSize: 11,
                      color: IvoryColors.textFaint,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// END OF FILE - lib/screens/legal_screen.dart

import 'package:flutter/material.dart';

import '../services/business_enquiry_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/admin_bits.dart';

/// Owner-only view of business notes. Supabase RLS is the actual guard;
/// hiding this tab on member screens is not relied on for security.
class AdminBusinessEnquiriesTab extends StatefulWidget {
  const AdminBusinessEnquiriesTab({super.key});

  @override
  State<AdminBusinessEnquiriesTab> createState() =>
      _AdminBusinessEnquiriesTabState();
}

class _AdminBusinessEnquiriesTabState extends State<AdminBusinessEnquiriesTab> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
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
      final List<Map<String, dynamic>> items =
          await BusinessEnquiryService.instance.fetchForOwner();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'The private enquiry inbox could not be opened. Check that its database setup is applied.';
      });
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final int? id = int.tryParse(item['id'].toString());
    if (id == null || item['status'] == 'read') return;
    try {
      await BusinessEnquiryService.instance.markRead(id);
      if (!mounted) return;
      setState(() => item['status'] = 'read');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this enquiry yet.')),
      );
    }
  }

  String _dateLabel(dynamic raw) {
    final DateTime? date = DateTime.tryParse(raw?.toString() ?? '');
    if (date == null) return 'Date unavailable';
    final DateTime local = date.toLocal();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} · $hour:$minute';
  }

  String _emailLabel(dynamic value) => switch (value?.toString()) {
        'sent' => 'EMAIL ALERT SENT',
        'failed' => 'EMAIL ALERT FAILED',
        'not_configured' => 'IN-APP INBOX ONLY',
        _ => 'EMAIL ALERT PENDING',
      };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 34),
        children: <Widget>[
          const AdminLabel('Business enquiries'),
          const SizedBox(height: 8),
          Text(
            'Private notes from members. Only Ivory can read this inbox.',
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: CircularProgressIndicator(color: IvoryColors.amber),
              ),
            )
          else if (_error != null)
            _emptyCard(Icons.lock_outline_rounded, _error!)
          else if (_items.isEmpty)
            _emptyCard(
              Icons.mark_email_unread_outlined,
              'The private desk is quiet for now. New business notes will appear here.',
            )
          else
            ..._items.map(_enquiryCard),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String message) => Container(
        padding: const EdgeInsets.all(22),
        decoration: IvoryTheme.card(),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 34, color: IvoryColors.amber),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: IvoryColors.textSoft,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      );

  Widget _enquiryCard(Map<String, dynamic> item) {
    final bool unread = item['status'] != 'read';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: IvoryTheme.card(highlighted: unread, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item['display_name']?.toString() ?? 'Ivory member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unread)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _dateLabel(item['created_at']),
            style: TextStyle(color: IvoryColors.textFaint, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          SelectableText(
            item['message']?.toString() ?? '',
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _emailLabel(item['email_status']),
                  style: TextStyle(
                    color: item['email_status'] == 'failed'
                        ? IvoryColors.danger
                        : IvoryColors.textFaint,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (unread)
                TextButton.icon(
                  onPressed: () => _markRead(item),
                  icon: const Icon(Icons.done_rounded, size: 17),
                  label: const Text('MARK READ'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_business_enquiries_tab.dart

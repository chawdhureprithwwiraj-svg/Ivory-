import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../services/notification_service.dart';
import '../services/wish_service.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../theme/ivory_theme.dart';

/// The mobile admin console: send push-style announcements and work
/// through incoming wishes. Every action is re-checked by the database,
/// so a non-admin who reaches this screen can do nothing.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: IvoryColors.burgundy,
          unselectedLabelColor: IvoryColors.textFaint,
          indicatorColor: IvoryColors.amber,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: const <Widget>[
            Tab(text: 'BROADCAST'),
            Tab(text: 'WISHES'),
            Tab(text: 'PAYMENTS'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: const <Widget>[
              _BroadcastTab(),
              _WishTrackerTab(),
              _PaymentsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// BROADCAST
// =====================================================================
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab();

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  String _audience = 'all';
  String _kind = 'system';
  int _tierLevel = 1;
  String? _userId;
  String _userName = '';
  bool _sending = false;

  static const List<String> _kinds = <String>[
    'system',
    'story',
    'audio',
    'video',
    'poll',
    'live',
    'wish',
    'payment',
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickPerson() async {
    final TextEditingController search = TextEditingController();
    List<Map<String, dynamic>> people =
        await NotificationService.instance.searchPeople('');
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(c).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Search by display name',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (String v) async {
                  final List<Map<String, dynamic>> r =
                      await NotificationService.instance.searchPeople(v);
                  setSheet(() => people = r);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (BuildContext _, int i) {
                    final Map<String, dynamic> p = people[i];
                    final String id = p['id'] as String;
                    return ListTile(
                      leading: const Icon(Icons.person_outline,
                          color: IvoryColors.plum),
                      title: Text(
                        (p['display_name'] as String?) ?? 'Anonymous',
                        style: const TextStyle(color: IvoryColors.burgundy),
                      ),
                      subtitle: Text(
                        'ID ${id.substring(0, 8).toUpperCase()}'
                        '${p['role'] == 'admin' ? ' · admin' : ''}',
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _userId = id;
                          _userName =
                              (p['display_name'] as String?) ?? 'that person';
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == 'user' && _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose who this is for first.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await NotificationService.instance.send(
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
        kind: _kind,
        tierLevel: _audience == 'tier' ? _tierLevel : 0,
        userId: _audience == 'user' ? _userId : null,
        actionTab: 'feed',
      );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent. It is in their inbox now.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
        children: <Widget>[
          Text('Send an announcement',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'It lands in the Sanctuary Inbox instantly and lights up the bell. '
            'Device push notifications are wired in the next sprint and will '
            'use these same messages.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: IvoryColors.textSoft,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (String? v) =>
                (v == null || v.trim().length < 3) ? 'Add a title' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _body,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
            validator: (String? v) =>
                (v == null || v.trim().length < 3) ? 'Add a message' : null,
          ),
          const SizedBox(height: 18),
          const Text('WHO SEES IT',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: <Widget>[
              _chip('Everyone', 'all'),
              _chip('A tier and above', 'tier'),
              _chip('One person', 'user'),
            ],
          ),
          if (_audience == 'tier') ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Text('Minimum tier level',
                    style: TextStyle(color: IvoryColors.burgundy)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(
                      () => _tierLevel = _tierLevel > 1 ? _tierLevel - 1 : 1),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: IvoryColors.plum),
                ),
                Text('$_tierLevel',
                    style: const TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    )),
                IconButton(
                  onPressed: () => setState(() => _tierLevel += 1),
                  icon: const Icon(Icons.add_circle_outline,
                      color: IvoryColors.plum),
                ),
              ],
            ),
          ],
          if (_audience == 'user') ...<Widget>[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickPerson,
              icon: const Icon(Icons.person_search, size: 18),
              label: Text(_userId == null ? 'CHOOSE A PERSON' : _userName),
              style: OutlinedButton.styleFrom(
                foregroundColor: IvoryColors.burgundy,
                side: const BorderSide(color: IvoryColors.burgundy),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text('STYLE',
              style: TextStyle(
                color: IvoryColors.plum,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              )),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kinds
                .map((String k) => ChoiceChip(
                      label: Text(k),
                      selected: _kind == k,
                      showCheckmark: false,
                      labelStyle: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _kind = k),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          IvoryGradientButton(
            label: _sending ? 'SENDING...' : 'SEND NOW',
            icon: Icons.campaign,
            busy: _sending,
            onPressed: _sending ? null : _send,
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) => ChoiceChip(
        label: Text(label),
        selected: _audience == value,
        showCheckmark: false,
        labelStyle: const TextStyle(
          color: IvoryColors.burgundy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => setState(() => _audience = value),
      );
}

// =====================================================================
// WISH TRACKER
// =====================================================================
class _WishTrackerTab extends StatefulWidget {
  const _WishTrackerTab();

  @override
  State<_WishTrackerTab> createState() => _WishTrackerTabState();
}

class _WishTrackerTabState extends State<_WishTrackerTab> {
  List<Wish> _wishes = <Wish>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<Wish> w = await WishService.instance.fetchAllWishes();
      if (!mounted) return;
      setState(() {
        _wishes = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _edit(Wish w) async {
    final TextEditingController reply =
        TextEditingController(text: w.adminReply ?? '');
    final TextEditingController link =
        TextEditingController(text: w.deliveryUrl ?? '');
    String status = w.status;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext c, StateSetter setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(c).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(w.title,
                  style: Theme.of(c).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '${w.categoryName} · ₹${w.budgetInr} · '
                '${w.requesterName ?? "someone"}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: IvoryColors.textSoft,
                ),
              ),
              const SizedBox(height: 12),
              Text(w.details,
                  style: const TextStyle(
                      color: IvoryColors.burgundy, fontSize: 14, height: 1.5)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Wish.allStatuses
                    .map((String s) => ChoiceChip(
                          label: Text(s.replaceAll('_', ' ')),
                          selected: status == s,
                          showCheckmark: false,
                          labelStyle: const TextStyle(
                              color: IvoryColors.burgundy, fontSize: 12.5),
                          onSelected: (_) => setSheet(() => status = s),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reply,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reply to them',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: link,
                decoration: const InputDecoration(
                  labelText: 'Delivery link (optional)',
                  hintText: 'https://t.me/... or any link',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await WishService.instance.updateStatus(
                      wishId: w.id,
                      status: status,
                      adminReply: reply.text.trim(),
                      deliveryUrl:
                          link.text.trim().isEmpty ? null : link.text.trim(),
                    );
                    if (!c.mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('SAVE & NOTIFY THEM'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: IvoryColors.burgundy));
    }
    if (_wishes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'No wishes yet. When someone makes one, it appears here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: IvoryColors.textSoft,
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        itemCount: _wishes.length,
        itemBuilder: (BuildContext c, int i) {
          final Wish w = _wishes[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _edit(w),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: IvoryTheme.card(radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              w.title,
                              style: const TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: IvoryColors.goldGradient,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              w.statusLabel.toUpperCase(),
                              style: const TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${w.categoryName} · ₹${w.budgetInr} · '
                        '${w.requesterName ?? "someone"}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: IvoryColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


// ================

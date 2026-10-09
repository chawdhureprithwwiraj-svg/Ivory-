import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../services/wish_service.dart';
import '../theme/ivory_insets.dart';
import '../theme/ivory_theme.dart';

// =====================================================================
// WISH TRACKER
// =====================================================================
class AdminWishesTab extends StatefulWidget {
  const AdminWishesTab({super.key});

  @override
  State<AdminWishesTab> createState() => _AdminWishesTabState();
}

class _AdminWishesTabState extends State<AdminWishesTab> {
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
            bottom: ivorySheetFoot(c, extra: 18),
          ),
          // With the keyboard up this sheet is taller than the
          // screen, so it must be able to scroll or the button
          // is unreachable for a second reason.
          child: SingleChildScrollView(
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
// END OF FILE - lib/screens/admin_wishes_tab.dart

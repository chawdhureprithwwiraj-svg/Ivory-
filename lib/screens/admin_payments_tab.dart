import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';
import '../theme/ivory_theme.dart';
// =====================================================================
// PAYMENTS - verify UPI transfers by hand
// =====================================================================
class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key});

  @override
  State<AdminPaymentsTab> createState() => AdminPaymentsTabState();
}

class AdminPaymentsTabState extends State<AdminPaymentsTab> {
  final TextEditingController _upi = TextEditingController();
  final TextEditingController _payee = TextEditingController();

  List<IvoryPayment> _payments = <IvoryPayment>[];
  PaymentSettings? _settings;
  bool _loading = true;
  bool _savingSettings = false;
  int? _busyId;
  String _filter = 'pending';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _upi.dispose();
    _payee.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final PaymentSettings s = await PaymentService.instance.fetchSettings();
      final List<IvoryPayment> rows = await PaymentService.instance
          .fetchAllPayments(status: _filter == 'all' ? null : _filter);
      if (!mounted) return;
      setState(() {
        _settings = s;
        if (_upi.text.isEmpty) _upi.text = s.upiId;
        if (_payee.text.isEmpty) _payee.text = s.payeeName;
        _payments = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load payments. Pull down to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _savingSettings = true);
    try {
      await PaymentService.instance.updateSettings(
        upiId: _upi.text,
        payeeName: _payee.text,
      );
      if (!mounted) return;
      _snack('UPI details saved.');
      await _load();
    } catch (_) {
      if (mounted) _snack('Could not save. Are you signed in as admin?');
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  Future<void> _approve(IvoryPayment p) async {
    setState(() => _busyId = p.id);
    try {
      await PaymentService.instance.approve(p.id);
      if (mounted) _snack('Approved. ${p.tierName ?? 'The tier'} is unlocked.');
      await _load();
    } catch (_) {
      if (mounted) _snack('Could not approve that payment.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reject(IvoryPayment p) async {
    final TextEditingController reason = TextEditingController();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: IvoryColors.surface,
        title: const Text('Reject this payment?'),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(
            labelText: 'Reason (the member sees this)',
          ),
          maxLines: 2,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (go != true) return;
    setState(() => _busyId = p.id);
    try {
      await PaymentService.instance.reject(
        p.id,
        reason.text.trim().isEmpty ? null : reason.text.trim(),
      );
      await _load();
    } catch (_) {
      if (mounted) _snack('Could not reject that payment.');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openProof(IvoryPayment p) async {
    final String? path = p.screenshotUrl;
    if (path == null || path.isEmpty) return;
    final String? url = await PaymentService.instance.signedProofUrl(path);
    if (!mounted) return;
    if (url == null) {
      _snack('Could not open that screenshot.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: IvoryColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('The screenshot could not be loaded.'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: IvoryColors.burgundy,
      backgroundColor: IvoryColors.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
        children: <Widget>[
          _settingsCard(),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const IvoryEyebrow('Payments', icon: Icons.payments_outlined),
              const Spacer(),
              DropdownButton<String>(
                value: _filter,
                underline: const SizedBox.shrink(),
                dropdownColor: IvoryColors.surface,
                style: const TextStyle(
                  color: IvoryColors.burgundy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                      value: 'pending', child: Text('Pending')),
                  DropdownMenuItem<String>(
                      value: 'approved', child: Text('Approved')),
                  DropdownMenuItem<String>(
                      value: 'rejected', child: Text('Rejected')),
                  DropdownMenuItem<String>(value: 'all', child: Text('All')),
                ],
                onChanged: (String? v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  _load();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: IvoryColors.burgundy),
              ),
            )
          else if (_error != null)
            Text(_error!,
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13))
          else if (_payments.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: IvoryTheme.card(),
              child: Text(
                _filter == 'pending'
                    ? 'Nothing is waiting for you. Every payment has been settled.'
                    : 'No payments here yet.',
                style: TextStyle(
                  color: IvoryColors.textSoft,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            )
          else
            ..._payments.map(_paymentCard),
        ],
      ),
    );
  }

  Widget _settingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: IvoryTheme.card(highlighted: true, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IvoryEyebrow('Where the money goes',
              icon: Icons.account_balance_outlined),
          const SizedBox(height: 12),
          TextField(
            controller: _upi,
            decoration: const InputDecoration(
              labelText: 'Your UPI ID',
              hintText: 'yourname@okhdfcbank',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payee,
            decoration: const InputDecoration(labelText: 'Payee name'),
          ),
          const SizedBox(height: 8),
          Text(
            _settings?.isConfigured == true
                ? 'Members are paying to ${_settings!.upiId}.'
                : 'Set a real UPI id - checkout stays disabled until you do.',
            style: TextStyle(
              color: _settings?.isConfigured == true
                  ? IvoryColors.textFaint
                  : IvoryColors.danger,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          IvoryGradientButton(
            label: 'SAVE UPI DETAILS',
            icon: Icons.save_outlined,
            busy: _savingSettings,
            onPressed: _savingSettings ? null : _saveSettings,
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(IvoryPayment p) {
    final bool busy = _busyId == p.id;
    final Color tone = p.isApproved
        ? IvoryColors.success
        : (p.isPending ? IvoryColors.amber : IvoryColors.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: IvoryTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '₹${p.amountInr} · ${p.tierName ?? 'Membership'}',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: tone.withValues(alpha: 0.6)),
                ),
                child: Text(
                  p.statusLabel.toUpperCase(),
                  style: TextStyle(
                    color: tone,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'UTR ${p.utr}',
            style: const TextStyle(
              color: IvoryColors.plum,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.payerName ?? 'A member'}'
            '${p.createdAt == null ? '' : ' · ${p.createdAt!.toLocal()}'.split('.').first}',
            style: TextStyle(color: IvoryColors.textFaint, fontSize: 12),
          ),
          if (p.adminNote != null && p.adminNote!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Note: ${p.adminNote}',
              style: TextStyle(color: IvoryColors.textSoft, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              if (p.screenshotUrl != null && p.screenshotUrl!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => _openProof(p),
                  icon: const Icon(Icons.image_outlined, size: 16),
                  label: const Text('PROOF'),
                ),
              if (p.screenshotUrl != null && p.screenshotUrl!.isNotEmpty)
                const SizedBox(width: 10),
              if (p.isPending) ...<Widget>[
                Expanded(
                  child: IvoryGradientButton(
                    label: 'APPROVE',
                    icon: Icons.check_rounded,
                    busy: busy,
                    onPressed: busy ? null : () => _approve(p),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: busy ? null : () => _reject(p),
                  child: const Text('REJECT'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

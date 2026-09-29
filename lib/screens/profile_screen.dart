import 'package:flutter/material.dart';

import '../models/ivory_profile.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../theme/ivory_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onOpenTab});

  final void Function(String tab)? onOpenTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  IvoryProfile? _profile;
  Membership? _membership;
  List<IvoryPayment> _payments = <IvoryPayment>[];
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
      final IvoryProfile? p = await AuthService.instance.loadProfile();
      await PaymentService.instance.expireOld();
      Membership? m;
      List<IvoryPayment> pays = <IvoryPayment>[];
      try {
        m = await PaymentService.instance.fetchMembership();
        pays = await PaymentService.instance.fetchMyPayments();
      } catch (_) {
        // A member with no payment history is not an error.
      }
      if (!mounted) return;
      setState(() {
        _profile = p;
        _membership = m;
        _payments = pays;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AuthService.friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final IvoryProfile? p = _profile;
    final String initial = (p?.displayName.trim().isNotEmpty ?? false)
        ? p!.displayName.trim().substring(0, 1).toUpperCase()
        : 'I';

    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 40),
          children: <Widget>[
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 70),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.amber),
                ),
              )
            else ...<Widget>[
              // ---- identity card ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: IvoryTheme.card(highlighted: true, radius: 24),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: IvoryColors.goldGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: IvoryTheme.softShadow(blur: 12, y: 5),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                color: IvoryColors.burgundy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                p?.displayName ?? 'Signed in',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                p == null ? '—' : 'ID ${p.shortId}',
                                style: TextStyle(
                                  color: IvoryColors.textFaint,
                                  fontSize: 12.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (p?.isAdmin ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: IvoryColors.goldGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                color: IvoryColors.burgundy,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Divider(color: IvoryColors.hairline, height: 30),
                    _line(Icons.check_circle, IvoryColors.success,
                        'Connected to Supabase. Profile loaded.'),
                    const SizedBox(height: 10),
                    _line(Icons.shield_outlined, IvoryColors.plum,
                        'No phone number stored. You are a UUID here.'),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      _line(Icons.error_outline, IvoryColors.danger, _error!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- membership ----
              Container(
                padding: const EdgeInsets.all(20),
                decoration: IvoryTheme.card(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const IvoryEyebrow('Your membership',
                        icon: Icons.diamond_outlined),
                    const SizedBox(height: 12),
                    Text(
                      _membership?.tierName ?? 'Free Guest',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _membership == null
                          ? 'The open feed, polls and teasers. Unlock a tier '
                              'to open the private rooms.'
                          : '${_membership!.daysLeft} days remaining. '
                              'Everything at this level is open to you.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    IvoryGradientButton(
                      label: _membership == null
                          ? 'SEE MEMBERSHIP TIERS'
                          : 'MANAGE OR RENEW',
                      icon: Icons.workspace_premium_outlined,
                      onPressed: () => widget.onOpenTab?.call('premium'),
                    ),
                    if (_payments.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      const IvoryEyebrow('Payment history',
                          icon: Icons.receipt_long_outlined),
                      const SizedBox(height: 10),
                      ..._payments.take(4).map(_paymentRow),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ---- shortcuts ----
              _row(Icons.auto_awesome, 'Your wishes',
                  () => widget.onOpenTab?.call('wish')),
              _row(Icons.mail_outline, 'Sanctuary Inbox',
                  () => widget.onOpenTab?.call('inbox')),

              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () async {
                  await NotificationService.instance.stop();
                  await PushService.instance.stop();
                  await AuthService.instance.signOut();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('SIGN OUT'),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Ivory · Every story leaves a mark',
                  style:
                      TextStyle(fontSize: 12, color: IvoryColors.textFaint),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(IvoryPayment p) {
    final Color tone = p.isApproved
        ? IvoryColors.success
        : (p.isPending ? IvoryColors.amber : IvoryColors.danger);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '₹${p.amountInr} · ${p.tierName ?? 'Membership'}',
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            p.statusLabel,
            style: TextStyle(
              color: tone,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: IvoryTheme.card(radius: 18),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 20, color: IvoryColors.plum),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: IvoryColors.plum),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _line(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: IvoryColors.textSoft,
                fontSize: 13.8,
                height: 1.42,
              ),
            ),
          ),
        ],
      );
}

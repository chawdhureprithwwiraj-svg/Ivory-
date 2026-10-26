import 'package:flutter/material.dart';

import '../models/ivory_profile.dart';
import '../services/line_service.dart';
import '../widgets/owner_house_card.dart';
import 'legal_screen.dart';
import '../models/payment.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/push_refused_note.dart';
import '../widgets/sessions_panel.dart';
import '../widgets/vault_skin.dart';
import '../widgets/member_pulse.dart';
import '../widgets/premium_badge.dart';
import '../widgets/report_sheet.dart';
import '../widgets/profile_photo_editor.dart';
import '../widgets/profile_folio_card.dart';
import '../widgets/profile_treasures_card.dart';
import '../widgets/language_row.dart';
import '../widgets/profile_wish_shortcut.dart';
import 'private_folio_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onOpenTab, this.onOpenCall});

  final void Function(String tab)? onOpenTab;
  final ValueChanged<int>? onOpenCall;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  IvoryProfile? _profile;
  Map<String, dynamic>? _free;
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
      LineService.instance.refresh();
      LineService.instance.freeState().then((Map<String, dynamic>? m) {
        if (mounted) setState(() => _free = m);
      });
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
            const PushRefusedNote(),
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
                decoration: (_membership?.tierLevel ?? 0) > 0 && !(p?.isAdmin ?? false)
                    ? IvoryTheme.card(highlighted: true, radius: 24)
                        .copyWith(border: Border.all(color: const Color(0xFFE8C86A), width: 1.6))
                    : IvoryTheme.card(highlighted: true, radius: 24),
                child: Column(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        ProfilePhotoEditor(
                          displayName: p?.displayName ?? initial,
                          avatarPath: p?.avatarPath,
                          legacyAvatarUrl: p?.avatarUrl,
                          isActivePaidMember: !(p?.isAdmin ?? false) &&
                              (_membership?.tierLevel ?? 0) > 0,
                          onPathChanged: (String? path) {
                            if (p == null) return;
                            setState(() => _profile = p.withAvatarPath(path));
                          },
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                p?.displayName ?? 'Signed in',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 20, height: 1.15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if ((p?.isAdmin ?? false) ||
                        (_membership?.tierLevel ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: (p?.isAdmin ?? false)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
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
                                )
                              : PremiumBadge.chip(
                                  tierName: _membership!.tierName,
                                  level: _membership!.tierLevel,
                                ),
                        ),
                      ),
                    Divider(color: IvoryColors.hairline, height: 30),
                    // Members see who they are. The technical diagnostics
                    // below are for the administrator only.
                    _line(Icons.alternate_email, IvoryColors.plum,
                        AuthService.instance.currentUser?.email ??
                            'Signed in privately'),
                    const SizedBox(height: 10),
                    _line(
                      Icons.workspace_premium_outlined,
                      IvoryColors.gold,
                      (p?.isAdmin ?? false)
                          ? 'Every tier, every room, always open'
                          : _membership == null
                              ? 'Forever Ivory Member \u00b7 no paid tier active yet'
                              : '${_membership!.tierName} \u00b7 '
                                  '${_membership!.daysLeft == 1 ? "1 day" : "${_membership!.daysLeft} days"} remaining',
                    ),
                    if (p?.isAdmin ?? false) ...<Widget>[
                      const SizedBox(height: 10),
                      _line(Icons.shield_outlined, IvoryColors.plum,
                          'Phone and birthday details stay separate from public profile data.'),
                    ],
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 10),
                      _line(Icons.error_outline, IvoryColors.danger, _error!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- membership ----
              // Owner: her house, not a shop. Paid: the Vault. Forever cream.
              if (p?.isAdmin ?? false)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: IvoryTheme.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const IvoryEyebrow('The house', icon: Icons.vpn_key_outlined),
                      const SizedBox(height: 12),
                      const OwnerHouseCard(),
                      if (_payments.isNotEmpty) _payRows(),
                    ],
                  ),
                )
              else if ((_membership?.tierLevel ?? 0) > 0) ...<Widget>[
                VaultMembershipCard(tierName: _membership!.tierName,
                    daysLeft: _membership!.daysLeft,
                    onManage: () => widget.onOpenTab?.call('premium')),
                if (_payments.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(20),
                    decoration: IvoryTheme.card(),
                    child: _payRows(lead: false)),
              ]
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: IvoryTheme.card(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const IvoryEyebrow('Your membership', icon: Icons.diamond_outlined),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text('Forever Ivory Member',
                              style: Theme.of(context).textTheme.titleLarge),
                          ForeverMemberChip(onTap: () => widget.onOpenTab?.call('premium')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('The open feed, polls and teasers. Unlock a tier to open the private rooms.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      IvoryGradientButton(label: 'SEE MEMBERSHIP TIERS',
                          icon: Icons.workspace_premium_outlined,
                          onPressed: () => widget.onOpenTab?.call('premium')),
                      if (_payments.isNotEmpty) _payRows(),
                    ],
                  ),
                ),
              _wornLine(p),
              const SizedBox(height: 14),

              // ---- shortcuts ----
              SessionsCard(onOpenTab: widget.onOpenTab),
              if (p?.isAdmin ?? false)
                _row(Icons.auto_awesome, 'Your wishes',
                    () => widget.onOpenTab?.call('wish'))
              else
                // Its row arrives a moment after the page; the space
                // is kept for it so the scroll never jumps.
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 76),
                  child: ProfileWishShortcut(
                    onOpenWish: () => widget.onOpenTab?.call('wish'),
                    onOpenScheduledCall: widget.onOpenCall,
                  ),
                ),
              ProfileFolioCard(
                onOpen: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivateFolioScreen(),
                  ),
                ),
              ),
              const ProfileTreasuresCard(),
              const ProfileLanguageRow(),

              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () => showReportSheet(context,
                          onOpenTab: widget.onOpenTab),
                      child: Text(
                        "something's not right?",
                        style: TextStyle(
                          fontSize: 12,
                          color: IvoryColors.textFaint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LegalScreen(),
                        ),
                      ),
                      child: Text(
                        'privacy, safety & terms',
                        style: TextStyle(
                          fontSize: 12,
                          color: IvoryColors.textFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Center(child: MemberPulseStrip(compact: true)),

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
                  'Ivory · Where every story leaves a mark',
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

  /// CC.220 - THE WORN LINE: the profile wears the member's place
  /// in the Line, so status is visible on the one screen members
  /// show each other.
  Widget _wornLine(IvoryProfile? p) {
    final LineState? ls = LineService.instance.state.value;
    if (ls == null) return const SizedBox.shrink();
    String txt;
    IconData ic = Icons.drafts_outlined;
    if (p?.isAdmin ?? false) {
      txt = 'The Line is yours to answer - every sealed letter waits on your desk.';
      ic = Icons.mark_email_read_outlined;
    } else if (ls.paid) {
      txt = 'In the Line - every letter of yours is answered, in order.';
      ic = Icons.mark_email_read_outlined;
    } else if (_free != null && _free!['position'] != null) {
      txt = 'Holds a sealed letter - number ${_free!['position']} in the Line.';
      ic = Icons.mail_outline;
    } else {
      txt = 'The Line is open to you: seal a letter and stand in the queue.';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: <Widget>[
          Icon(ic, size: 16, color: IvoryColors.plum.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              txt,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: IvoryColors.plum.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRows({bool lead = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (lead) const SizedBox(height: 18),
        const IvoryEyebrow('Payment history', icon: Icons.receipt_long_outlined),
        const SizedBox(height: 10),
        ..._payments.take(4).map(_paymentRow),
      ],
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

// END OF FILE - lib/screens/profile_screen.dart

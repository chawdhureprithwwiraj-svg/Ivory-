import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'admin_broadcast_tab.dart';
import 'admin_business_enquiries_tab.dart';
import 'admin_calls_tab.dart';
import 'admin_gold_tab.dart';
import 'admin_heart_tab.dart';
import 'admin_codes_tab.dart';
import 'admin_bells_tab.dart';
import 'admin_ladder_tab.dart';
import 'admin_early_tab.dart';
import 'admin_i18n_tab.dart';
import 'admin_line_tab.dart';
import 'admin_rewards_tab.dart';
import 'admin_live_tab.dart';
import 'admin_members_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_create_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_tiers_tab.dart';
import 'admin_wishes_tab.dart';
import 'admin_stories_tab.dart';

/// The mobile admin console. Every action is re-checked by the database,
/// so a member who somehow reaches this screen can do nothing.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 20,
    initialIndex: widget.initialTab,
    vsync: this,
  );

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
          tabAlignment: TabAlignment.start,
          tabs: const <Widget>[
            Tab(text: 'CREATE'),
            Tab(text: 'MEMBERS'),
            Tab(text: 'REPORTS'),
            Tab(text: 'CALLS'),
            Tab(text: 'LIVE'),
            Tab(text: 'BROADCAST'),
            Tab(text: 'TIERS'),
            Tab(text: 'WISHES'),
            Tab(text: 'STORIES'),
            Tab(text: 'PAYMENTS'),
            Tab(text: 'ENQUIRIES'),
            Tab(text: 'GOLD'),
            Tab(text: 'HEART'),
            Tab(text: 'REWARDS'),
            Tab(text: 'CODES'),
            Tab(text: 'BELLS'),
            Tab(text: 'LADDER'),
            Tab(text: 'DOOR'),
            Tab(text: 'LINE'),
            Tab(text: 'TRANSLATE'),
          ],
        ),
      ),
      body: Theme(
        // Every switch in Admin: a plain burgundy track when ON and a
        // soft one when OFF (the default looked greyed-out when ON).
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> st) => st.contains(WidgetState.selected)
                  ? IvoryColors.cream
                  : IvoryColors.plum,
            ),
            trackColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> st) => st.contains(WidgetState.selected)
                  ? IvoryColors.burgundy
                  : const Color(0xFFEBDDD2),
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> st) => st.contains(WidgetState.selected)
                  ? IvoryColors.burgundy
                  : IvoryColors.plum.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: const <Widget>[
              AdminCreateTab(),
              AdminMembersTab(),
              AdminReportsTab(),
              AdminCallsTab(),
              AdminLiveTab(),
              AdminBroadcastTab(),
              AdminTiersTab(),
              AdminWishesTab(),
              AdminStoriesTab(),
              AdminPaymentsTab(),
              AdminBusinessEnquiriesTab(),
              AdminGoldTab(),
              AdminHeartTab(),
              AdminRewardsTab(),
              AdminCodesTab(),
              AdminBellsTab(),
              AdminLadderTab(),
              AdminEarlyTab(),
              AdminLineTab(),
              AdminI18nTab(),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_screen.dart

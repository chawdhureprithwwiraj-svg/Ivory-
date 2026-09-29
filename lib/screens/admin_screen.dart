import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'admin_broadcast_tab.dart';
import 'admin_create_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_tiers_tab.dart';
import 'admin_wishes_tab.dart';

/// The mobile admin console. Every action is re-checked by the database,
/// so a member who somehow reaches this screen can do nothing.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);

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
            Tab(text: 'BROADCAST'),
            Tab(text: 'TIERS'),
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
              AdminCreateTab(),
              AdminBroadcastTab(),
              AdminTiersTab(),
              AdminWishesTab(),
              AdminPaymentsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_screen.dart

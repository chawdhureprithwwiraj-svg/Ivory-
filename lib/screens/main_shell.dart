import 'package:flutter/material.dart';

import '../models/ivory_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/push_service.dart';
import '../theme/ivory_theme.dart';
import 'admin_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'inbox_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';
import 'wish_screen.dart';

/// The signed-in container.
/// Home · Explore · Wish · Premium · Inbox · Profile,
/// with a live unread badge and an admin crown for the owner.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  IvoryProfile? _profile;

  /// Tab names used by notifications and in-app shortcuts.
  static const List<String> _tabKeys = <String>[
    'home',
    'explore',
    'wish',
    'premium',
    'inbox',
    'profile',
  ];

  static const List<String> _titles = <String>[
    'IVORY',
    'EXPLORE',
    'THE WISH',
    'MEMBERSHIP',
    'INBOX',
    'PROFILE',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    NotificationService.instance.start();
    PushService.instance.start();
  }

  Future<void> _loadProfile() async {
    try {
      final IvoryProfile? p = await AuthService.instance.loadProfile();
      if (!mounted) return;
      setState(() => _profile = p);
    } catch (_) {
      // The app still works without it; the Profile tab retries.
    }
  }

  bool get _isAdmin => _profile?.isAdmin ?? false;

  /// Notifications say 'feed', older links may too - treat it as Home.
  void _openTab(String name) {
    final String key = name == 'feed' ? 'home' : name;
    final int i = _tabKeys.indexOf(key);
    if (i >= 0) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      HomeScreen(onOpenTab: _openTab),
      const ExploreScreen(),
      WishScreen(onOpenTab: _openTab),
      const PremiumScreen(),
      InboxScreen(onOpenTab: _openTab),
      ProfileScreen(onOpenTab: _openTab),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: <Widget>[
            Text(_titles[_index]),
            if (_isAdmin) ...<Widget>[
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: <Widget>[
          _BellButton(onTap: () => _openTab('inbox')),
          if (_isAdmin)
            IconButton(
              tooltip: 'Admin console',
              icon: const Icon(Icons.workspace_premium),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
              ),
            ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await NotificationService.instance.stop();
              await PushService.instance.stop();
              await AuthService.instance.signOut();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: IvoryColors.hairline)),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: NotificationService.instance.unreadCount,
          builder: (BuildContext context, int unread, _) {
            return BottomNavigationBar(
              currentIndex: _index,
              type: BottomNavigationBarType.fixed,
              onTap: (int i) => setState(() => _index = i),
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.explore_outlined),
                  activeIcon: Icon(Icons.explore),
                  label: 'Explore',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome),
                  label: 'Wish',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.diamond_outlined),
                  activeIcon: Icon(Icons.diamond),
                  label: 'Premium',
                ),
                BottomNavigationBarItem(
                  icon: _Badged(
                      count: unread, child: const Icon(Icons.mail_outline)),
                  activeIcon:
                      _Badged(count: unread, child: const Icon(Icons.mail)),
                  label: 'Inbox',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (BuildContext context, int unread, _) => IconButton(
        tooltip: 'Notifications',
        onPressed: onTap,
        icon: _Badged(
          count: unread,
          child: const Icon(Icons.notifications_none),
        ),
      ),
    );
  }
}

/// A small gold badge with a number, used on the bell and the Inbox tab.
class _Badged extends StatelessWidget {
  const _Badged({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          right: -7,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 17),
            decoration: BoxDecoration(
              gradient: IvoryColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: IvoryColors.surface, width: 1.2),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// END OF FILE - lib/screens/main_shell.dart

import 'package:flutter/material.dart';

import '../models/ivory_profile.dart';
import '../services/auth_service.dart';
import '../theme/ivory_theme.dart';

/// Temporary home shown after signing in. It proves the whole backend
/// round-trip works: auth session -> profiles row -> role.
/// Sprint 3 replaces this with the real storytelling feed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IvoryProfile? _profile;
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
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = AuthService.friendlyError(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IVORY'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: IvoryColors.gold),
            onPressed: () => AuthService.instance.signOut(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: IvoryColors.burgundy,
            backgroundColor: IvoryColors.cream,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: <Widget>[
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: IvoryColors.burgundy,
                      ),
                    ),
                  )
                else if (_error != null)
                  _ErrorCard(message: _error!, onRetry: _load)
                else
                  _ProfileCard(profile: _profile),
                const SizedBox(height: 22),
                const _RoadmapCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final IvoryProfile? profile;

  @override
  Widget build(BuildContext context) {
    final IvoryProfile? p = profile;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: IvoryTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (p?.displayName.isNotEmpty ?? false)
                        ? p!.displayName.characters.first.toUpperCase()
                        : 'I',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: IvoryColors.burgundy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      p?.displayName ?? 'Signed in',
                      style: const TextStyle(
                        color: IvoryColors.ivory,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      p == null ? 'Profile loading…' : 'ID ${p.shortId}',
                      style: TextStyle(
                        color: IvoryColors.ivory.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              if (p?.isAdmin ?? false)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: IvoryColors.burgundy,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: IvoryColors.gold.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 16),
          const Row(
            children: <Widget>[
              Icon(Icons.check_circle, size: 18, color: IvoryColors.amber),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Connected to Supabase. Your profile loaded successfully.',
                  style: TextStyle(
                    color: IvoryColors.ivory,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Icon(Icons.shield_outlined,
                  size: 18, color: IvoryColors.peach),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No phone number stored. You are identified by UUID only.',
                  style: TextStyle(
                    color: IvoryColors.ivory.withValues(alpha: 0.75),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: IvoryColors.peach, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'COULD NOT LOAD PROFILE',
            style: TextStyle(
              color: IvoryColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: IvoryColors.ivory,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('RETRY')),
        ],
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard();

  @override
  Widget build(BuildContext context) {
    const List<List<Object>> items = <List<Object>>[
      <Object>['GitHub repository + auto APK builds', true],
      <Object>['Ivory design system locked in', true],
      <Object>['Supabase backend & authentication', true],
      <Object>['Community storytelling feed', false],
      <Object>['Premium tiers & UPI payments', false],
      <Object>['Agora live streaming & 1-on-1 calls', false],
      <Object>['Mobile admin dashboard', false],
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: IvoryTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'BUILD ROADMAP',
            style: TextStyle(
              color: IvoryColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((List<Object> row) {
            final String label = row[0] as String;
            final bool done = row[1] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    done ? Icons.check_circle : Icons.lock_outline,
                    size: 19,
                    color: done ? IvoryColors.amber : IvoryColors.peach,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: done
                            ? IvoryColors.ivory
                            : IvoryColors.ivory.withValues(alpha: 0.6),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

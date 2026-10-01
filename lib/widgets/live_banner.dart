import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/live_screen.dart';
import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - "LIVE NOW"
///
/// Nothing at all when nobody is broadcasting. The moment a session
/// starts, this appears at the top of Home by itself - the realtime
/// subscription pushes it, nobody has to pull to refresh.
///
/// A member who is not entitled still sees the banner: it is the shop
/// window. Tapping it tells them, in one warm sentence, what the
/// session is included with. The channel name is never in their hands.
/// ============================================================
class LiveBanner extends StatefulWidget {
  const LiveBanner({super.key});

  @override
  State<LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<LiveBanner>
    with SingleTickerProviderStateMixin {
  LiveSession? _session;
  RealtimeChannel? _channel;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _load();
    _channel = LiveService.instance.watchSessions(_load);
  }

  Future<void> _load() async {
    try {
      final LiveSession? s = await LiveService.instance.fetchOnAir();
      if (!mounted) return;
      setState(() => _session = s);
    } catch (_) {
      // Live is a bonus on Home; never let it break the feed.
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    final RealtimeChannel? c = _channel;
    if (c != null) LiveService.instance.stopWatching(c);
    super.dispose();
  }

  Future<void> _open() async {
    final LiveSession? s = _session;
    if (s == null) return;

    if (!s.isEntitled) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _LockedSheet(session: s),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveScreen(
          sessionId: s.id,
          title: s.title,
          subtitle: s.subtitle,
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final LiveSession? s = _session;
    if (s == null || !s.isLive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            gradient: IvoryColors.goldGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: IvoryTheme.softShadow(blur: 20, y: 7),
          ),
          child: Row(
            children: <Widget>[
              FadeTransition(
                opacity: _pulse,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: IvoryColors.burgundy,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'LIVE NOW',
                      style: TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (s.viewerCount > 0) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        s.viewerCount == 1
                            ? '1 member watching'
                            : '${s.viewerCount} members watching',
                        style: TextStyle(
                          color: IvoryColors.burgundy.withValues(alpha: 0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  s.isEntitled ? 'JOIN' : 'DETAILS',
                  style: const TextStyle(
                    color: IvoryColors.cream,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a member who is not entitled sees. Warm, never a rejection.
class _LockedSheet extends StatelessWidget {
  const _LockedSheet({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
      decoration: const BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: IvoryColors.gold,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: IvoryTheme.softShadow(blur: 16, y: 6),
              ),
              child: const Icon(Icons.videocam_rounded,
                  color: IvoryColors.burgundy, size: 29),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              session.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              session.isPayPerView
                  ? 'This session is Rs.${session.priceInr} to join.'
                  : 'Live sessions are part of the '
                      '${session.tierName ?? 'premium'} membership.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: IvoryColors.textSoft,
              ),
            ),
          ),
          const SizedBox(height: 22),
          IvoryGradientButton(
            label: 'SEE THE PLANS',
            icon: Icons.diamond_outlined,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_banner.dart

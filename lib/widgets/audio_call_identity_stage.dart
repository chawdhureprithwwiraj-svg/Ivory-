import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/call_audio_identity.dart';
import '../services/call_audio_identity_service.dart';
import '../theme/ivory_theme.dart';
import 'admin_call_royal_avatar.dart';
import 'member_avatar.dart';
import 'premium_badge.dart';

/// The two identities shown together on both sides of an audio-only call.
/// Only the admin tile uses the royal artwork; the member's existing avatar
/// frame is still controlled by the active-paid tier passed from the call.
class AudioCallIdentityStage extends StatefulWidget {
  const AudioCallIdentityStage({
    super.key,
    required this.callId,
    required this.memberDisplayName,
    required this.heading,
    required this.memberTierLevel,
    this.memberTierName,
    this.subtitle,
    this.pulse = false,
  });

  final int callId;
  final String memberDisplayName;
  final String heading;
  final String? subtitle;
  final int memberTierLevel;
  final String? memberTierName;
  final bool pulse;

  @override
  State<AudioCallIdentityStage> createState() =>
      _AudioCallIdentityStageState();
}

class _AudioCallIdentityStageState extends State<AudioCallIdentityStage>
    with SingleTickerProviderStateMixin {
  static const Duration _refreshEvery = Duration(minutes: 8);

  List<CallAudioIdentity> _identities = const <CallAudioIdentity>[];
  late final AnimationController _breath;
  Timer? _refreshTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    unawaited(_loadIdentities());
    _refreshTimer = Timer.periodic(_refreshEvery, (_) {
      unawaited(_loadIdentities());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncBreath();
  }

  @override
  void didUpdateWidget(covariant AudioCallIdentityStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.callId != widget.callId) unawaited(_loadIdentities());
    if (oldWidget.pulse != widget.pulse) _syncBreath();
  }

  void _syncBreath() {
    if (!widget.pulse || MediaQuery.of(context).disableAnimations) {
      if (_breath.isAnimating) _breath.stop();
      _breath.value = 0;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  Future<void> _loadIdentities() async {
    if (_loading) return;
    _loading = true;
    try {
      final List<CallAudioIdentity> people =
          await CallAudioIdentityService.instance.forAudioCall(widget.callId);
      if (mounted) setState(() => _identities = people);
    } catch (_) {
      // Preserve the initials/photo already on screen if a refresh fails.
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _breath.dispose();
    super.dispose();
  }

  CallAudioIdentity? get _admin {
    for (final CallAudioIdentity person in _identities) {
      if (person.isAdmin) return person;
    }
    return null;
  }

  CallAudioIdentity? get _member {
    for (final CallAudioIdentity person in _identities) {
      if (!person.isAdmin) return person;
    }
    return null;
  }

  Widget _memberPortrait({required double baseSize, required String name}) {
    final bool hasPremiumTier = widget.memberTierLevel > 0;
    return MemberAvatar(
      displayName: name,
      imageUrl: _member?.imageUrl,
      size: hasPremiumTier ? baseSize * 1.05 : baseSize * 0.62,
      premiumFrame: hasPremiumTier,
    );
  }

  Widget _nameLabel(String name, double width) => SizedBox(
        width: width,
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: IvoryColors.cream,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bool motionOff = MediaQuery.of(context).disableAnimations;
    final String adminName = _admin?.displayName ?? 'Ivory';
    final String memberName = _member?.displayName ??
        (widget.memberDisplayName.trim().isEmpty
            ? 'A member'
            : widget.memberDisplayName.trim());

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 360;
        final double baseSize =
            math.min(134.0, availableWidth * 0.33).toDouble();
        // Room for the royal frame's diagonal sweep, without clipping a crown.
        final double tileWidth = baseSize * 1.45;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedBuilder(
                animation: _breath,
                builder: (BuildContext context, Widget? child) {
                  final double scale = widget.pulse && !motionOff
                      ? 1 + _breath.value * 0.02
                      : 1;
                  return Transform.scale(scale: scale, child: child);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: tileWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: tileWidth,
                            height: tileWidth,
                            child: Center(
                              child: AdminCallRoyalAvatar(
                                displayName: adminName,
                                imageUrl: _admin?.imageUrl,
                                size: baseSize,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _nameLabel(adminName, tileWidth),
                        ],
                      ),
                    ),
                    const SizedBox(width: 2),
                    SizedBox(
                      width: tileWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: tileWidth,
                            height: tileWidth,
                            child: Center(
                              child: _memberPortrait(
                                baseSize: baseSize,
                                name: memberName,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _nameLabel(memberName, tileWidth),
                          if (widget.memberTierLevel > 0) ...<Widget>[
                            const SizedBox(height: 4),
                            PremiumBadge.compact(
                              tierName: widget.memberTierName ?? '',
                              level: widget.memberTierLevel,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.heading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: IvoryColors.ivory,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (widget.pulse || widget.subtitle != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  widget.pulse ? 'Together, here' : widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: IvoryColors.cream.withValues(alpha: 0.8),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/audio_call_identity_stage.dart

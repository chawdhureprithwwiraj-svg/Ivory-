import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_profile.dart';
import 'auth_service.dart';
import 'profile_photo_service.dart';

/// CC.120 - a profile photo belongs to an ACTIVE paid membership.
///
/// When a member's paid tier has ended and they have not renewed, their
/// photo is removed for good: the profile link is cleared and every file in
/// their own private photo folder is deleted. They see Ivory's default
/// portrait (their initial) until they renew and choose a photo again.
///
/// SAFETY: nothing is ever removed unless the member's membership was read
/// successfully AND is definitely not active. A network error, a missing
/// answer or a paid member all mean "touch nothing". The administrator is
/// never touched.
class LapsedPhotoCleanup {
  LapsedPhotoCleanup._();
  static final LapsedPhotoCleanup instance = LapsedPhotoCleanup._();

  SupabaseClient get _db => Supabase.instance.client;
  bool _running = false;

  /// true = active paid tier, false = definitely none, null = unknown.
  Future<bool?> hasActivePaidTier() async {
    try {
      final List<dynamic> rows = await _db
          .from('my_membership')
          .select('tier_level')
          .order('tier_level', ascending: false)
          .limit(1);
      if (rows.isEmpty) return false;
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(rows.first as Map);
      return ((row['tier_level'] as num?) ?? 0).toInt() > 0;
    } catch (_) {
      return null;
    }
  }

  /// Returns true when a photo link or file was actually removed.
  Future<bool> runIfLapsed() async {
    if (_running) return false;
    final User? user = _db.auth.currentUser;
    if (user == null) return false;
    _running = true;
    try {
      IvoryProfile? profile = AuthService.instance.cachedProfile;
      if (profile == null || profile.id != user.id) {
        profile = await AuthService.instance.loadProfile();
      }
      if (profile == null || profile.isAdmin) return false;

      final bool? active = await hasActivePaidTier();
      if (active != false) return false;

      bool changed = false;

      // 1. Cut the link first, so nothing ever points at a deleted file.
      //    The sweep also clears every other lapsed member's link and the
      //    old live-chat snapshots. It is optional: if the CC.120 SQL has
      //    not been run, the member's own link is still cleared below.
      try {
        await _db.rpc<dynamic>('clear_lapsed_profile_photos');
      } catch (_) {}

      final bool linked = (profile.avatarPath?.isNotEmpty ?? false) ||
          (profile.avatarUrl?.isNotEmpty ?? false);
      if (linked) {
        try {
          await AuthService.instance.updateAvatarPath(null);
          changed = true;
        } catch (_) {
          // Could not clear the link: leave the files alone.
          return false;
        }
      }

      // 2. Delete every file in the member's own folder (the folder name is
      //    their own id; storage rules let only them delete these).
      try {
        final List<FileObject> files = await _db.storage
            .from(ProfilePhotoService.bucket)
            .list(path: user.id);
        for (final FileObject f in files) {
          final String name = f.name.trim();
          if (name.isEmpty) continue;
          try {
            await ProfilePhotoService.instance
                .deleteOwnPhoto('${user.id}/$name');
            changed = true;
          } catch (_) {}
        }
      } catch (_) {}

      final IvoryProfile? cached = AuthService.instance.cachedProfile;
      if (cached != null && cached.id == user.id) {
        AuthService.instance.cachedProfile = cached.withAvatarPath(null);
      }
      return changed;
    } catch (_) {
      return false;
    } finally {
      _running = false;
    }
  }
}

// END OF FILE - lib/services/lapsed_photo_cleanup.dart

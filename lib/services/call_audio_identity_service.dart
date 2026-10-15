import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/call_audio_identity.dart';
import '../models/ivory_profile.dart';
import 'auth_service.dart';
import 'profile_photo_service.dart';

/// Returns only the two public identity cards for the signed-in side of an
/// open audio call. Postgres checks the participant before returning paths.
class CallAudioIdentityService {
  CallAudioIdentityService._();
  static final CallAudioIdentityService instance = CallAudioIdentityService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<CallAudioIdentity>> forAudioCall(int callId) async {
    final List<CallAudioIdentity> identities = <CallAudioIdentity>[];
    try {
      final dynamic result = await _db.rpc<dynamic>(
        'call_audio_participant_identities',
        params: <String, dynamic>{'call_id_in': callId},
      );
      if (result is List) {
        for (final dynamic value in result) {
          if (value is! Map) continue;
          try {
            final Map<String, dynamic> row =
                Map<String, dynamic>.from(value as Map);
            final String? path = (row['avatar_path'] as String?)?.trim();
            final String? legacyUrl = (row['avatar_url'] as String?)?.trim();
            final String? imageUrl = path != null && path.isNotEmpty
                ? await ProfilePhotoService.instance.signedCallAvatarUrl(path)
                : ((legacyUrl?.isNotEmpty ?? false) ? legacyUrl : null);
            final String rawName = (row['display_name'] as String? ?? '').trim();
            final bool isAdmin = row['is_admin'] == true;
            identities.add(CallAudioIdentity(
              displayName:
                  rawName.isEmpty ? (isAdmin ? 'Ivory' : 'A member') : rawName,
              imageUrl: imageUrl,
              isAdmin: isAdmin,
            ));
          } catch (_) {
            // One malformed row/photo must not discard the other participant.
          }
        }
      }
    } catch (_) {
      // Use the locally cached profile below if the optional RPC is unavailable.
    }

    final CallAudioIdentity? self = await _currentProfileIdentity();
    if (self != null) {
      final int index = identities.indexWhere(
        (CallAudioIdentity identity) => identity.isAdmin == self.isAdmin,
      );
      if (index < 0) {
        identities.add(self);
      } else {
        final CallAudioIdentity server = identities[index];
        identities[index] = CallAudioIdentity(
          displayName:
              self.displayName.trim().isEmpty ? server.displayName : self.displayName,
          imageUrl: self.imageUrl ?? server.imageUrl,
          isAdmin: self.isAdmin,
        );
      }
    }

    identities.sort((CallAudioIdentity a, CallAudioIdentity b) {
      if (a.isAdmin == b.isAdmin) return 0;
      return a.isAdmin ? -1 : 1;
    });
    return identities;
  }

  Future<CallAudioIdentity?> _currentProfileIdentity() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;
    try {
      IvoryProfile? profile = AuthService.instance.cachedProfile;
      if (profile?.id != user.id) {
        profile = await AuthService.instance.loadProfile();
      }
      if (profile == null || profile.id != user.id) return null;

      final String? path = profile.avatarPath?.trim();
      final String? imageUrl = path != null && path.isNotEmpty
          ? await ProfilePhotoService.instance.signedAvatarUrl(path)
          : ((profile.avatarUrl?.trim().isNotEmpty ?? false)
              ? profile.avatarUrl!.trim()
              : null);
      return CallAudioIdentity(
        displayName: profile.displayName,
        imageUrl: imageUrl,
        isAdmin: profile.isAdmin,
      );
    } catch (_) {
      return null;
    }
  }
}

// END OF FILE - lib/services/call_audio_identity_service.dart

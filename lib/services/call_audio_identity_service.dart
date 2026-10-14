import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/call_audio_identity.dart';
import 'profile_photo_service.dart';

/// Returns only the two public identity cards for the signed-in side of an
/// active audio call. Postgres checks the participant before returning paths.
class CallAudioIdentityService {
  CallAudioIdentityService._();
  static final CallAudioIdentityService instance = CallAudioIdentityService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<List<CallAudioIdentity>> forAudioCall(int callId) async {
    try {
      final dynamic result = await _db.rpc<dynamic>(
        'call_audio_participant_identities',
        params: <String, dynamic>{'call_id_in': callId},
      );
      if (result is! List) return const <CallAudioIdentity>[];

      final List<CallAudioIdentity> identities = <CallAudioIdentity>[];
      for (final dynamic value in result) {
        if (value is! Map) continue;
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
          displayName: rawName.isEmpty ? (isAdmin ? 'Ivory' : 'A member') : rawName,
          imageUrl: imageUrl,
          isAdmin: isAdmin,
        ));
      }
      identities.sort((CallAudioIdentity a, CallAudioIdentity b) {
        if (a.isAdmin == b.isAdmin) return 0;
        return a.isAdmin ? -1 : 1;
      });
      return identities;
    } catch (_) {
      // Missing optional identity SQL or a photo-read denial must never
      // stop the audio call; initials remain as a graceful fallback.
      return const <CallAudioIdentity>[];
    }
  }
}

// END OF FILE - lib/services/call_audio_identity_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_service.dart';

/// ============================================================
/// IVORY - THE PRIVATE LINE, THE HOUSE'S DOOR TO THE DATABASE
///
/// Everything Ivory does on the Admin LINE tab goes through here:
/// the queue, opening and answering a letter, approving or declining
/// a held one, muting, the numbers, reply templates and the Letter
/// of the Day. Every call is re-checked by the database, so a member
/// who somehow reached it could do nothing. Errors are thrown for
/// the Admin screens to show with adminDetail().
/// ============================================================
class LineHouseService {
  LineHouseService._();
  static final LineHouseService instance = LineHouseService._();

  /// The private store for voice replies.
  static const String bucket = 'line';

  SupabaseClient get _db => Supabase.instance.client;

  Map<String, dynamic> _map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  List<Map<String, dynamic>> _list(dynamic v) => v is List
      ? v.map((dynamic e) => Map<String, dynamic>.from(e as Map)).toList()
      : <Map<String, dynamic>>[];

  Future<Map<String, dynamic>> state() async =>
      _map(await _db.rpc('line_admin_state'));

  Future<String> save({
    required bool open,
    required int places,
    required int chars,
    required int returnDays,
    required int retentionDays,
    required int windowDays,
    required int tierHours,
    required int rungHours,
    required bool dailyOn,
    required String words,
  }) async {
    final dynamic r = await _db.rpc(
      'line_admin_save',
      params: <String, dynamic>{
        'open_in': open,
        'places_in': places,
        'chars_in': chars,
        'return_in': returnDays,
        'retention_in': retentionDays,
        'window_in': windowDays,
        'tier_hours_in': tierHours,
        'rung_hours_in': rungHours,
        'daily_in': dailyOn,
        'words_in': words,
      },
    );
    return '$r';
  }

  Future<String> setTier(int tierId, int letters) async => '${await _db.rpc(
    'line_admin_tier',
    params: <String, dynamic>{'tier_in': tierId, 'letters_in': letters},
  )}';

  Future<String> setRung(int rung, int extra) async => '${await _db.rpc(
    'line_admin_rung',
    params: <String, dynamic>{'rung_in': rung, 'extra_in': extra},
  )}';

  Future<List<Map<String, dynamic>>> queue(String filter) async => _list(
    await _db.rpc(
      'line_admin_queue',
      params: <String, dynamic>{'filter_in': filter},
    ),
  );

  Future<Map<String, dynamic>> open(int id) async => _map(
    await _db.rpc('line_admin_open', params: <String, dynamic>{'letter_in': id}),
  );

  Future<String> reply(int id, String text, {String? audioPath}) async =>
      '${await _db.rpc(
        'line_admin_reply',
        params: <String, dynamic>{
          'letter_in': id,
          'text_in': text,
          'audio_in': audioPath,
        },
      )}';

  Future<String> decide(int id, bool approve) async => '${await _db.rpc(
    'line_admin_decide',
    params: <String, dynamic>{'letter_in': id, 'approve_in': approve},
  )}';

  Future<String> mute(String userId, bool on, {String? reason}) async =>
      '${await _db.rpc(
        'line_admin_mute',
        params: <String, dynamic>{
          'user_in': userId,
          'on_in': on,
          'reason_in': reason,
        },
      )}';

  Future<List<Map<String, dynamic>>> templates() async =>
      _list(await _db.rpc('line_admin_templates'));

  Future<String> saveTemplate(int? id, String title, String body) async =>
      '${await _db.rpc(
        'line_admin_template_save',
        params: <String, dynamic>{
          'id_in': id,
          'title_in': title,
          'body_in': body,
        },
      )}';

  Future<String> deleteTemplate(int id) async => '${await _db.rpc(
    'line_admin_template_delete',
    params: <String, dynamic>{'id_in': id},
  )}';

  /// Shares an answered letter. A voice-only reply needs a typed [note]
  /// (a written reply is used as it is and the note is ignored).
  Future<String> shareDaily(int id, {String note = ''}) async => '${await _db.rpc(
    'line_admin_daily_share',
    params: <String, dynamic>{'letter_in': id, 'note_in': note},
  )}';

  Future<String> clearDaily() async =>
      '${await _db.rpc('line_admin_daily_clear')}';

  /// Uploads a voice note to the private store and returns its path.
  /// The letter keeps that path; only that letter's member can fetch it.
  Future<String> uploadVoice(int letterId, PickedMedia media) async {
    final String clean = media.name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final String safe =
        clean.length <= 50 ? clean : clean.substring(clean.length - 50);
    final String path =
        '$letterId/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _db.storage
        .from(bucket)
        .uploadBinary(
          path,
          media.bytes,
          fileOptions: FileOptions(contentType: _type(safe), upsert: true),
        );
    return path;
  }

  static String _type(String name) {
    final String e =
        name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (e) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      default:
        return 'audio/mp4';
    }
  }
}

// END OF FILE - lib/services/line_house_service.dart
    

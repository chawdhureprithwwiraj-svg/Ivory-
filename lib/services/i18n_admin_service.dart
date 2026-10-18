import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin side of the languages: the list of languages, switching one on or
/// off, searching the words, changing one word, and pasting many at once.
/// Every call is re-checked by the database (Admins only).
class I18nAdminService {
  I18nAdminService._();
  static final I18nAdminService instance = I18nAdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  List<Map<String, dynamic>> _rows(dynamic r) {
    if (r is! List) return <Map<String, dynamic>>[];
    return r
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<List<Map<String, dynamic>>> languages() async {
    final dynamic r = await _db.rpc<dynamic>('i18n_admin_languages');
    return _rows(r);
  }

  Future<void> setOn(String code, bool on) async {
    await _db.rpc<dynamic>(
      'i18n_admin_set_on',
      params: <String, dynamic>{'code_in': code, 'on_in': on},
    );
  }

  Future<List<Map<String, dynamic>>> words({
    required String lang,
    String q = '',
    String filter = 'all',
    int limit = 60,
    int offset = 0,
  }) async {
    final dynamic r = await _db.rpc<dynamic>(
      'i18n_admin_list',
      params: <String, dynamic>{
        'lang_in': lang,
        'q_in': q,
        'filter_in': filter,
        'lim_in': limit,
        'off_in': offset,
      },
    );
    return _rows(r);
  }

  Future<void> save(String lang, String src, String txt) async {
    await _db.rpc<dynamic>(
      'i18n_admin_save',
      params: <String, dynamic>{
        'lang_in': lang,
        'src_in': src,
        'txt_in': txt,
      },
    );
  }

  /// Returns `{saved, skipped}`.
  Future<Map<String, dynamic>> importBlock(String lang, String block) async {
    final dynamic r = await _db.rpc<dynamic>(
      'i18n_admin_import',
      params: <String, dynamic>{'lang_in': lang, 'block_in': block},
    );
    if (r is Map) return Map<String, dynamic>.from(r);
    return <String, dynamic>{'saved': 0, 'skipped': 0};
  }
}

// END OF FILE - lib/services/i18n_admin_service.dart

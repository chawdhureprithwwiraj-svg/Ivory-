import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n_langs.dart';

/// ============================================================
/// IVORY'S VOICE IN MANY LANGUAGES
///
/// English is the text written in the app itself and is the KEY. A word
/// that has no translation simply stays English, so a half-finished
/// language is never broken.
///
///   'Sign in'.tr                                  one word or line
///   'Sent to {email}.'.trWith({'email': e})       with a blank to fill
///
/// The chosen language and its word pack are kept on the phone, so the
/// app speaks the right language the moment it opens, even offline.
/// ============================================================
class L10n {
  L10n._();
  static final L10n instance = L10n._();

  static const String _kCode = 'ivory_lang';
  static const String _kVer = 'ivory_lang_ver';
  static const String _kPack = 'ivory_lang_pack';

  /// Goes up by one every time the language is chosen. The app listens to
  /// this and repaints itself from the top.
  final ValueNotifier<int> epoch = ValueNotifier<int>(0);

  String _code = 'en';
  bool _chosen = false;
  Map<String, String> _pack = <String, String>{};

  String get code => _code;

  /// False until the member has used the language screen once.
  bool get chosen => _chosen;

  LangInfo get info => langByCode(_code);
  bool get rtl => info.rtl;

  SupabaseClient get _db => Supabase.instance.client;

  /// Letter-spacing that is safe for the language: Indian scripts join
  /// their letters, so wide spacing is dropped for them.
  double ls(double v) => (_code == 'en' || _code.endsWith('-Latn')) ? v : 0;

  /// Call once before runApp.
  Future<void> init() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final String? c = p.getString(_kCode);
      if (c != null && isKnownLang(c)) {
        _code = c;
        _chosen = true;
        final String? raw = p.getString(_kPack);
        if (c != 'en' && raw != null) {
          _pack = _decode(raw);
        }
      }
    } catch (_) {
      // Storage unavailable: English.
    }
  }

  Map<String, String> _decode(String raw) {
    try {
      final dynamic j = jsonDecode(raw);
      if (j is Map) {
        return j.map((dynamic k, dynamic v) =>
            MapEntry<String, String>('$k', '$v'));
      }
    } catch (_) {
      // A damaged pack is ignored: English.
    }
    return <String, String>{};
  }

  /// The words, in the chosen language. English text in, language text out.
  String t(String src, [Map<String, Object?>? params]) {
    String out = _pack[src] ?? src;
    if (params != null) {
      params.forEach((String k, Object? v) {
        out = out.replaceAll('{$k}', '${v ?? ''}');
      });
    }
    return out;
  }

  /// Fetches a word pack. Returns null if the network or database failed.
  Future<Map<String, String>?> _download(
      String c, void Function(String v) onVer) async {
    try {
      final dynamic r = await _db.rpc<dynamic>(
        'i18n_pack',
        params: <String, dynamic>{'lang_in': c},
      );
      if (r is Map) {
        onVer('${r['v'] ?? ''}');
        final dynamic s = r['s'];
        if (s is Map) {
          return s.map((dynamic k, dynamic v) =>
              MapEntry<String, String>('$k', '$v'));
        }
        return <String, String>{};
      }
    } catch (_) {
      // Offline or not set up yet: the caller carries on in English.
    }
    return null;
  }

  /// The member picked a language (or kept the preselected one).
  Future<void> choose(String c) async {
    final String code = isKnownLang(c) ? c : 'en';
    Map<String, String> pack = <String, String>{};
    String ver = '';
    if (code != 'en') {
      final Map<String, String>? got =
          await _download(code, (String v) => ver = v);
      if (got != null) pack = got;
    }
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString(_kCode, code);
      await p.setString(_kVer, ver);
      if (code == 'en' || pack.isEmpty) {
        await p.remove(_kPack);
      } else {
        await p.setString(_kPack, jsonEncode(pack));
      }
    } catch (_) {
      // Remembering the choice is a convenience, never a failure.
    }
    _pack = pack;
    _code = code;
    _chosen = true;
    _saveToAccount();
    epoch.value = epoch.value + 1;
  }

  /// Tells the database which language a signed-in member chose.
  Future<void> _saveToAccount() async {
    try {
      if (_db.auth.currentSession == null) return;
      await _db.rpc<dynamic>(
        'i18n_set_my_language',
        params: <String, dynamic>{'lang_in': _code},
      );
    } catch (_) {
      // Not set up yet, or offline: nothing is lost.
    }
  }

  /// Quiet check at start-up: if the house edited a word, fetch the new
  /// pack. It is used from the next screen that is built.
  Future<void> refreshQuietly() async {
    if (!_chosen) return;
    await _saveToAccount();
    if (_code == 'en') return;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      final dynamic v = await _db.rpc<dynamic>(
        'i18n_version',
        params: <String, dynamic>{'lang_in': _code},
      );
      if ('$v' == (p.getString(_kVer) ?? '')) return;
      String ver = '';
      final Map<String, String>? got =
          await _download(_code, (String x) => ver = x);
      if (got == null) return;
      _pack = got;
      await p.setString(_kVer, ver);
      await p.setString(_kPack, jsonEncode(got));
    } catch (_) {
      // Try again next time the app opens.
    }
  }
}

/// `'text'.tr` and `'text {name}'.trWith({'name': x})`.
extension IvoryTr on String {
  String get tr => L10n.instance.t(this);
  String trWith(Map<String, Object?> params) => L10n.instance.t(this, params);
}

// END OF FILE - lib/l10n/l10n.dart

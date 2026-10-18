import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_notification.dart';
import '../models/ivory_post.dart';
import 'l10n.dart';

/// ============================================================
/// THE HOUSE'S OWN WORDS, IN THE MEMBER'S LANGUAGE
///
/// Posts, poll options and broadcast notices are written once by the house.
/// A translated line may exist for each language the member could choose.
/// This class lays those lines over the original, and only ever REPLACES
/// text: if a line is missing, stale or the call fails, the original shows.
///
/// The database decides what may be returned (a locked story's full text is
/// never sent to a member who cannot open it). Nothing here can break a
/// screen, because every method falls back to the list it was given.
/// ============================================================
class ContentI18n {
  ContentI18n._();
  static final ContentI18n instance = ContentI18n._();

  static const Duration _hitKeeps = Duration(minutes: 10);
  static const Duration _missKeeps = Duration(minutes: 2);

  SupabaseClient get _db => Supabase.instance.client;

  /// 'kind|lang|ref|fields' -> the lines found (empty = nothing yet).
  final Map<String, _Found> _seen = <String, _Found>{};

  Future<Map<int, Map<String, String>>> _lines(
      String kind, List<int> refs, List<String> fields) async {
    final Map<int, Map<String, String>> out = <int, Map<String, String>>{};
    final String lang = L10n.instance.code;
    if (lang == 'en' || refs.isEmpty) return out;

    final DateTime now = DateTime.now();
    final String fk = fields.join(',');
    final List<int> need = <int>[];
    for (final int ref in refs.toSet()) {
      final _Found? f = _seen['$kind|$lang|$ref|$fk'];
      if (f != null &&
          now.difference(f.at) < (f.lines.isEmpty ? _missKeeps : _hitKeeps)) {
        if (f.lines.isNotEmpty) out[ref] = f.lines;
      } else {
        need.add(ref);
      }
    }

    for (int i = 0; i < need.length; i += 100) {
      final List<int> part = need.sublist(i, math.min(i + 100, need.length));
      final dynamic res = await _db.rpc<dynamic>(
        'content_i18n_get',
        params: <String, dynamic>{
          'kind_in': kind,
          'refs_in': part,
          'lang_in': lang,
          'fields_in': fields,
        },
      );
      final Map<int, Map<String, String>> got = <int, Map<String, String>>{};
      if (res is List) {
        for (final dynamic e in res) {
          if (e is! Map) continue;
          final int ref = (e['ref'] as num).toInt();
          got.putIfAbsent(ref, () => <String, String>{})['${e['field']}'] =
              '${e['txt']}';
        }
      }
      for (final int ref in part) {
        final Map<String, String> lines = got[ref] ?? <String, String>{};
        _seen['$kind|$lang|$ref|$fk'] = _Found(lines, now);
        if (lines.isNotEmpty) out[ref] = lines;
      }
    }
    return out;
  }

  IvoryPost _post(IvoryPost p, Map<String, String> f) => IvoryPost(
        id: p.id,
        type: p.type,
        title: f['title'] ?? p.title,
        tierRequired: p.tierRequired,
        isUnlocked: p.isUnlocked,
        priceInr: p.priceInr,
        freeFromTier: p.freeFromTier,
        summary: f['summary'] ?? p.summary,
        body: f['body'] ?? p.body,
        tierName: p.tierName,
        durationSecs: p.durationSecs,
        viewCount: p.viewCount,
        createdAt: p.createdAt,
        media: p.media,
        thumb: p.thumb,
        thumbnailUrl: p.thumbnailUrl,
        doorCredit: p.doorCredit,
        allowedTiers: p.allowedTiers,
      );

  /// Feed cards: title and summary only (the full text comes with the post).
  Future<List<IvoryPost>> posts(List<IvoryPost> list) async {
    try {
      final Map<int, Map<String, String>> got = await _lines(
          'post',
          list.map((IvoryPost p) => p.id).toList(),
          const <String>['title', 'summary']);
      if (got.isEmpty) return list;
      return list.map((IvoryPost p) {
        final Map<String, String>? f = got[p.id];
        return f == null ? p : _post(p, f);
      }).toList();
    } catch (_) {
      return list;
    }
  }

  /// One opened post: title, summary and (when the member may read it) text.
  Future<IvoryPost> post(IvoryPost p) async {
    try {
      final Map<int, Map<String, String>> got = await _lines(
          'post', <int>[p.id], const <String>['title', 'summary', 'body']);
      final Map<String, String>? f = got[p.id];
      return f == null ? p : _post(p, f);
    } catch (_) {
      return p;
    }
  }

  Future<List<PollOption>> options(List<PollOption> list) async {
    try {
      final Map<int, Map<String, String>> got = await _lines('poll',
          list.map((PollOption o) => o.id).toList(), const <String>['label']);
      if (got.isEmpty) return list;
      return list.map((PollOption o) {
        final String? label = got[o.id]?['label'];
        return label == null
            ? o
            : PollOption(id: o.id, label: label, votes: o.votes);
      }).toList();
    } catch (_) {
      return list;
    }
  }

  Future<List<IvoryNotification>> notices(List<IvoryNotification> list) async {
    try {
      final Map<int, Map<String, String>> got = await _lines(
          'notice',
          list.map((IvoryNotification n) => n.id).toList(),
          const <String>['title', 'body']);
      if (got.isEmpty) return list;
      return list.map((IvoryNotification n) {
        final Map<String, String>? f = got[n.id];
        if (f == null) return n;
        return IvoryNotification(
          id: n.id,
          title: f['title'] ?? n.title,
          body: f['body'] ?? n.body,
          kind: n.kind,
          isRead: n.isRead,
          postId: n.postId,
          actionTab: n.actionTab,
          actionUrl: n.actionUrl,
          createdAt: n.createdAt,
        );
      }).toList();
    } catch (_) {
      return list;
    }
  }
}

class _Found {
  const _Found(this.lines, this.at);
  final Map<String, String> lines;
  final DateTime at;
}

// END OF FILE - lib/l10n/content_i18n.dart

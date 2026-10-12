import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/folio_entry.dart';

/// A friendly limit the editor can show before a row reaches the server.
class PrivateFolioLimitException implements Exception {
  const PrivateFolioLimitException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Account-owned writing and link storage. RLS is the access boundary;
/// this service never reads another member's rows or uses an admin client.
class PrivateFolioService {
  PrivateFolioService._();
  static final PrivateFolioService instance = PrivateFolioService._();

  static const int maxEntries = 100;
  static const int maxEntryContentBytes = 42 * 1024;
  static const int maxMemberContentBytes = 1024 * 1024;

  SupabaseClient get _db => Supabase.instance.client;

  static const String _table = 'member_private_folio_entries';

  /// Counts the UTF-8 bytes of user-authored fields (not database overhead).
  /// The same fields are counted by the CC.110 database trigger.
  static int contentBytes({
    required String title,
    required String body,
    String? url,
    List<String> tags = const <String>[],
  }) {
    int bytes = utf8.encode(title).length + utf8.encode(body).length;
    if (url != null) bytes += utf8.encode(url).length;
    for (final String tag in tags) {
      bytes += utf8.encode(tag).length;
    }
    return bytes;
  }

  static int contentBytesForEntry(FolioEntry entry) => contentBytes(
        title: entry.title,
        body: entry.body,
        url: entry.url,
        tags: entry.tags,
      );

  static int contentBytesForEntries(Iterable<FolioEntry> entries) =>
      entries.fold<int>(
        0,
        (int total, FolioEntry entry) => total + contentBytesForEntry(entry),
      );

  Future<List<FolioEntry>> fetchEntries() async {
    final List<dynamic> rows = await _db
        .from(_table)
        .select()
        .order('updated_at', ascending: false)
        .limit(maxEntries);
    return rows
        .map((dynamic row) => FolioEntry.fromDb(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> save({
    String? id,
    required FolioKind kind,
    required String title,
    required String body,
    String? url,
    int? relatedCallId,
    List<String> tags = const <String>[],
  }) async {
    final String cleanTitle = title.trim();
    final String cleanBody = body.trim();
    final String? cleanUrl = url == null || url.trim().isEmpty
        ? null
        : url.trim();
    final List<String> cleanTags = tags.take(5).toList(growable: false);

    if (contentBytes(
          title: cleanTitle,
          body: cleanBody,
          url: cleanUrl,
          tags: cleanTags,
        ) >
        maxEntryContentBytes) {
      throw const PrivateFolioLimitException(
        'This page is too large to keep. Shorten it and try again.',
      );
    }

    final Map<String, dynamic> values = <String, dynamic>{
      'kind': kind.dbValue,
      'title': cleanTitle,
      'body': cleanBody,
      'url': cleanUrl,
      'related_call_id': relatedCallId,
      'tags': cleanTags,
    };
    if (id == null) {
      await _db.from(_table).insert(values);
    } else {
      await _db.from(_table).update(values).eq('id', id);
    }
  }

  Future<void> delete(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}

// END OF FILE - lib/services/private_folio_service.dart

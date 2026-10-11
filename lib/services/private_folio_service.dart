import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/folio_entry.dart';

/// Account-owned writing and link storage. RLS is the access boundary;
/// this service never reads another member's rows or uses an admin client.
class PrivateFolioService {
  PrivateFolioService._();
  static final PrivateFolioService instance = PrivateFolioService._();

  SupabaseClient get _db => Supabase.instance.client;

  static const String _table = 'member_private_folio_entries';

  Future<List<FolioEntry>> fetchEntries() async {
    final List<dynamic> rows = await _db
        .from(_table)
        .select()
        .order('updated_at', ascending: false)
        .limit(500);
    return rows
        .map((dynamic row) =>
            FolioEntry.fromDb(row as Map<String, dynamic>))
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
    final Map<String, dynamic> values = <String, dynamic>{
      'kind': kind.dbValue,
      'title': title.trim(),
      'body': body.trim(),
      'url': url == null || url.trim().isEmpty ? null : url.trim(),
      'related_call_id': relatedCallId,
      'tags': tags.take(5).toList(growable: false),
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

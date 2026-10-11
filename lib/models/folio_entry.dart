enum FolioKind {
  note('note', 'Note'),
  draft('draft', 'Draft'),
  link('link', 'Saved link'),
  callNote('call_note', 'Call note');

  const FolioKind(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static FolioKind fromDb(Object? value) => FolioKind.values.firstWhere(
        (FolioKind kind) => kind.dbValue == value,
        orElse: () => FolioKind.note,
      );
}

class FolioEntry {
  const FolioEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.url,
    this.relatedCallId,
    this.tags = const <String>[],
  });

  final String id;
  final FolioKind kind;
  final String title;
  final String body;
  final String? url;
  final int? relatedCallId;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FolioEntry.fromDb(Map<String, dynamic> row) => FolioEntry(
        id: row['id'].toString(),
        kind: FolioKind.fromDb(row['kind']),
        title: (row['title'] as String?) ?? '',
        body: (row['body'] as String?) ?? '',
        url: row['url'] as String?,
        relatedCallId: (row['related_call_id'] as num?)?.toInt(),
        tags: (row['tags'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList(growable: false),
        createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
        updatedAt: DateTime.tryParse((row['updated_at'] as String?) ?? ''),
      );
}

// END OF FILE - lib/models/folio_entry.dart

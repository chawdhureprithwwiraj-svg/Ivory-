import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// IVORY - THE VAULT (CLOUDFLARE R2)
///
/// Big videos ride in R2: 10 GB free and, the part that matters,
/// zero egress fees - a hundred members watching a one-gigabyte
/// film costs nothing in bandwidth. The phone never sees the R2
/// secret: the edge function signs a PUT for the house and a GET
/// for a member who may open the post.
///
/// Uploads stream straight from the file on disk, so a 1 GB video
/// never sits in the phone's memory.
/// ============================================================
/// The Vault is at its 9 GB safety cap. The composer catches this
/// and opens the Vault manager instead of a dead-end toast.
class VaultFullError extends Error {
  VaultFullError(this.usedGb);
  final double usedGb;
}

/// One object sitting in the Vault, as the manager shows it.
class VaultItem {
  const VaultItem({
    required this.key,
    required this.size,
    required this.modified,
    this.postId,
    this.postTitle,
  });

  final String key;
  final int size;
  final String modified;
  final int? postId;
  final String? postTitle;

  String get sizeLabel {
    final double gb = size / (1024 * 1024 * 1024);
    return gb >= 1
        ? '${gb.toStringAsFixed(1)} GB'
        : '${(size / (1024 * 1024)).round()} MB';
  }
}

class VaultService {
  VaultService._();
  static final VaultService instance = VaultService._();

  static String _contentType(String name) {
    final String n = name.toLowerCase();
    if (n.endsWith('.mp4')) return 'video/mp4';
    if (n.endsWith('.m4v')) return 'video/x-m4v';
    if (n.endsWith('.mov')) return 'video/quicktime';
    if (n.endsWith('.mkv')) return 'video/x-matroska';
    if (n.endsWith('.webm')) return 'video/webm';
    return 'application/octet-stream';
  }

  /// Streams [path] into the Vault. Returns the vault key to store
  /// on the post (media_source 'r2'). [onProgress] gets 0..1.
  Future<String> uploadVideo({
    required String path,
    required String name,
    void Function(double progress)? onProgress,
  }) async {
    final SupabaseClient client = Supabase.instance.client;
    final String safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String key = 'vault/${stamp}_$safe';
    final String ct = _contentType(safe);

    final File f = File(path);
    final int total = await f.length();

    final dynamic fr = await client.functions.invoke(
      'r2-vault',
      method: HttpMethod.post,
      body: <String, dynamic>{
        'op': 'put',
        'key': key,
        'size': total,
        'content_type': ct,
      },
    );
    if (fr.status != 200) {
      final dynamic d = fr.data;
      if (d is Map && d['error'] == 'vault_full') {
        throw VaultFullError(
            ((d['used'] as num?) ?? 0) / (1024 * 1024 * 1024));
      }
      throw Exception(
          (d is Map ? d['error'] as String? : null) ?? 'The Vault door jammed.');
    }
    final String url = (fr.data as Map<String, dynamic>)['url'] as String;

    int sent = 0;
    double last = 0;

    final HttpClient hc = HttpClient();
    hc.connectionTimeout = const Duration(seconds: 30);
    try {
      final HttpClientRequest req =
          await hc.openUrl('PUT', Uri.parse(url));
      req.headers.set('Content-Type', ct);
      req.contentLength = total;
      req.persistentConnection = false;

      await for (final List<int> chunk in f.openRead()) {
        req.add(chunk);
        sent += chunk.length;
        final double p = total == 0 ? 1 : sent / total;
        if (p - last >= 0.04 || sent == total) {
          last = p;
          onProgress?.call(p);
        }
      }
      final HttpClientResponse res = await req.close();
      final int code = res.statusCode;
      await res.drain<void>();
      if (code >= 300) {
        throw Exception('The Vault refused the file (code $code).');
      }
    } finally {
      hc.close(force: true);
    }
    return key;
  }

  /// How many bytes the Vault really holds, after the edge's own
  /// sweep. Null on any hiccup - the UI then simply stays quiet.
  Future<int?> usedBytes() async {
    try {
      final dynamic fr = await Supabase.instance.client.functions.invoke(
        'r2-vault',
        method: HttpMethod.post,
        body: <String, dynamic>{'op': 'usage'},
      );
      if (fr.status != 200) return null;
      return ((fr.data as Map<String, dynamic>)['used'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Every object in the Vault, with the story (if any) that points
  /// at it. The manager shows this; nothing is ever removed without
  /// the house approving on screen.
  Future<List<VaultItem>> items() async {
    final dynamic fr = await Supabase.instance.client.functions.invoke(
      'r2-vault',
      method: HttpMethod.post,
      body: <String, dynamic>{'op': 'list'},
    );
    if (fr.status != 200) return <VaultItem>[];
    final List<dynamic> rows =
        (fr.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
            <dynamic>[];
    return rows
        .map((dynamic r) => VaultItem(
              key: (r as Map<String, dynamic>)['key'] as String,
              size: ((r['size'] as num?) ?? 0).toInt(),
              modified: (r['modified'] as String?) ?? '',
              postId: (r['post_id'] as num?)?.toInt(),
              postTitle: r['post_title'] as String?,
            ))
        .toList();
  }

  /// Only ever called after the house taps delete and confirms.
  Future<void> remove(String key) async {
    final dynamic fr = await Supabase.instance.client.functions.invoke(
      'r2-vault',
      method: HttpMethod.post,
      body: <String, dynamic>{'op': 'delete', 'key': key},
    );
    if (fr.status != 200) {
      final dynamic d = fr.data;
      throw Exception((d is Map ? d['error'] as String? : null) ??
          'The Vault refused to remove that file.');
    }
  }

  /// A member-side signed GET for a vault post, straight from the
  /// edge (which re-checks can_open_post as that member).
  Future<String?> openUrl(int postId) async {
    try {
      final dynamic fr = await Supabase.instance.client.functions.invoke(
        'r2-vault',
        method: HttpMethod.post,
        body: <String, dynamic>{'op': 'get', 'post_id': postId},
      );
      if (fr.status != 200) return null;
      return (fr.data as Map<String, dynamic>)['url'] as String?;
    } catch (_) {
      return null;
    }
  }
}

// END OF FILE - lib/services/vault_service.dart

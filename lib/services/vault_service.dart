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

    final dynamic fr = await client.functions.invoke(
      'r2-vault',
      method: HttpMethod.post,
      body: <String, dynamic>{'op': 'put', 'key': key, 'content_type': ct},
    );
    if (fr.status != 200) {
      final dynamic d = fr.data;
      throw Exception(
          (d is Map ? d['error'] as String? : null) ?? 'The Vault door jammed.');
    }
    final String url = (fr.data as Map<String, dynamic>)['url'] as String;

    final File f = File(path);
    final int total = await f.length();
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

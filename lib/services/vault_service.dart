import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/ivory_errors.dart';

/// ============================================================
/// IVORY - THE VAULT (CLOUDFLARE R2)
///
/// Video, voice and published story images use R2. Internet egress is
/// free, but storage and request quotas still apply. The phone never
/// sees the R2 secret: the edge function signs uploads and private-media
/// reads; public story images use a separate custom-domain bucket.
///
/// Uploads stream straight from the file on disk, so a 1 GB video
/// never sits in the phone's memory.
///
/// SPRINT 24b - every call into the edge function now reports what
/// actually happened. Before this, `items()` and `remove()` threw
/// raw and the manager swallowed it into an endless spinner, so a
/// broken Vault looked identical to an empty one. It never will
/// again: if the door jams, the house is told which door and why.
/// ============================================================

/// The Vault is at its 9 GB safety cap. The composer catches this
/// and opens the Vault manager instead of a dead-end toast.
class VaultFullError extends Error {
  VaultFullError(this.usedGb);
  final double usedGb;
}

/// The Vault refused, and this is exactly why. [detail] is written
/// for the house, not for a member - show it in the admin console.
class VaultError implements Exception {
  VaultError(this.op, this.detail);

  /// Which door: usage, list, private/public put, delete or get.
  final String op;

  /// The real reason, already made readable by adminDetail().
  final String detail;

  @override
  String toString() => 'The Vault door jammed on "$op". $detail';
}

/// One private Vault file or published image in the shared R2 manager.
class VaultItem {
  const VaultItem({
    required this.key,
    required this.size,
    required this.modified,
    this.postId,
    this.postTitle,
    this.isPublicImage = false,
    this.isCoverImage = false,
  });

  final String key;
  final int size;
  final String modified;
  final int? postId;
  final String? postTitle;
  final bool isPublicImage;
  final bool isCoverImage;

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
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    if (n.endsWith('.mp4')) return 'video/mp4';
    if (n.endsWith('.m4v')) return 'video/x-m4v';
    if (n.endsWith('.mov')) return 'video/quicktime';
    if (n.endsWith('.mkv')) return 'video/x-matroska';
    if (n.endsWith('.webm')) return 'video/webm';
    return 'application/octet-stream';
  }

  /// One way in and out of the edge function, so every operation
  /// fails the same readable way. Returns the decoded body.
  ///
  /// Throws [VaultFullError] when the cap is the reason, and
  /// [VaultError] for everything else - never a bare exception.
  Future<Map<String, dynamic>> _call(
    String op,
    Map<String, dynamic> body,
  ) async {
    dynamic fr;
    try {
      fr = await Supabase.instance.client.functions.invoke(
        'r2-vault',
        method: HttpMethod.post,
        body: <String, dynamic>{'op': op, ...body},
      );
    } catch (e) {
      // A thrown FunctionException carries the status and the body
      // the function actually returned - that is the useful part.
      if (e is FunctionException) {
        final Object? d = e.details;
        if (d is Map && d['error'] == 'vault_full') {
          throw VaultFullError(((d['used'] as num?) ?? 0) / (1 << 30));
        }
        if (e.status == 404) {
          throw VaultError(op,
              'The r2-vault function is not deployed, or is deployed '
              'under a different name. Supabase -> Edge Functions.');
        }
        if (e.status == 401 || e.status == 403) {
          // Report what the function actually said. Guessing a cause
          // here once sent the house to the wrong settings page.
          final String said =
              d is Map ? (d['error'] ?? '').toString().trim() : '';
          throw VaultError(
              op,
              'r2-vault refused the call (HTTP ${e.status})'
              '${said.isEmpty ? '' : ': "$said"'}. '
              'If it names the house, the function is checking the wrong '
              'admin column. Otherwise check that "Verify JWT with legacy '
              'secret" is switched OFF on the function.');
        }
      }
      throw VaultError(op, adminDetail(e));
    }

    final int status = (fr.status as int?) ?? 0;
    final dynamic data = fr.data;

    if (status != 200) {
      if (data is Map && data['error'] == 'vault_full') {
        throw VaultFullError(((data['used'] as num?) ?? 0) / (1 << 30));
      }
      final String why = data is Map
          ? (data['error'] ?? data['message'] ?? data).toString()
          : (data?.toString() ?? 'no reply');
      throw VaultError(op, 'r2-vault answered HTTP $status: $why');
    }

    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw VaultError(op, 'r2-vault replied with ${data.runtimeType}, '
        'not an object. Check the function returns JSON.');
  }

  /// Streams [path] into the Vault. Returns the vault key to store
  /// on the post (media_source 'r2'). [onProgress] gets 0..1.
  Future<String> uploadVideo({
    required String path,
    required String name,
    void Function(double progress)? onProgress,
  }) async {
    final String safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String key = 'vault/${stamp}_$safe';
    final String ct = _contentType(safe);

    final File f = File(path);
    if (!await f.exists()) {
      throw VaultError('put',
          'The phone has already cleared that video from its temporary '
          'folder. Pick the film again and publish without leaving the '
          'composer in between.');
    }
    final int total = await f.length();

    final Map<String, dynamic> signed = await _call('put', <String, dynamic>{
      'key': key,
      'size': total,
      'content_type': ct,
    });

    final String? url = signed['url'] as String?;
    if (url == null || url.isEmpty) {
      throw VaultError('put', 'r2-vault did not return an upload link. '
          'Check the R2 secrets are set on the function.');
    }

    int sent = 0;
    double last = 0;

    final HttpClient hc = HttpClient();
    hc.connectionTimeout = const Duration(seconds: 30);
    try {
      final HttpClientRequest req = await hc.openUrl('PUT', Uri.parse(url));
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
        throw VaultError('put',
            'R2 refused the film (HTTP $code). The signed link may have '
            'expired - try publishing again straight after picking.');
      }
    } on VaultError {
      rethrow;
    } catch (e) {
      throw VaultError('put', adminDetail(e));
    } finally {
      hc.close(force: true);
    }
    return key;
  }

  /// SPRINT 24j - the same journey as uploadVideo, but for a file the
  /// app already holds in memory (audio, and anything picked as bytes
  /// rather than as a path). Supabase's free tier gives 1 GB of
  /// storage and charges for egress; R2 gives 10 GB and charges
  /// nothing to serve it. Voice notes belong here, not there.
  ///
  /// Returns the vault key to store on the post with media_source
  /// 'r2'. open_post signs a GET for whoever is allowed to listen.
  Future<String> uploadBytes({
    required Uint8List bytes,
    required String name,
    void Function(double progress)? onProgress,
  }) async {
    final String safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String key = 'vault/${stamp}_$safe';
    final String ct = _contentType(safe);
    final int total = bytes.length;

    if (total == 0) {
      throw VaultError('put', 'That file came back empty. Pick it again.');
    }

    final Map<String, dynamic> signed = await _call('put', <String, dynamic>{
      'key': key,
      'size': total,
      'content_type': ct,
    });

    final String? url = signed['url'] as String?;
    if (url == null || url.isEmpty) {
      throw VaultError('put', 'r2-vault did not return an upload link. '
          'Check the R2 secrets are set on the function.');
    }

    // Sent in slices so the progress line moves on a slow connection
    // instead of sitting still and looking frozen.
    const int slice = 256 * 1024;
    final HttpClient hc = HttpClient();
    hc.connectionTimeout = const Duration(seconds: 30);
    try {
      final HttpClientRequest req = await hc.openUrl('PUT', Uri.parse(url));
      req.headers.set('Content-Type', ct);
      req.contentLength = total;
      req.persistentConnection = false;

      int sent = 0;
      double last = 0;
      while (sent < total) {
        final int end = (sent + slice) > total ? total : (sent + slice);
        req.add(bytes.sublist(sent, end));
        sent = end;
        final double prog = sent / total;
        if (prog - last >= 0.04 || sent == total) {
          last = prog;
          onProgress?.call(prog);
        }
      }

      final HttpClientResponse res = await req.close();
      final int code = res.statusCode;
      await res.drain<void>();
      if (code >= 300) {
        throw VaultError('put',
            'R2 refused the file (HTTP $code). The signed link may have '
            'expired - try publishing again straight after picking.');
      }
    } on VaultError {
      rethrow;
    } catch (e) {
      throw VaultError('put', adminDetail(e));
    } finally {
      hc.close(force: true);
    }
    return key;
  }

  /// Uploads a published post photo or cover into the separate public R2
  /// bucket. The server returns a short-lived PUT link and the stable HTTPS
  /// custom-domain URL to save on the post. Private profile/proof photos do
  /// not use this path.
  Future<String> uploadPublicImageBytes({
    required Uint8List bytes,
    required String name,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (folder != 'images' && folder != 'thumbs') {
      throw VaultError('put_public_image', 'That image folder is not allowed.');
    }
    if (bytes.isEmpty || bytes.length > 48 * 1024 * 1024) {
      throw VaultError('put_public_image',
          'Choose a JPEG, PNG, WebP or GIF image under 48 MB.');
    }
    String safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (safe.length > 120) safe = safe.substring(safe.length - 120);
    final String key =
        '$folder/${DateTime.now().microsecondsSinceEpoch}_$safe';
    final String ct = _contentType(safe);
    if (!ct.startsWith('image/')) {
      throw VaultError('put_public_image',
          'Choose a JPEG, PNG, WebP or GIF image.');
    }

    final Map<String, dynamic> signed = await _call(
      'put_public_image',
      <String, dynamic>{'key': key, 'size': bytes.length, 'content_type': ct},
    );
    final String? uploadUrl = signed['url'] as String?;
    final String? publicUrl = signed['public_url'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty ||
        publicUrl == null || publicUrl.isEmpty ||
        Uri.tryParse(publicUrl)?.scheme != 'https') {
      throw VaultError('put_public_image',
          'The image store did not return its upload and display addresses.');
    }

    const int slice = 256 * 1024;
    final HttpClient hc = HttpClient();
    hc.connectionTimeout = const Duration(seconds: 30);
    try {
      final HttpClientRequest req =
          await hc.openUrl('PUT', Uri.parse(uploadUrl));
      req.headers.set('Content-Type', ct);
      req.contentLength = bytes.length;
      req.persistentConnection = false;
      int sent = 0;
      double last = 0;
      while (sent < bytes.length) {
        final int end = (sent + slice) > bytes.length
            ? bytes.length
            : sent + slice;
        req.add(bytes.sublist(sent, end));
        sent = end;
        final double progress = sent / bytes.length;
        if (progress - last >= 0.04 || sent == bytes.length) {
          last = progress;
          onProgress?.call(progress);
        }
      }
      final HttpClientResponse res = await req.close();
      final int code = res.statusCode;
      await res.drain<void>();
      if (code >= 300) {
        throw VaultError('put_public_image',
            'R2 refused the image (HTTP $code). Please retry.');
      }
    } on VaultError {
      rethrow;
    } catch (e) {
      throw VaultError('put_public_image', adminDetail(e));
    } finally {
      hc.close(force: true);
    }
    return publicUrl;
  }

  /// Shared bytes in the private Vault and public-media bucket. Null on
  /// a hiccup - the caller then stays quiet.
  Future<int?> usedBytes() async {
    try {
      final Map<String, dynamic> d = await _call('usage', <String, dynamic>{});
      return (d['used'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Every managed R2 object, including published images, with the post
  /// (if any) that points at it. The manager requires on-screen approval
  /// before anything is removed.
  ///
  /// SPRINT 24b: this now THROWS on failure instead of returning an
  /// empty list. An empty Vault and a broken Vault are not the same
  /// thing and must never look the same.
  Future<List<VaultItem>> items() async {
    final Map<String, dynamic> d = await _call('list', <String, dynamic>{});
    final List<dynamic> rows = d['items'] as List<dynamic>? ?? <dynamic>[];
    return rows.map((dynamic r) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(r as Map);
      return VaultItem(
        key: (m['key'] ?? '').toString(),
        size: ((m['size'] as num?) ?? 0).toInt(),
        modified: (m['modified'] as String?) ?? '',
        postId: (m['post_id'] as num?)?.toInt(),
        postTitle: m['post_title'] as String?,
        isPublicImage: (m['is_public_image'] as bool?) ?? false,
        isCoverImage: (m['is_cover_image'] as bool?) ?? false,
      );
    }).toList();
  }

  /// Only ever called after the house taps delete and confirms.
  Future<void> remove(String key) async {
    await _call('delete', <String, dynamic>{'key': key});
  }

  /// A member-side signed GET for a vault post, straight from the
  /// edge (which re-checks can_open_post as that member).
  Future<String?> openUrl(int postId) async {
    try {
      final Map<String, dynamic> d =
          await _call('get', <String, dynamic>{'post_id': postId});
      return d['url'] as String?;
    } catch (_) {
      return null;
    }
  }
}

// END OF FILE - lib/services/vault_service.dart

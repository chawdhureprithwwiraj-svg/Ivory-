import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';

class _SignedAvatar {
  const _SignedAvatar(this.url, this.validUntil);
  final String url;
  final DateTime validUntil;
}

class ProfilePhotoService {
  ProfilePhotoService._();
  static final ProfilePhotoService instance = ProfilePhotoService._();

  static const String bucket = 'profile-photos';
  static const int _maxBytes = 5 * 1024 * 1024;
  static const int _signedUrlSeconds = 7 * 24 * 60 * 60;

  SupabaseClient get _db => Supabase.instance.client;
  final Map<String, _SignedAvatar> _urlCache = <String, _SignedAvatar>{};

  Future<String?> pickAndUpload() async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) throw StateError('Sign in to add a profile photo.');
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 86,
    );
    if (image == null) return null;

    final String extension = image.name.split('.').last.toLowerCase();
    final String contentType;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      default:
        throw StateError('Choose a JPEG, PNG or WebP photo.');
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty || bytes.length > _maxBytes) {
      throw StateError('Choose a photo smaller than 5 MB.');
    }
    final String path =
        '$uid/${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _db.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return path;
  }

  Future<String?> signedAvatarUrl(String path, {bool refresh = false}) async {
    if (path.trim().isEmpty || path.contains('://')) return null;
    final _SignedAvatar? cached = _urlCache[path];
    if (!refresh && cached != null &&
        cached.validUntil.isAfter(DateTime.now())) {
      return cached.url;
    }
    try {
      final String url = await _db.storage
          .from(bucket)
          .createSignedUrl(path, _signedUrlSeconds);
      _urlCache[path] = _SignedAvatar(
        url,
        DateTime.now().add(const Duration(days: 6, hours: 23)),
      );
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<List<LiveMessage>> resolveLiveMessageAvatars(
    List<LiveMessage> messages,
  ) async {
    final Set<String> paths = messages
        .map((LiveMessage m) => m.senderAvatarPath)
        .whereType<String>()
        .where((String path) => path.isNotEmpty)
        .toSet();
    final Map<String, String?> urls = <String, String?>{};
    await Future.wait(paths.map((String path) async {
      urls[path] = await signedAvatarUrl(path);
    }));
    return messages
        .map((LiveMessage m) =>
            m.withSenderAvatarUrl(urls[m.senderAvatarPath]))
        .toList();
  }

  Future<void> deleteOwnPhoto(String path) async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null || !path.startsWith('$uid/')) return;
    await _db.storage.from(bucket).remove(<String>[path]);
    _urlCache.remove(path);
  }
}

// END OF FILE - lib/services/profile_photo_service.dart

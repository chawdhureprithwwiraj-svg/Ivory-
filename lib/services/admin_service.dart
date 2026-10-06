import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/media_ref.dart';

/// ============================================================
/// THE ADMIN STUDIO SERVICE
///
/// Everything the administrator can do to the library from the phone:
/// upload a file, publish a post, re-price a tier. Every call is also
/// re-checked by Postgres (is_admin()), so nothing here is a security
/// boundary - it is only the convenience layer.
/// ============================================================
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  SupabaseClient get _db => Supabase.instance.client;

  static const String mediaBucket = 'media';

  // =================================================================
  // 1. PICKING A FILE OFF THE PHONE
  // =================================================================

  /// What the composer needs to know about a chosen file before upload.
  /// Kept deliberately small so it works for both pickers.
  Future<PickedMedia?> pickImage({bool fromCamera = false}) async {
    final XFile? x = await ImagePicker().pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2000,
    );
    if (x == null) return null;
    return PickedMedia(
      name: x.name,
      bytes: await x.readAsBytes(),
    );
  }

  Future<PickedMedia?> pickVideo({bool fromCamera = false}) async {
    final XFile? x = await ImagePicker().pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(minutes: 30),
    );
    if (x == null) return null;
    return PickedMedia(
      name: x.name,
      bytes: await File(x.path).readAsBytes(),
    );
  }

  /// Path-only video pick. The bytes stay on disk - a Vault video
  /// can be a gigabyte and must never be read into memory.
  Future<VaultPick?> pickVideoPath() async {
    final XFile? x = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 120),
    );
    if (x == null) return null;
    final File f = File(x.path);
    if (!await f.exists()) return null;
    return VaultPick(path: x.path, name: x.name, size: await f.length());
  }

  /// Audio, documents, anything. file_selector is the Flutter team's own
  /// plugin, so it keeps pace with each Android SDK instead of lagging a
  /// year behind the way the community pickers do.
  Future<PickedMedia?> pickFile({bool audioOnly = false}) async {
    const XTypeGroup audioGroup = XTypeGroup(
      label: 'Audio',
      extensions: <String>['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'],
      mimeTypes: <String>['audio/*'],
    );
    const XTypeGroup anyGroup = XTypeGroup(label: 'Any file');

    final XFile? x = await openFile(
      acceptedTypeGroups: <XTypeGroup>[audioOnly ? audioGroup : anyGroup],
    );
    if (x == null) return null;

    final Uint8List bytes = await x.readAsBytes();
    if (bytes.isEmpty) return null;
    return PickedMedia(name: x.name, bytes: bytes);
  }

  // =================================================================
  // 2. UPLOADING TO SUPABASE STORAGE
  // =================================================================

  /// Uploads into the public "media" bucket and returns the finished
  /// public URL - unless [private] is set, in which case the file goes
  /// to the private "vault" bucket and the raw path is returned. A
  /// playable signed URL for vault files is handed out later by
  /// open_post(), and only to a member who may open the post.
  ///
  /// [folder] keeps the bucket tidy: images/, audio/, video/, thumbs/.
  Future<String> upload(
    PickedMedia media, {
    String folder = 'uploads',
    bool private = false,
  }) async {
    final String bucket = private ? 'vault' : mediaBucket;
    final String safe = _safeName(media.name);
    final String path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}_$safe';

    await _db.storage.from(bucket).uploadBinary(
          path,
          media.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(safe),
            upsert: true,
          ),
        );

    return private ? path : _db.storage.from(bucket).getPublicUrl(path);
  }

  static String _safeName(String name) {
    final String cleaned = name
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return cleaned.length <= 60
        ? cleaned
        : cleaned.substring(cleaned.length - 60);
  }

  static String _contentType(String name) {
    final String e = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    switch (e) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
      case 'aac':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
      case 'opus':
        return 'audio/ogg';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// A friendly size string for the composer: "4.2 MB".
  static String sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // =================================================================
  // 3. PUBLISHING
  // =================================================================

  /// Creates the post (and its poll options) in one database call. The
  /// existing announce trigger then writes the notification and queues
  /// the device push, so publishing really is one tap.
  /// The two dials a post can carry: what it costs on its own, and
  /// the tier that opens it without paying. Setting a price of 0
  /// clears both and hands the post back to the tier rule.
  Future<void> setPostPrice({
    required int postId,
    required int priceInr,
    int? freeFromTier,
  }) async {
    await _db.rpc<dynamic>('set_post_price', params: <String, dynamic>{
      'post_id_in': postId,
      'price_in': priceInr,
      'free_from_in': priceInr > 0 ? freeFromTier : null,
    });
  }

  Future<int> publishPost({
    required String type,
    required String title,
    String? summary,
    String? body,
    MediaSource mediaSource = MediaSource.none,
    String? mediaRef,
    MediaSource thumbSource = MediaSource.none,
    String? thumbRef,
    int tierRequired = 0,
    int? durationSecs,
    List<String>? pollOptions,
    bool isPublished = true,
  }) async {
    final dynamic id = await _db.rpc(
      'publish_post',
      params: <String, dynamic>{
        'type_in': type,
        'title_in': title,
        'summary_in': (summary == null || summary.trim().isEmpty)
            ? null
            : summary.trim(),
        'body_in':
            (body == null || body.trim().isEmpty) ? null : body.trim(),
        'media_source_in': mediaSource.dbValue,
        'media_ref_in': (mediaRef == null || mediaRef.trim().isEmpty)
            ? null
            : mediaRef.trim(),
        'thumb_source_in': thumbSource.dbValue,
        'thumb_ref_in': (thumbRef == null || thumbRef.trim().isEmpty)
            ? null
            : thumbRef.trim(),
        'tier_required_in': tierRequired,
        'duration_secs_in': durationSecs,
        'poll_options_in': pollOptions,
        'is_published_in': isPublished,
      },
    );
    return (id as num).toInt();
  }

  /// Everything in the library, published or not.
  Future<List<Map<String, dynamic>>> fetchLibrary({int limit = 40}) async {
    final List<dynamic> rows = await _db
        .from('admin_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> setPublished(int postId, bool value) =>
      _db.rpc('set_post_published', params: <String, dynamic>{
        'post_id_in': postId,
        'value_in': value,
      });

  Future<void> deletePost(int postId) =>
      _db.rpc('delete_post', params: <String, dynamic>{'post_id_in': postId});

  // =================================================================
  // 4. TIERS
  // =================================================================

  /// Every tier, including the switched-off ones, for the manager screen.
  Future<List<Map<String, dynamic>>> fetchAllTiers() async {
    final List<dynamic> rows = await _db
        .from('subscription_tiers')
        .select()
        .order('level', ascending: true);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> saveTier({
    required int id,
    required String name,
    required int level,
    required int priceInr,
    required int durationDays,
    String? description,
    List<String>? perks,
    required bool isActive,
  }) async {
    await _db.from('subscription_tiers').update(<String, dynamic>{
      'name': name.trim(),
      'level': level,
      'price_inr': priceInr,
      'duration_days': durationDays,
      'description': description?.trim(),
      if (perks != null) 'perks': perks,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> createTier({
    required String name,
    required int level,
    required int priceInr,
    int durationDays = 30,
    String? description,
    List<String> perks = const <String>[],
  }) async {
    await _db.from('subscription_tiers').insert(<String, dynamic>{
      'name': name.trim(),
      'level': level,
      'price_inr': priceInr,
      'duration_days': durationDays,
      'description': description?.trim(),
      'perks': perks,
      'is_active': true,
    });
  }

  /// Tiers are never deleted - history would break. They are retired.
  Future<void> setTierActive(int id, bool value) async {
    await _db
        .from('subscription_tiers')
        .update(<String, dynamic>{'is_active': value}).eq('id', id);
  }
}

/// A file chosen on the phone but not yet uploaded.
class PickedMedia {
  const PickedMedia({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
  String get sizeLabel => AdminService.sizeLabel(size);
}

/// A big video chosen for the Vault: path and size only, no bytes.
class VaultPick {
  const VaultPick(
      {required this.path, required this.name, required this.size});

  final String path;
  final String name;
  final int size;

  String get sizeLabel => AdminService.sizeLabel(size);
}

// END OF FILE - lib/services/admin_service.dart

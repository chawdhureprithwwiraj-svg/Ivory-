import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../services/b2_media_service.dart';
import '../services/vault_service.dart';
import 'admin_attach_panel.dart';

/// Upload routes (CC.233): every slot honours the visible R2/B2 choice.
/// Images and covers: B2 private, R2 private, or - published only - R2
/// public by URL. Video/voice: private R2 or B2, choice required. Other
/// types follow the media choice, defaulting to R2 as before. Drafts
/// never go public R2. Profile/payment files are untouched.
class ResolvedMedia {
  const ResolvedMedia({
    this.ref,
    this.source = MediaSource.none,
    this.thumbRef,
    this.thumbSource = MediaSource.none,
  });
  final String? ref;
  final MediaSource source;
  final String? thumbRef;
  final MediaSource thumbSource;
}

MediaSource _source(String storage) {
  switch (storage) {
    case 'b2':
      return MediaSource.b2;
    case 'r2':
    case 'r2pub':
      return MediaSource.r2;
    default:
      return MediaSource.supabase;
  }
}

Future<ResolvedMedia> resolvePublishMedia({
  required String type,
  required AdminAttachPanelState? at,
  required bool hasLink,
  required bool isPublished,
  required void Function(String label) onStatus,
}) async {
  final String imageChoice = at?.imageProvider ?? 'b2';
  final String? mediaChoice = at?.mediaProvider;
  if ((type == 'audio' || type == 'video') &&
      (at?.picked != null || at?.vaultPath != null) &&
      mediaChoice == null) {
    throw StateError('Choose R2 or B2 storage before uploading this file.');
  }
  final String desiredMedia = type == 'image'
      ? (imageChoice == 'r2pub' && isPublished
          ? 'r2pub'
          : (imageChoice == 'r2' ? 'r2' : 'b2'))
      : ((type == 'audio' || type == 'video')
          ? (mediaChoice ?? '')
          : (mediaChoice ?? 'r2'));

  String? mediaRef = at?.uploadedUrl;
  String? mediaStorage = at?.uploadedSource;
  if (at != null &&
      (at.picked != null || at.vaultPath != null) &&
      mediaRef != null &&
      mediaStorage != desiredMedia) {
    mediaRef = null;
  }

  if (at != null && at.vaultPath != null && mediaRef == null) {
    onStatus('Preparing ${desiredMedia.toUpperCase()}...');
    if (desiredMedia == 'b2') {
      mediaRef = await B2MediaService.instance.uploadFile(
        path: at.vaultPath!,
        name: at.vaultName ?? 'video.mp4',
        kind: 'video',
        onProgress: (double p) =>
            onStatus('Private B2 ${(p * 100).round()}% - keep open'),
      );
    } else {
      mediaRef = await VaultService.instance.uploadVideo(
        path: at.vaultPath!,
        name: at.vaultName ?? 'video.mp4',
        onProgress: (double p) =>
            onStatus('Private R2 ${(p * 100).round()}% - keep open'),
      );
    }
    mediaStorage = desiredMedia;
    at.setUploadedUrl(mediaRef, source: mediaStorage ?? desiredMedia);
  }

  if (at != null && at.picked != null && mediaRef == null) {
    final PickedMedia file = at.picked!;
    if (type == 'image') {
      if (desiredMedia == 'r2') {
        onStatus('Saving private R2 photo...');
        mediaRef = await VaultService.instance.uploadBytes(
          bytes: file.bytes,
          name: file.name,
          onProgress: (double p) =>
              onStatus('Private R2 ${(p * 100).round()}% - keep open'),
        );
      } else if (desiredMedia == 'b2') {
        onStatus('Saving private B2 photo...');
        mediaRef = await B2MediaService.instance.uploadBytes(
          bytes: file.bytes,
          name: file.name,
          kind: 'image',
          onProgress: (double p) =>
              onStatus('Private B2 ${(p * 100).round()}% - keep open'),
        );
      } else if (desiredMedia == 'r2pub') {
        onStatus('Preparing published photo for public R2...');
        mediaRef = await VaultService.instance.uploadPublicImageBytes(
          bytes: file.bytes,
          name: file.name,
          folder: 'images',
          onProgress: (double p) =>
              onStatus('Public R2 ${(p * 100).round()}% - keep open'),
        );
      }
    } else if (type == 'audio' || type == 'video') {
      if (desiredMedia == 'b2') {
        mediaRef = await B2MediaService.instance.uploadBytes(
          bytes: file.bytes,
          name: file.name,
          kind: type,
          onProgress: (double p) =>
              onStatus('Private B2 ${(p * 100).round()}% - keep open'),
        );
      } else {
        mediaRef = await VaultService.instance.uploadBytes(
          bytes: file.bytes,
          name: file.name,
          onProgress: (double p) =>
              onStatus('Private R2 ${(p * 100).round()}% - keep open'),
        );
      }
    } else {
      mediaRef = await VaultService.instance.uploadBytes(
        bytes: file.bytes,
        name: file.name,
        onProgress: (double p) =>
            onStatus('R2 ${(p * 100).round()}% - keep open'),
      );
    }
    mediaStorage = desiredMedia;
    at.setUploadedUrl(mediaRef, source: mediaStorage ?? desiredMedia);
  }

  MediaSource mediaSource = MediaSource.none;
  if (mediaRef != null) {
    mediaSource = _source(mediaStorage ?? desiredMedia);
  } else if (hasLink && at != null) {
    final MediaRef parsed = MediaRef.parse(at.link.text.trim());
    mediaSource = parsed.source;
    mediaRef = parsed.ref;
  }

  final String desiredThumb = imageChoice == 'r2pub' && isPublished
      ? 'r2pub'
      : (imageChoice == 'r2' ? 'r2' : 'b2');
  String? thumbRef = at?.uploadedThumbUrl;
  String? thumbStorage = at?.uploadedThumbSource;
  if (at != null &&
      at.thumb != null &&
      thumbRef != null &&
      thumbStorage != desiredThumb) {
    thumbRef = null;
  }
  if (at != null && at.thumb != null && thumbRef == null) {
    if (desiredThumb == 'r2') {
      onStatus('Saving private R2 cover...');
      thumbRef = await VaultService.instance.uploadBytes(
        bytes: at.thumb!.bytes,
        name: at.thumb!.name,
        onProgress: (double p) =>
            onStatus('Private R2 cover ${(p * 100).round()}% - keep open'),
      );
    } else if (desiredThumb == 'b2') {
      onStatus('Saving private B2 cover...');
      thumbRef = await B2MediaService.instance.uploadBytes(
        bytes: at.thumb!.bytes,
        name: at.thumb!.name,
        kind: 'cover',
        onProgress: (double p) =>
            onStatus('Private B2 cover ${(p * 100).round()}% - keep open'),
      );
    } else if (desiredThumb == 'r2pub') {
      onStatus('Preparing public R2 cover...');
      thumbRef = await VaultService.instance.uploadPublicImageBytes(
        bytes: at.thumb!.bytes,
        name: at.thumb!.name,
        folder: 'thumbs',
        onProgress: (double p) =>
            onStatus('Public R2 cover ${(p * 100).round()}% - keep open'),
      );
    }
    thumbStorage = desiredThumb;
    at.setUploadedThumbUrl(thumbRef, source: thumbStorage ?? desiredThumb);
  }

  return ResolvedMedia(
    ref: mediaRef,
    source: mediaRef == null
        ? MediaSource.none
        : (hasLink && at != null && mediaStorage == null
              ? mediaSource
              : _source(mediaStorage ?? desiredMedia)),
    thumbRef: thumbRef,
    thumbSource: thumbRef == null
        ? MediaSource.none
        : _source(thumbStorage ?? desiredThumb),
  );
}

// END OF FILE - lib/screens/admin_publish_media.dart

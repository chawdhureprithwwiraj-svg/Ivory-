import '../models/media_ref.dart';
import '../services/admin_service.dart';
import '../services/vault_service.dart';
import 'admin_attach_panel.dart';

/// ============================================================
/// IVORY - WHERE A FILE GOES WHEN YOU PRESS PUBLISH
///
/// SPRINT 24j. Lifted whole out of admin_create_tab.dart, which
/// had reached the 18 KB paste ceiling. Nothing about the
/// behaviour changed in the move; it simply lives somewhere it
/// can breathe, and the composer can grow again.
///
/// WHERE THINGS LAND, AND WHY
///
///   film, any size   -> Cloudflare R2 (the Vault)
///   voice note       -> Cloudflare R2 (the Vault)
///   photograph       -> Supabase Storage, public
///   cover image      -> Supabase Storage, public
///   a pasted link    -> nowhere; the link is stored as given
///
/// R2 gives 10 GB free and, the part that matters, charges
/// nothing to serve it - a hundred members watching the same
/// film costs zero. Supabase gives 1 GB and bills for egress, so
/// only the small public things stay there.
///
/// Photographs stay on Supabase on purpose: the home feed paints
/// them straight from a public URL. An R2 object has no public
/// URL - every view would need the edge function to sign one
/// first, which for a feed of twenty cards means twenty round
/// trips before anything appears. Films and voice notes do not
/// have that problem: they are only ever opened one at a time,
/// and `open_post` signs them on the way in.
/// ============================================================

/// Everything the composer needs to write onto the new post.
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

/// Uploads whatever the attach panel is holding and reports where
/// it ended up. [onStatus] drives the line on the publish button;
/// it is already safe to call - the composer checks `mounted`.
///
/// Throws on failure. The composer catches and shows the message.
Future<ResolvedMedia> resolvePublishMedia({
  required String type,
  required AdminAttachPanelState? at,
  required bool hasLink,
  required void Function(String label) onStatus,
}) async {
  String? mediaRef = at?.uploadedUrl;
  MediaSource mediaSource = MediaSource.none;
  bool vaulted = false;

  // ---- a film picked by path: streamed, never held in memory ----
  if (at != null && at.vaultPath != null && mediaRef == null) {
    onStatus('Opening the Vault...');
    mediaRef = await VaultService.instance.uploadVideo(
      path: at.vaultPath!,
      name: at.vaultName ?? 'video.mp4',
      onProgress: (double p) =>
          onStatus('Vault ${(p * 100).round()}% - keep open'),
    );
    vaulted = true;
  }

  // ---- a file the app already holds as bytes ----
  if (at != null && at.picked != null && mediaRef == null) {
    final PickedMedia file = at.picked!;

    if (type == 'image') {
      onStatus('Uploading ${file.sizeLabel}...');
      mediaRef = await AdminService.instance.upload(
        file,
        folder: 'images',
        private: false,
      );
      // Only a public URL is worth remembering. Caching an R2 key
      // here would make a retried publish file it as a Supabase
      // object, and the member would be handed a dead link.
      at.setUploadedUrl(mediaRef);
    } else {
      mediaRef = await VaultService.instance.uploadBytes(
        bytes: file.bytes,
        name: file.name,
        onProgress: (double p) =>
            onStatus('Vault ${(p * 100).round()}% - keep open'),
      );
      vaulted = true;
    }
  }

  if (mediaRef != null) {
    mediaSource = vaulted ? MediaSource.r2 : MediaSource.supabase;
  } else if (hasLink && at != null) {
    final MediaRef parsed = MediaRef.parse(at.link.text.trim());
    mediaSource = parsed.source;
    mediaRef = parsed.ref;
  }

  // ---- the optional cover image ----
  String? thumbRef = at?.uploadedThumbUrl;
  MediaSource thumbSource = MediaSource.none;
  if (at != null && at.thumb != null && thumbRef == null) {
    onStatus('Uploading the cover...');
    thumbRef = await AdminService.instance.upload(at.thumb!, folder: 'thumbs');
    at.setUploadedThumbUrl(thumbRef);
  }
  if (thumbRef != null) thumbSource = MediaSource.supabase;

  return ResolvedMedia(
    ref: mediaRef,
    source: mediaSource,
    thumbRef: thumbRef,
    thumbSource: thumbSource,
  );
}

// END OF FILE - lib/screens/admin_publish_media.dart

/// IVORY - PROVIDER-AGNOSTIC MEDIA LAYER
///
/// Ivory never assumes where a video or image is hosted. A post stores a
/// [MediaSource] plus an opaque reference string, and this file turns that
/// pair into something playable or displayable.
///
/// This means you can start on free YouTube hosting today, put images on
/// Telegram, and migrate premium video to Cloudflare R2 later - without
/// rewriting a single screen. Mixed sources can coexist in the same feed.
library;

enum MediaSource {
  youtube,
  telegram,
  telegramChannel,
  r2,
  supabase,
  direct,
  vimeo,
  dailymotion,
  none;

  /// Column values use snake_case to match the database check constraint.
  String get dbValue =>
      this == MediaSource.telegramChannel ? 'telegram_channel' : name;

  static MediaSource fromDb(String? value) {
    if (value == null) return MediaSource.none;
    if (value == 'telegram_channel') return MediaSource.telegramChannel;
    return MediaSource.values.firstWhere(
      (MediaSource s) => s.name == value,
      orElse: () => MediaSource.none,
    );
  }

  /// Human label for the admin uploader.
  String get label {
    switch (this) {
      case MediaSource.youtube:
        return 'YouTube (unlisted)';
      case MediaSource.telegram:
        return 'Telegram file (under 20 MB)';
      case MediaSource.telegramChannel:
        return 'Private Telegram channel';
      case MediaSource.r2:
        return 'Cloudflare R2';
      case MediaSource.supabase:
        return 'Supabase Storage';
      case MediaSource.direct:
        return 'Direct link';
      case MediaSource.vimeo:
        return 'Vimeo';
      case MediaSource.dailymotion:
        return 'Dailymotion';
      case MediaSource.none:
        return 'No media';
    }
  }

  /// True when playback happens inside an embedded web player rather than
  /// a native video widget.
  bool get needsEmbedPlayer =>
      this == MediaSource.youtube ||
      this == MediaSource.vimeo ||
      this == MediaSource.dailymotion;

  /// Telegram's Bot API refuses to serve files over 20 MB, so long videos
  /// can never be streamed from it. Enforced in the admin uploader.
  bool get supportsLongVideo => this != MediaSource.telegram;

  /// Playback happens in an external app rather than inside Ivory.
  /// Telegram streams the full file itself, so the 20 MB Bot API limit
  /// does not apply here.
  bool get opensExternally => this == MediaSource.telegramChannel;
}

/// A resolved pointer to one piece of media.
class MediaRef {
  const MediaRef({required this.source, required this.ref});

  final MediaSource source;
  final String? ref;

  bool get isEmpty =>
      source == MediaSource.none || ref == null || ref!.trim().isEmpty;

  /// The YouTube/Vimeo/Dailymotion video id, for embed players.
  String? get embedId => source.needsEmbedPlayer ? ref : null;

  /// A plain https URL for native players and Image.network.
  /// Returns null for sources that must go through an embed player.
  ///
  /// [supabasePublicBase] is your project's public storage URL, e.g.
  /// https://xxxx.supabase.co/storage/v1/object/public/media
  String? directUrl({String? supabasePublicBase}) {
    final String? r = ref;
    if (r == null || r.trim().isEmpty) return null;

    switch (source) {
      case MediaSource.r2:
      case MediaSource.direct:
        return r.startsWith('http') ? r : null;
      case MediaSource.supabase:
        if (r.startsWith('http')) return r;
        if (supabasePublicBase == null) return null;
        return '${supabasePublicBase.replaceAll(RegExp(r'/$'), '')}/$r';
      case MediaSource.telegram:
        // Resolved at runtime via a bot call; only valid for files <20MB.
        return null;
      case MediaSource.telegramChannel:
        // Opened in the Telegram app, never fetched by Ivory.
        return null;
      case MediaSource.youtube:
      case MediaSource.vimeo:
      case MediaSource.dailymotion:
      case MediaSource.none:
        return null;
    }
  }

  /// YouTube gives free thumbnails for every video - useful even when the
  /// video itself is hosted elsewhere.
  String? get youtubeThumbnail => source == MediaSource.youtube && ref != null
      ? 'https://img.youtube.com/vi/$ref/hqdefault.jpg'
      : null;

  /// Watch page URL, for an "open externally" fallback button.
  String? get externalUrl {
    final String? r = ref;
    if (r == null) return null;
    switch (source) {
      case MediaSource.youtube:
        return 'https://www.youtube.com/watch?v=$r';
      case MediaSource.vimeo:
        return 'https://vimeo.com/$r';
      case MediaSource.dailymotion:
        return 'https://www.dailymotion.com/video/$r';
      case MediaSource.r2:
      case MediaSource.direct:
      case MediaSource.supabase:
        return r.startsWith('http') ? r : null;
      case MediaSource.telegramChannel:
        // t.me deep link to the exact post inside the private channel.
        if (r.startsWith('http')) return r;
        final List<String> parts = r.split(':');
        if (parts.length == 2) {
          return 'https://t.me/c/${parts[0]}/${parts[1]}';
        }
        return 'https://t.me/c/$r';
      case MediaSource.telegram:
      case MediaSource.none:
        return null;
    }
  }

  /// Pastes a link from ANY supported provider and works out what it is.
  /// This is what powers the admin uploader: you paste a link, Ivory
  /// figures out the source and extracts the id automatically.
  static MediaRef parse(String input) {
    final String s = input.trim();
    if (s.isEmpty) return const MediaRef(source: MediaSource.none, ref: null);

    // ---- YouTube: many URL shapes all carry the same 11-char id ----
    final RegExp yt = RegExp(
      r'(?:youtube\.com/(?:watch\?(?:.*&)?v=|embed/|shorts/|live/)|youtu\.be/)([A-Za-z0-9_-]{11})',
    );
    final RegExpMatch? ytMatch = yt.firstMatch(s);
    if (ytMatch != null) {
      return MediaRef(source: MediaSource.youtube, ref: ytMatch.group(1));
    }
    // A bare 11-character id pasted on its own.
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(s)) {
      return MediaRef(source: MediaSource.youtube, ref: s);
    }

    // ---- Vimeo ----
    final RegExpMatch? vimeo =
        RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(s);
    if (vimeo != null) {
      return MediaRef(source: MediaSource.vimeo, ref: vimeo.group(1));
    }

    // ---- Dailymotion ----
    final RegExpMatch? dm =
        RegExp(r'dailymotion\.com/video/([A-Za-z0-9]+)').firstMatch(s);
    if (dm != null) {
      return MediaRef(source: MediaSource.dailymotion, ref: dm.group(1));
    }

    // ---- Telegram: private channel post links look like
    //      https://t.me/c/1234567890/42
    final RegExpMatch? tg =
        RegExp(r't\.me/c/(\d+)/(\d+)').firstMatch(s);
    if (tg != null) {
      return MediaRef(
        source: MediaSource.telegramChannel,
        ref: '${tg.group(1)}:${tg.group(2)}',
      );
    }
    // Invite links (https://t.me/+AbCdEf...) and public @channel links.
    if (s.contains('t.me/')) {
      return MediaRef(source: MediaSource.telegramChannel, ref: s);
    }

    // ---- Cloudflare R2 / generic direct file ----
    if (s.startsWith('http')) {
      if (s.contains('.r2.dev') || s.contains('r2.cloudflarestorage.com')) {
        return MediaRef(source: MediaSource.r2, ref: s);
      }
      if (s.contains('/storage/v1/object/public/')) {
        return MediaRef(source: MediaSource.supabase, ref: s);
      }
      return MediaRef(source: MediaSource.direct, ref: s);
    }

    // Anything else is treated as a path inside the Supabase media bucket.
    return MediaRef(source: MediaSource.supabase, ref: s);
  }

  /// Warns the admin when a chosen source cannot physically work.
  /// Returns null when the pairing is fine.
  static String? validateForLongVideo(MediaRef ref) {
    if (ref.source == MediaSource.telegram) {
      return 'Telegram bots can only serve files under 20 MB, so a full '
          'episode cannot stream inside Ivory. Either link the post in a '
          'private channel instead (it plays in the Telegram app with no '
          'size limit), or use YouTube or R2.';
    }
    if (ref.isEmpty) {
      return 'Paste a video link first.';
    }
    return null;
  }

  @override
  String toString() => '${source.name}:$ref';
}

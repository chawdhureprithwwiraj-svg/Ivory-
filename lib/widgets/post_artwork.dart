import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../theme/ivory_theme.dart';
import 'ivory_media_view.dart';

/// Ivory is portrait-first: artwork starts life as a 9:16 frame and
/// then takes the shape of the file that was actually uploaded, clamped
/// between 9:16 and 16:9 so a landscape cover settles into a short wide
/// band instead of being cropped to a slab or stretched.

IconData postActionIcon(PostType t) {
  switch (t) {
    case PostType.video:
      return Icons.play_arrow_rounded;
    case PostType.audio:
      return Icons.headphones;
    case PostType.blog:
      return Icons.menu_book;
    case PostType.image:
      return Icons.image_outlined;
    case PostType.poll:
      return Icons.how_to_vote_outlined;
    case PostType.unknown:
      return Icons.open_in_new;
  }
}

/// The image area, including the blurred treatment for locked posts and
/// a warm typographic panel when a post has no artwork at all.
class PostArtwork extends StatefulWidget {
  const PostArtwork({
    super.key,
    required this.post,
    required this.maxHeight,
  });

  final IvoryPost post;

  /// The tallest this artwork may become. A 9:16 upload fills it; a
  /// 16:9 upload settles into a short wide band all by itself.
  final double maxHeight;

  @override
  State<PostArtwork> createState() => PostArtworkState();
}

class PostArtworkState extends State<PostArtwork> {
  /// Portrait until the real file says otherwise.
  double _ratio = kIvoryPortraitAspect;

  ImageStream? _stream;
  ImageStreamListener? _listener;
  String? _measuring;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure(widget.post.thumbnailFor());
  }

  @override
  void didUpdateWidget(PostArtwork old) {
    super.didUpdateWidget(old);
    _measure(widget.post.thumbnailFor());
  }

  /// Reads the artwork's true dimensions as soon as the first bytes
  /// arrive, so the card can take the shape of the media instead of
  /// forcing every upload into one band.
  void _measure(String? url) {
    if (url == null || url == _measuring) return;
    _measuring = url;
    _detach();
    final ImageStream stream =
        NetworkImage(url).resolve(const ImageConfiguration());
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final int w = info.image.width;
        final int h = info.image.height;
        if (!mounted || h == 0) return;
        final double r = ivoryClampAspect(w / h);
        if ((r - _ratio).abs() > 0.001) setState(() => _ratio = r);
      },
      onError: (Object _, StackTrace? __) {},
    );
    stream.addListener(listener);
    _stream = stream;
    _listener = listener;
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double width =
            box.maxWidth.isFinite ? box.maxWidth : 360.0;
        final bool hasArtwork = widget.post.thumbnailFor() != null;
        // No artwork at all? Do not reserve a tall portrait slab for a
        // placeholder - keep the card compact.
        final double natural = hasArtwork
            ? width / _ratio
            : widget.maxHeight * 0.46;
        final double height = natural < widget.maxHeight
            ? natural
            : widget.maxHeight;
        return SizedBox(
          height: height,
          width: double.infinity,
          child: _build(context, height),
        );
      },
    );
  }

  Widget _build(BuildContext context, double height) {
    final IvoryPost post = widget.post;
    final String? url = post.thumbnailFor();

    final Widget base = url == null
        ? Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: IvoryColors.warmGradient),
            child: Center(
              child: Icon(
                postActionIcon(post.type),
                size: 44,
                color: IvoryColors.burgundy.withValues(alpha: 0.55),
              ),
            ),
          )
        : Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              decoration:
                  const BoxDecoration(gradient: IvoryColors.warmGradient),
              child: Center(
                child: Icon(
                  postActionIcon(post.type),
                  size: 40,
                  color: IvoryColors.burgundy.withValues(alpha: 0.5),
                ),
              ),
            ),
            loadingBuilder: (BuildContext c, Widget child, ImageChunkEvent? p) {
              if (p == null) return child;
              return Container(
                height: height,
                color: IvoryColors.surfaceWarm,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: IvoryColors.amber,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          );

    // A soft burgundy wash at the bottom so overlaid text stays legible.
    final Widget scrim = Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              IvoryColors.burgundy.withValues(alpha: 0.0),
              IvoryColors.burgundy.withValues(alpha: 0.55),
            ],
            stops: const <double>[0.45, 1.0],
          ),
        ),
      ),
    );

    if (!post.isLocked) {
      return Stack(children: <Widget>[base, scrim]);
    }

    // Locked: blur is presentation only. The media link for a locked
    // post is never sent to this device in the first place.
    return Stack(
      children: <Widget>[
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: base,
        ),
        Positioned.fill(
          child: Container(
            color: IvoryColors.cream.withValues(alpha: 0.35),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: IvoryColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: IvoryTheme.softShadow(blur: 14, y: 5),
                    ),
                    child: const Icon(Icons.lock,
                        color: IvoryColors.burgundy, size: 25),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: IvoryColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: IvoryColors.hairlineStrong),
                    ),
                    child: Text(
                      post.isForSale
                          ? 'Open for Rs.${post.priceInr}'
                          : post.tierName != null
                          ? '${post.tierName} members'
                          : 'Members only',
                      style: const TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/post_artwork.dart

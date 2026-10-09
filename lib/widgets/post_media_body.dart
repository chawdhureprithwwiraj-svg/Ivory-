import 'package:flutter/material.dart';

import '../models/ivory_post.dart';
import '../models/media_ref.dart';
import '../theme/ivory_theme.dart';
import 'ivory_media_view.dart';
import 'post_actions.dart';
import 'post_poll.dart';

/// ============================================================
/// A FILM OR A VOICE NOTE, FULL SCREEN.
///
/// Lifted out of post_actions.dart, which had grown past the
/// size that can be pasted reliably on a phone. Nothing about
/// it changed in the move except the name, which had to stop
/// being private in order to cross a file boundary.
///
/// It imports post_actions.dart back, for PostActions.launch()
/// and PostCardIcons. Dart permits two files to import each
/// other and this is the honest way to say what depends on
/// what - the alternative was dragging two unrelated helpers
/// across with it.
/// ============================================================
class PostMediaBody extends StatelessWidget {
  const PostMediaBody({super.key, required this.post});

  final IvoryPost post;

  @override
  Widget build(BuildContext context) {
    // A file Ivory can stream itself: Supabase Storage, Cloudflare R2 or
    // any direct https link. YouTube and Telegram still open outside.
    final String? playable = post.media.directUrl();
    final String? external = post.media.externalUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        IvoryEyebrow(post.type.label, icon: PostCardIcons.of(post.type)),
        const SizedBox(height: 10),
        _doorStamp(post),
        Text(postCleanTitle(post.title),
            style: Theme.of(context).textTheme.headlineLarge),
        if (post.summary != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(post.summary!, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 20),

        // ---- in-app viewing / playback ----
        if (playable != null && post.type == PostType.image)
          IvoryImageView(url: playable)
        else if (playable != null)
          IvoryPlayer(
            url: playable,
            audioOnly: post.type == PostType.audio,
            posterUrl: post.thumbnailFor(),
          )
        else
          Container(
            padding: const EdgeInsets.all(18),
            decoration: IvoryTheme.card(highlighted: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      playable != null
                          ? Icons.play_circle_fill
                          : Icons.open_in_new_rounded,
                      color: IvoryColors.amber,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        playable != null ? 'PLAYS IN IVORY' : 'OPENS OUTSIDE',
                        style: const TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (post.durationLabel != null)
                      Text(
                        post.durationLabel!,
                        style: TextStyle(
                          color: IvoryColors.textFaint,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (external != null)
                  IvoryGradientButton(
                    label: 'WATCH NOW',
                    icon: Icons.play_arrow,
                    onPressed: () => PostActions.launch(context, external),
                  )
                else
                  Text(
                    'No playable link is attached to this post yet.',
                    style: TextStyle(
                      color: IvoryColors.textSoft,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

        // ---- footer line ----
        // SPRINT 24f - PRIVACY.
        // This row used to end in an "Open externally" button that handed
        // the member the raw storage address - the Supabase or Cloudflare
        // R2 URL. One tap and they could see where Ivory keeps its files,
        // which companies it depends on, and the shape of the back end.
        // It is gone. So is the "Streaming inside Ivory" caption, which
        // announced plumbing nobody asked to hear about.
        //
        // What remains is the only fact a member actually wants: how long
        // the piece runs. Nothing here reveals an address.
        if (playable != null && post.durationLabel != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            post.durationLabel!,
            style: TextStyle(
              fontSize: 12.5,
              color: IvoryColors.textFaint,
            ),
          ),
        ],
        postGiftRow(context, post),
      ],
    );
  }
}


/// Tiny helper so the sheets can reuse the card's icon mapping.

// END OF FILE - lib/widgets/post_media_body.dart

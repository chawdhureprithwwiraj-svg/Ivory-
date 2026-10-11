import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/ivory_theme.dart';
import 'member_avatar.dart';
import 'report_sheet.dart';

/// Live chat floats over the broadcast; member avatars and realtime updates
/// remain visible while Ivory's replies keep their distinct styling.
class LiveChat extends StatefulWidget {
  const LiveChat({super.key, required this.sessionId, this.onGift});

  final int sessionId;

  /// A gift line landed in the stream - the room celebrates.
  final void Function(String emoji, String label, String? from)? onGift;

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// How many messages have landed while the member was reading
  /// further up. Zero means they are at the foot and following.
  int _behind = 0;

  List<LiveMessage> _messages = <LiveMessage>[];
  RealtimeChannel? _channel;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = LiveService.instance.watchMessages(
      widget.sessionId,
      _onMessage,
    );
  }

  void _onMessage(LiveMessage m) {
    if (!mounted) return;
    setState(() {
      // The realtime copy may race the one we just inserted.
      if (!_messages.any((LiveMessage x) => x.id == m.id)) {
        _messages.add(m);
      }
    });
    final RegExpMatch? g =
        RegExp('^(\\S+)\\s{2}sent\\s(.+)').firstMatch(m.body);
    if (!m.isHost && g != null) {
      widget.onGift?.call(g.group(1)!, g.group(2)!, m.senderName);
    }
    _toBottom();
    unawaited(_resolveAvatars(<LiveMessage>[m]));
  }

  Future<void> _resolveAvatars(List<LiveMessage> messages) async {
    try {
      final List<LiveMessage> resolved = await ProfilePhotoService.instance
          .resolveLiveMessageAvatars(messages);
      if (!mounted) return;
      final Map<int, LiveMessage> byId = <int, LiveMessage>{
        for (final LiveMessage m in resolved) m.id: m,
      };
      setState(() {
        _messages = _messages
            .map((LiveMessage m) => byId[m.id] ?? m)
            .toList();
      });
    } catch (_) {
      // The message remains readable with its initial instead of a photo.
    }
  }

  Future<void> _load() async {
    try {
      final List<LiveMessage> rows =
          await LiveService.instance.fetchMessages(widget.sessionId);
      if (!mounted) return;
      setState(() => _messages = rows);
      _toBottom();
      unawaited(_resolveAvatars(rows));
    } catch (_) {
      // An empty rail is better than an error during a broadcast.
    }
  }

  /// Is the member already reading the newest words?
  bool get _atFoot {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 90;
  }

  /// Follow new messages only while the member is already at the bottom.
  /// Preserve their reading position and show a quiet catch-up count.
  void _toBottom({bool force = false}) {
    if (!force && !_atFoot) {
      if (mounted) setState(() => _behind += 1);
      return;
    }
    if (_behind != 0 && mounted) setState(() => _behind = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  /// Shows a quiet count for new messages while the reader is scrolled up.
  Widget _catchUp() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 14, 6),
        child: GestureDetector(
          onTap: () => _toBottom(force: true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: IvoryColors.gold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _behind == 1 ? '1 new word below' : '$_behind new below',
              style: const TextStyle(
                fontSize: 11.6,
                fontWeight: FontWeight.w800,
                color: IvoryColors.burgundy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await LiveService.instance.sendMessage(widget.sessionId, text);
      _input.clear();
      // Their OWN words always bring them back down. Reading
      // further up is a choice; speaking is a reason to return.
      _toBottom(force: true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    final RealtimeChannel? c = _channel;
    if (c != null) LiveService.instance.stopWatching(c);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Say something dear.! I am waiting! I can see everything '
                      'you want to say here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: IvoryColors.cream.withValues(alpha: 0.86),
                        shadows: <Shadow>[
                          Shadow(
                            color: IvoryColors.burgundy.withValues(alpha: 0.9),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : NotificationListener<ScrollEndNotification>(
                  onNotification: (ScrollEndNotification n) {
                    if (_behind > 0 && _atFoot) {
                      setState(() => _behind = 0);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext c, int i) =>
                        _bubble(_messages[i]),
                  ),
                ),
        ),
        if (_behind > 0) _catchUp(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: IvoryColors.gold),
            ),
          ),
        _composer(),
      ],
    );
  }

  Widget _bubble(LiveMessage m) {
    final List<Shadow> readableShadow = <Shadow>[
      Shadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.88),
        blurRadius: 5,
        offset: const Offset(0, 1),
      ),
      Shadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.42),
        blurRadius: 11,
      ),
    ];
    if (m.isHost) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onLongPress: () => showReportSheet(context, preset: 'content'),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.94,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: IvoryColors.gold.withValues(alpha: 0.16),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.burgundy.withValues(alpha: 0.34),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: IvoryColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: 'IVORY  ',
                              style: TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 1,
                                color: IvoryColors.gold,
                                shadows: readableShadow,
                              ),
                            ),
                            TextSpan(
                              text: m.body,
                              style: TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.32,
                                color: IvoryColors.cream,
                                shadows: readableShadow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final String message = _said(m.body).$1;
    final String? note = _said(m.body).$2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GestureDetector(
        onLongPress: () => showReportSheet(context, preset: 'content'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MemberAvatar(
              displayName: m.senderName ?? 'A member',
              imageUrl: m.senderAvatarUrl,
              size: 28,
              premiumFrame: m.senderHasActivePaidTier &&
                  (m.senderAvatarUrl?.isNotEmpty ?? false),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: IvoryColors.cream.withValues(alpha: 0.10),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: IvoryColors.burgundy.withValues(alpha: 0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.35,
                      color: IvoryColors.cream,
                      shadows: readableShadow,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: "${m.senderName ?? 'A member'}  ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: IvoryColors.peach,
                          shadows: readableShadow,
                        ),
                      ),
                      TextSpan(text: message),
                      if (note != null)
                        TextSpan(
                          text: '\n\u201C$note\u201D',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                            color: IvoryColors.gold,
                            shadows: readableShadow,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Splits a gift line into the gift and the words, if any.
  ///
  /// The database sends them as one message with a line break
  /// between, so the room shows the gift plainly and the
  /// member's words in gold italics underneath - the same
  /// treatment their words get on a post, so a member learns
  /// one visual language and not two. The quotation marks are
  /// added here rather than stored, so the stored text stays
  /// clean.
  static (String, String?) _said(String body) {
    final int cut = body.indexOf('\n');
    if (cut < 0) return (body, null);
    final String note = body.substring(cut + 1).trim();
    final String quoted = note.startsWith('"') && note.endsWith('"')
        ? note.substring(1, note.length - 1)
        : note;
    return (
      body.substring(0, cut),
      quoted.isEmpty ? null : quoted,
    );
  }

  Widget _composer() {
    final List<Shadow> legibility = <Shadow>[
      Shadow(
        color: IvoryColors.burgundy.withValues(alpha: 0.96),
        blurRadius: 5,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              cursorColor: IvoryColors.gold,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: TextStyle(
                color: IvoryColors.cream,
                fontSize: 15,
                shadows: legibility,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: 'Write to me...',
                filled: false,
                hintStyle: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.82),
                  fontSize: 14.5,
                  shadows: legibility,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: IvoryColors.cream.withValues(alpha: 0.82),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: IvoryColors.cream.withValues(alpha: 0.78),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: IvoryColors.gold,
                    width: 1.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: IvoryColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: IvoryColors.burgundy,
                      ),
                    )
                  : const Icon(Icons.send_rounded,
                      color: IvoryColors.burgundy, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/live_chat.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';
import 'report_sheet.dart';

/// ============================================================
/// IVORY - THE LIVE RAIL
///
/// During a broadcast only one voice is heard: yours. Members take
/// part by writing, and this is where that happens. Your own lines
/// come back in gold so they are never lost in the stream.
///
/// Everything arrives over the realtime subscription, so a message
/// appears on every device at once without anyone refreshing.
/// ============================================================
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
      (LiveMessage m) {
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
      },
    );
  }

  Future<void> _load() async {
    try {
      final List<LiveMessage> rows =
          await LiveService.instance.fetchMessages(widget.sessionId);
      if (!mounted) return;
      setState(() => _messages = rows);
      _toBottom();
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

  /// THE RULE THAT WAS MISSING: **never drag a member away from
  /// what they are reading.**
  ///
  /// This used to jump to the newest line every single time a
  /// message arrived. During a busy broadcast that makes
  /// scrolling back completely impossible - you reach up to
  /// read something, a stranger types, and you are thrown to
  /// the bottom again. It felt broken because it was.
  ///
  /// Now: if they are already at the foot, follow along as
  /// before. If they have scrolled up, LEAVE THEM WHERE THEY
  /// ARE and just mark that something new has landed.
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

  /// The quiet way back down. It states a plain number and
  /// nothing else - no "everyone is talking!", no urgency. A
  /// count of what is actually there is a fact; anything
  /// livelier would be manufactured excitement.
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
                        fontSize: 13,
                        height: 1.5,
                        color: IvoryColors.cream.withValues(alpha: 0.6),
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
    if (m.isHost) {
      // Ivory's words remain unmistakable, but no longer form a
      // full-width panel over the broadcast picture.
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: GestureDetector(
            onLongPress: () => showReportSheet(context, preset: 'content'),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.86,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(11, 7, 12, 8),
                decoration: BoxDecoration(
                  color: IvoryColors.burgundy.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: IvoryColors.gold.withValues(alpha: 0.78),
                    width: 1,
                  ),
                  boxShadow: IvoryTheme.softShadow(blur: 9, y: 3),
                ),
                child: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'IVORY  ',
                        style: TextStyle(
                          fontFamily: IvoryTheme.displayFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                          letterSpacing: 0.9,
                          color: IvoryColors.gold,
                        ),
                      ),
                      TextSpan(
                        text: m.body,
                        style: TextStyle(
                          fontFamily: IvoryTheme.displayFont,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          height: 1.3,
                          color: IvoryColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        // Long-press anything a member wrote to report it. The IT
        // Rules require this route to exist for member content.
        onLongPress: () => showReportSheet(context, preset: 'content'),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: IvoryColors.peach,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: IvoryColors.cream.withValues(alpha: 0.92),
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: "${m.senderName ?? 'A member'}  ",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: IvoryColors.peach,
                    ),
                  ),
                  // A gift sent with a few words arrives as two
                  // lines in one message: the gift, then what
                  // they wrote. They are deliberately ONE
                  // message - the words belong to the gift and
                  // must never drift off as a loose comment.
                  TextSpan(text: _said(m.body).$1),
                  if (_said(m.body).$2 != null)
                    TextSpan(
                      text: '\n\u201C${_said(m.body).$2}\u201D',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13.2,
                        color: IvoryColors.gold.withValues(alpha: 0.95),
                      ),
                    ),
                ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: IvoryColors.cream.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _input,
              maxLength: 500,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(
                color: IvoryColors.cream,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: 'Write to me...',
                hintStyle: TextStyle(
                  color: IvoryColors.cream.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: IvoryColors.plum,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
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

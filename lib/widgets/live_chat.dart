import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../theme/ivory_theme.dart';

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
  const LiveChat({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

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

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
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
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext c, int i) =>
                      _bubble(_messages[i]),
                ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: m.isHost ? IvoryColors.gold : IvoryColors.peach,
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
                    text: m.isHost ? 'Ivory  ' : 'A member  ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: m.isHost
                          ? IvoryColors.gold
                          : IvoryColors.peach,
                    ),
                  ),
                  TextSpan(text: m.body),
                ],
              ),
            ),
          ),
        ],
      ),
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// ============================================================
/// IVORY - IVORY'S WORDS WITH TAPPABLE LINKS
///
/// Shows text exactly as written, except that a web address (http or
/// https only) becomes underlined and opens in the phone's browser
/// when tapped. Used only for Ivory's own replies, never for a
/// member's letter. Nothing else in the text is touched.
/// ============================================================
class LineLinkedText extends StatefulWidget {
  const LineLinkedText(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<LineLinkedText> createState() => _LineLinkedTextState();
}

class _LineLinkedTextState extends State<LineLinkedText> {
  final List<TapGestureRecognizer> _taps = <TapGestureRecognizer>[];

  static final RegExp _url = RegExp(r'https?://[^\s]+', caseSensitive: false);

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  void _clear() {
    for (final TapGestureRecognizer t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That link could not be opened.')),
      );
    }
  }

  List<InlineSpan> _spans() {
    _clear();
    final String t = widget.text;
    final List<InlineSpan> out = <InlineSpan>[];
    int at = 0;
    for (final RegExpMatch m in _url.allMatches(t)) {
      String link = m.group(0)!;
      // Sentence punctuation after a link is not part of the link.
      String tail = '';
      while (link.isNotEmpty && '.,;:!?)]}\'"'.contains(link[link.length - 1])) {
        tail = link[link.length - 1] + tail;
        link = link.substring(0, link.length - 1);
      }
      if (m.start > at) out.add(TextSpan(text: t.substring(at, m.start)));
      final TapGestureRecognizer tap = TapGestureRecognizer()
        ..onTap = () => _open(link);
      _taps.add(tap);
      out.add(
        TextSpan(
          text: link,
          recognizer: tap,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      if (tail.isNotEmpty) out.add(TextSpan(text: tail));
      at = m.end;
    }
    if (at < t.length) out.add(TextSpan(text: t.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(style: widget.style, children: _spans()),
    );
  }
}

// END OF FILE - lib/widgets/line_linked_text.dart

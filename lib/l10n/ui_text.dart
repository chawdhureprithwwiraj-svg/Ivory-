import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as m show Text;

import 'l10n.dart';

/// ============================================================
/// THE APP'S OWN WORDS, ON EVERY SCREEN
///
/// A drop-in twin of Flutter's `Text`. It shows the same words, except that
/// when the member has chosen another language and a translation exists for
/// that exact English text, the translation is shown instead. No translation
/// means the English stays, so nothing can go blank or break.
///
/// The build robot (tools/ci_l10n.py) points the member screens at this class
/// while it builds the app, so the screen files themselves stay untouched.
/// It also removes wide letter-spacing in Indian scripts, where it looks wrong.
/// ============================================================
class Text extends StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final InlineSpan? textSpan;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  TextStyle? _calm(TextStyle? s) {
    final double? v = s?.letterSpacing;
    if (s == null || v == null) return s;
    final double nv = L10n.instance.ls(v);
    return nv == v ? s : s.copyWith(letterSpacing: nv);
  }

  @override
  Widget build(BuildContext context) {
    final InlineSpan? span = textSpan;
    if (span != null) {
      return m.Text.rich(
        span,
        style: _calm(style),
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return m.Text(
      L10n.instance.t(data ?? ''),
      style: _calm(style),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

// END OF FILE - lib/l10n/ui_text.dart

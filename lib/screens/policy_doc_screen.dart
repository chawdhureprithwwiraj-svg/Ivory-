import 'package:flutter/material.dart';

import '../content/policy_content.dart';
import '../content/policy_privacy.dart';
import '../content/policy_refunds.dart';
import '../content/policy_terms.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// ONE READER FOR ALL FOUR DOCUMENTS.
///
/// Four screens would have been four chances for them to drift
/// apart in look and behaviour. The text lives in lib/content,
/// this file only knows how to put it on cream and make it
/// readable.
///
/// A numbered heading is picked out in burgundy serif; every
/// other line is body text. That is the whole of the
/// formatting, and it is enough.
///
/// THE DOCUMENTS ARE IN THE APP, NOT ON A WEBSITE. A sideloaded
/// build with no site behind it must still be able to show its
/// own terms, on a train, with no signal.
/// ============================================================

enum PolicyDoc { terms, privacy, refunds, content }

class PolicyDocScreen extends StatelessWidget {
  const PolicyDocScreen({super.key, required this.doc});

  final PolicyDoc doc;

  static Future<void> open(BuildContext context, PolicyDoc doc) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PolicyDocScreen(doc: doc),
      ),
    );
  }

  String get _title {
    switch (doc) {
      case PolicyDoc.terms:
        return kTermsTitle;
      case PolicyDoc.privacy:
        return kPrivacyTitle;
      case PolicyDoc.refunds:
        return kRefundsTitle;
      case PolicyDoc.content:
        return kContentTitle;
    }
  }

  String get _updated {
    switch (doc) {
      case PolicyDoc.terms:
        return kTermsUpdated;
      case PolicyDoc.privacy:
        return kPrivacyUpdated;
      case PolicyDoc.refunds:
        return kRefundsUpdated;
      case PolicyDoc.content:
        return kContentUpdated;
    }
  }

  String get _body {
    switch (doc) {
      case PolicyDoc.terms:
        return kTermsBody;
      case PolicyDoc.privacy:
        return kPrivacyBody;
      case PolicyDoc.refunds:
        return kRefundsBody;
      case PolicyDoc.content:
        return kContentBody;
    }
  }

  /// A heading is a line that starts with a number and a full
  /// stop, which is how all four documents are written.
  bool _isHeading(String line) {
    final String t = line.trimLeft();
    if (t.length < 3) return false;
    final int dot = t.indexOf('. ');
    if (dot < 1 || dot > 2) return false;
    return int.tryParse(t.substring(0, dot)) != null;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> paragraphs = _body.trim().split('\n\n');

    return Scaffold(
      backgroundColor: IvoryColors.ivory,
      appBar: AppBar(
        backgroundColor: IvoryColors.ivory,
        elevation: 0,
        title: Text(
          _title.toLowerCase(),
          style: TextStyle(
            fontFamily: IvoryTheme.displayFont,
            fontStyle: FontStyle.italic,
            fontSize: 16,
            color: IvoryColors.burgundy,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        itemCount: paragraphs.length + 1,
        itemBuilder: (BuildContext context, int i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                _updated,
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: IvoryColors.textFaint,
                ),
              ),
            );
          }

          final String para = paragraphs[i - 1].replaceAll('\n', ' ').trim();
          if (para.isEmpty) return const SizedBox.shrink();

          if (_isHeading(para)) {
            return Padding(
              padding: const EdgeInsets.only(top: 22, bottom: 8),
              child: Text(
                para,
                style: TextStyle(
                  fontFamily: IvoryTheme.displayFont,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  height: 1.35,
                  color: IvoryColors.burgundy,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text(
              para,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.6,
                color: IvoryColors.textSoft,
              ),
            ),
          );
        },
      ),
    );
  }
}

// END OF FILE - lib/screens/policy_doc_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ivory_theme.dart';

/// THE HOUSE SEAL (CC.209): one scan carries Ivory to another phone.
///
/// Every app prints a QR code; almost none dares to print its own
/// fingerprint beside it. The seal below encodes the official download
/// page and shows the first eight hex digits of the APK's SHA-256, so a
/// receiver can compare numbers before installing - the same number the
/// download page publishes in full. One payload everywhere: app, website,
/// printed house card. The "?from=seal" tail lets the house tell seal
/// scans from other traffic the day analytics arrive.
class HouseSeal {
  const HouseSeal._();

  static const String url =
      'https://ivory-stories.pages.dev/download.html?from=seal';

  /// Build 1692, first eight hex of its SHA-256, as printed on the seal.
  static const String build = '1692';
  static const String fingerprint = '45CC 8AB8';

  /// The seal itself, embedded so no asset and no pubspec line is needed.
  static const String _png = 'iVBORw0KGgoAAAANSUhEUgAAAN4AAADeCAIAAADdBSngAAAEVklEQVR42u3dwY3bMBQE0CRIBekh1aTeVJMectjzAkkBeyGImU+u/N7ZlmVpQOKLIvn13/vbF7jPN5cA0QTRRDRBNBFNEE0QTUQTRBPRhGnfVz7068fPg6f4+++f0pE//q+931o5zso1TP36ypHvv6daTXToIJqIJogmKvTbqubet3r1+N5vTf6L+++pVhMdOogmogmiiQp9sgqbHLNOfSZVs6fOMHU+tz0x0GqiQwfRRDRBNFGhf0a9ce1e7X925F2rCaKJaIJoIpqgQm9IVbKpMfRUHT05n12rCaKJaIJoIprwjAr9/qpwcr526u30s/X42Xuq1USHDqKJaIJookJfcf+b1b1Z3pO/dXZevFYTRBPRBNFENOG2Cv0Zb00/4xlC6n7df0+1mogmiCaiCaLJi/n67/3tYC2ZqjdTb4P3jtNb3b33T3v3S6uJDh1EE9EE0YQPPuU89Nuq1Ge8Vb5yDVO71a9cH60mOnQQTUQTRBMVeqpGnqwBzz4fmBwf37uGe3u97Z1zana/VhMdOogmogmiyYtZesu9V7P3Vma7rfruXcM9vVF+b7mjQwfRBNFENGFLbAx9skbujf+m1mBPXZ/UOfeeD/RWyNdqokMH0UQ0QTR5MZsrxfVMjj5PjuBPzgt4xlp2Wk106CCaiCaIJi9mcwy9N+97r76b3Dc8dZyze6an7kUvLVpNdOggmogmiCYq9FRNOllv9sa1UyPCvRo59byilwStJjp0EE1EE0QTUhV6b4753q/3KuvUW9yTM9z3TK6ib7c1dOggmogmiCYs2JyH3lsfbFJvfPzsXuepSj81x1yFjg4dRBPRBNGEVIW+V5M+o7a9bQ2621Z46z3l0GqiQwfRRDRBNFGhT9aSk296nx3Tn6ysn7Ebu1YTHTqIJqIJosmL+Z460OT64WfnxafOpzdmPal3hlpNdOggmogmiCYq9JVasrfG2tm9w87u2nb/Guwfv5W671pNdOggmogmiCYq9NSBUnVZr+JLnXNqBL835733Rn3v17Wa6NBBNBFNEE1U6KkD9dZyP1uzp86wV9f37k5qVztruaNDB9FENEE0YUFst7Wztfb9O4nfth967/mAMXR06CCaIJqIJvQq9NtMzme/rWqerJHPrtiv1USHDqKJaIJo8mI2V4qbtPLG+P2j2L293nrz/SefKmg10aGDaCKaIJqo0CdrrlS9mapJe9/aO05v1bXUHZx8GqDVRIcOoologmiiQu9VoL1KP/X2dW/PuNv+V4q13NGhg2iCaCKacFuFfr/eGPrku/GTO6D13h8who4OHUQT0QTRhKdW6JOzqvdGqCd3N9v7F3vnnPqWVhMdOogmogmiiQo9daBeRdyrdleO3KtkU/V46mpMrn6v1USHDqKJaIJoQqpCP7u6++Sqa3t1a2pMPzXHPDUHf+/umIeODh1EE9EE0YQFn3I/dLSaIJogmogmiCaiCaKJaIJogmgimlDwH9gE4k29RN05AAAAAElFTkSuQmCC';

  static Uint8List get bytes => base64Decode(_png);

  static String shareText(String? penName) {
    final who = (penName == null || penName.isEmpty)
        ? 'A member of the house'
        : penName;
    return '$who sends you Ivory - where every story leaves a mark. '
        'True stories, confessions and real crime from India, told aloud. '
        'Free Android app, official page only: $url '
        '(build $build, seal $fingerprint)';
  }

  /// Native share sheet when the platform side listens; until then the
  /// link is copied and the member is told so, gently.
  static Future<bool> share(BuildContext context, String? penName) async {
    const channel = MethodChannel('ivory_house/seal');
    try {
      await channel.invokeMethod<void>('share', <String, String>{
        'text': shareText(penName),
      });
      return true;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText(penName)));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('The seal\'s words are copied - paste them in any app.'),
        ));
      }
      return false;
    }
  }

  static Future<void> copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seal link copied.'),
      ));
    }
  }
}

/// The card on the home shelf: seal, fingerprint, three quiet actions.
class HouseSealCard extends StatelessWidget {
  const HouseSealCard({super.key, this.penName});

  final String? penName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFDF7), Color(0xFFFDF1DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: IvoryColors.gold.withOpacity(0.55)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF2),
              border: Border.all(color: IvoryColors.gold),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.memory(HouseSeal.bytes,
                width: 96, height: 96, filterQuality: FilterQuality.none),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('THE HOUSE SEAL',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: IvoryColors.burgundy)),
                const SizedBox(height: 4),
                Text('One scan carries Ivory to another phone.',
                    style: TextStyle(
                        fontSize: 12,
                        color: IvoryColors.burgundy.withOpacity(0.75))),
                const SizedBox(height: 4),
                Text('BUILD ${HouseSeal.build} · SEAL ${HouseSeal.fingerprint}',
                    style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        color: IvoryColors.burgundy.withOpacity(0.6))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _sealButton(context, 'SHOW LARGE', () => _large(context)),
                    _sealButton(context, 'SHARE', () => HouseSeal.share(context, penName)),
                    _sealButton(context, 'COPY', () => HouseSeal.copy(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sealButton(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: IvoryColors.goldGradient,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: IvoryColors.gold.withOpacity(0.85)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: IvoryColors.burgundy)),
      ),
    );
  }

  Future<void> _large(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: const Color(0xFFFFFCF2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: IvoryColors.gold.withOpacity(0.8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('THE HOUSE SEAL',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                        color: IvoryColors.burgundy)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF2),
                    border: Border.all(color: IvoryColors.gold),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.memory(HouseSeal.bytes,
                      width: 240, height: 240, filterQuality: FilterQuality.none),
                ),
                const SizedBox(height: 10),
                const Text('Where every story leaves a mark',
                    style: TextStyle(fontSize: 12, color: IvoryColors.burgundy)),
                const SizedBox(height: 4),
                Text('BUILD ${HouseSeal.build} · SEAL ${HouseSeal.fingerprint}',
                    style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.6,
                        color: IvoryColors.burgundy.withOpacity(0.6))),
                const SizedBox(height: 6),
                Text('Any camera reads this seal. The page it opens prints the '
                    'full fingerprint of the build, so a receiver can verify '
                    'before installing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10.5,
                        color: IvoryColors.burgundy.withOpacity(0.7))),
              ],
            ),
          ),
        );
      },
    );
  }
}

// END OF FILE - lib/widgets/house_seal.dart

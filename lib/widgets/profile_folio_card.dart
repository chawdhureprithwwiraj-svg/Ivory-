import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';

/// A personal writing shelf, deliberately not styled as another inbox.
class ProfileFolioCard extends StatelessWidget {
  const ProfileFolioCard({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.fromLTRB(17, 16, 15, 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[IvoryColors.surfaceWarm, IvoryColors.cream],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: IvoryColors.gold, width: 1.25),
              boxShadow: IvoryTheme.softShadow(blur: 12, y: 4),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 54,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.deepGradient,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: IvoryColors.gold, width: 1.1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.menu_book_rounded,
                        color: IvoryColors.cream,
                        size: 28,
                      ),
                      Positioned(
                        right: 8,
                        top: 7,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: IvoryColors.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'THE QUIET FOLIO',
                        style: TextStyle(
                          color: IvoryColors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.45,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Unsent words. Good links. Things worth keeping.',
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PRIVATE TO YOUR ACCOUNT  ·  OPEN FOLIO  ›',
                        style: TextStyle(
                          color: IvoryColors.plum,
                          fontSize: 9.3,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/profile_folio_card.dart

import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - THE LOOKS OF THE BELL SETS
///
/// Every bell set is four jewel colours (Dawn, Noon, Dusk, Night)
/// and a name. The database decides which sets exist, what they are
/// called and how many Full Days earn them; this file only knows how
/// each set looks, by its key. A key it does not know wears the
/// Jewel colours, so a set the house adds later still works.
/// No black anywhere.
/// ============================================================
class BellLook {
  const BellLook(this.key, this.colors);

  final String key;
  final List<Color> colors;

  static const BellLook jewel = BellLook('jewel', <Color>[
    Color(0xFFFF6B8B),
    Color(0xFF4DF0A8),
    Color(0xFFFFA42B),
    Color(0xFF52C7FF),
  ]);

  static const List<BellLook> all = <BellLook>[
    jewel,
    BellLook('opal', <Color>[
      Color(0xFFFFB3D9),
      Color(0xFFB5F5EC),
      Color(0xFFC8B6FF),
      Color(0xFFFFE9A8),
    ]),
    BellLook('sunset', <Color>[
      Color(0xFFFF5E62),
      Color(0xFFFF8A47),
      Color(0xFFFFC145),
      Color(0xFFFF7BAC),
    ]),
    BellLook('ocean', <Color>[
      Color(0xFF2EC4FF),
      Color(0xFF3DDAD7),
      Color(0xFF5B8DEF),
      Color(0xFF8EE3EF),
    ]),
    BellLook('aurora', <Color>[
      Color(0xFF5CFFB1),
      Color(0xFF4DD2FF),
      Color(0xFFA06CFF),
      Color(0xFFFF6BD6),
    ]),
    BellLook('orchid', <Color>[
      Color(0xFFE56BFF),
      Color(0xFFFF7EC9),
      Color(0xFFB66CFF),
      Color(0xFF8F9BFF),
    ]),
    BellLook('citrus', <Color>[
      Color(0xFFFFE14D),
      Color(0xFFB6F23A),
      Color(0xFFFF9F1C),
      Color(0xFF7DF0A0),
    ]),
    BellLook('lagoon', <Color>[
      Color(0xFF22E4C4),
      Color(0xFF3AA8FF),
      Color(0xFF1ECFA0),
      Color(0xFF7B9BFF),
    ]),
    BellLook('ember', <Color>[
      Color(0xFFFF4D4D),
      Color(0xFFFF7A29),
      Color(0xFFFFB020),
      Color(0xFFFF5C8A),
    ]),
    BellLook('twilight', <Color>[
      Color(0xFF8E7DFF),
      Color(0xFFC86BFF),
      Color(0xFF5C9DFF),
      Color(0xFFFF7AB6),
    ]),
    BellLook('meadow', <Color>[
      Color(0xFF7BE05A),
      Color(0xFF3DDC97),
      Color(0xFFC6F25C),
      Color(0xFF5AD1E0),
    ]),
    BellLook('lotus', <Color>[
      Color(0xFFFF9ECF),
      Color(0xFFFFC2E2),
      Color(0xFFFFD6A5),
      Color(0xFFC9B6FF),
    ]),
    BellLook('crystal', <Color>[
      Color(0xFFBFF0FF),
      Color(0xFFD8E6FF),
      Color(0xFFF4FAFF),
      Color(0xFFE3D4FF),
    ]),
    BellLook('celestial', <Color>[
      Color(0xFFFFD84D),
      Color(0xFFFF8AE2),
      Color(0xFF7DF0FF),
      Color(0xFFB6A0FF),
    ]),
  ];

  /// The look for a set key (Jewel for any key not known here).
  static BellLook of(String? key) {
    for (final BellLook l in all) {
      if (l.key == key) return l;
    }
    return jewel;
  }

  /// The look the bells are wearing right now, on every screen.
  static final ValueNotifier<BellLook> current = ValueNotifier<BellLook>(jewel);

  static void apply(String? key) {
    final BellLook l = of(key);
    if (current.value.key != l.key) current.value = l;
  }
}

// END OF FILE - lib/widgets/bell_looks.dart

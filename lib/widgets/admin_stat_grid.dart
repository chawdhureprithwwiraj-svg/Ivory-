import 'package:flutter/material.dart';

/// ============================================================
/// IVORY - ADMIN NUMBER TILES, TWO ACROSS
///
/// Lays the little number cards of the Gold, Heart, Rewards and
/// Codes tabs in rows of two that fill the width, with the two cards
/// of a row always the same height.
/// ============================================================
class AdminStatGrid extends StatelessWidget {
  const AdminStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: children[i]),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

// END OF FILE - lib/widgets/admin_stat_grid.dart

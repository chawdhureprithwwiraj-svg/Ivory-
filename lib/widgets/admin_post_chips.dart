import 'package:flutter/material.dart';

import 'admin_bits.dart';

/// The three rows of chips in the composer, lifted out of
/// admin_create_tab.dart so neither file grows past a comfortable
/// paste. They hold no state of their own: the composer passes in
/// what is selected and gets back what was tapped.

List<Widget> postTypeChips({
  required String selected,
  required ValueChanged<String> onTap,
}) {
  const List<List<Object>> specs = <List<Object>>[
    <Object>['blog', 'Story', Icons.auto_stories_outlined],
    <Object>['audio', 'Audio', Icons.headphones_outlined],
    <Object>['video', 'Video', Icons.play_circle_outline],
    <Object>['image', 'Image', Icons.image_outlined],
    <Object>['poll', 'Poll', Icons.how_to_vote_outlined],
  ];
  return specs.map((List<Object> s) {
    final String value = s[0] as String;
    return AdminSelectChip(
      label: s[1] as String,
      icon: s[2] as IconData,
      selected: selected == value,
      onTap: () => onTap(value),
    );
  }).toList();
}

/// Who the tier rule lets in when the post carries no price.
List<Widget> postTierChips({
  required int selected,
  required List<Map<String, dynamic>> tiers,
  required ValueChanged<int> onTap,
}) {
  final List<Widget> chips = <Widget>[
    AdminSelectChip(
      label: 'Free for everyone',
      icon: Icons.lock_open,
      selected: selected == 0,
      onTap: () => onTap(0),
    ),
  ];
  for (final Map<String, dynamic> t in tiers) {
    final int level = ((t['level'] as num?) ?? 0).toInt();
    final int price = ((t['price_inr'] as num?) ?? 0).toInt();
    chips.add(AdminSelectChip(
      label: '${(t['name'] as String?) ?? 'Tier'} \u00b7 \u20B9$price',
      icon: Icons.lock_outline,
      selected: selected == level,
      onTap: () => onTap(level),
    ));
  }
  return chips;
}

/// Who skips the price. "Nobody" means every member pays, however
/// much they already subscribe for.
List<Widget> postFreeFromChips({
  required int? selected,
  required List<Map<String, dynamic>> tiers,
  required ValueChanged<int?> onTap,
}) {
  final List<Widget> chips = <Widget>[
    AdminSelectChip(
      label: 'Nobody - all pay',
      icon: Icons.payments_outlined,
      selected: selected == null,
      onTap: () => onTap(null),
    ),
  ];
  for (final Map<String, dynamic> t in tiers) {
    final int level = ((t['level'] as num?) ?? 0).toInt();
    chips.add(AdminSelectChip(
      label: '${(t['name'] as String?) ?? 'Tier'} and above',
      icon: Icons.workspace_premium_outlined,
      selected: selected == level,
      onTap: () => onTap(level),
    ));
  }
  return chips;
}


/// The exact-audience mix: nobody-all-pay, Forever Members, any tiers.
/// Used by CREATE, LIVE and anywhere the house picks who gets in.
List<Widget> audienceMixChips({
  required Set<int> who,
  required List<Map<String, dynamic>> tiers,
  required void Function(Set<int>) onChange,
}) {
  Set<int> toggle(Set<int> src, int v) {
    final Set<int> next = Set<int>.from(src);
    if (next.contains(v)) {
      next.remove(v);
    } else {
      next.add(v);
    }
    return next;
  }

  return <Widget>[
    AdminSelectChip(
      label: 'Nobody - all pay',
      icon: Icons.currency_rupee_rounded,
      selected: who.isEmpty,
      onTap: () => onChange(<int>{}),
    ),
    AdminSelectChip(
      label: 'Forever Members',
      icon: Icons.public_rounded,
      selected: who.contains(0),
      onTap: () => onChange(toggle(who, 0)),
    ),
    for (final Map<String, dynamic> t in tiers)
      if ((t['level'] as num?)?.toInt() != null &&
          (t['level'] as num).toInt() > 0)
        AdminSelectChip(
          label: (t['name'] as String?) ?? 'Tier',
          icon: Icons.workspace_premium_rounded,
          selected: who.contains((t['level'] as num).toInt()),
          onTap: () => onChange(toggle(who, (t['level'] as num).toInt())),
        ),
  ];
}

// END OF FILE - lib/widgets/admin_post_chips.dart

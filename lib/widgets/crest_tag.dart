import 'package:flutter/material.dart';

import '../services/crest_service.dart';
import 'bell_looks.dart';

/// ============================================================
/// IVORY - THE SMALL SHOWCASE TAG BESIDE A NAME
///
/// Four tiny dots in the colours of the bell set the member wears and
/// the name of their rung on the Ivory Ladder. It appears only when the
/// member has left their Showcase on; otherwise, or while the answer is
/// on its way, or if anything fails, there is simply nothing here.
/// ============================================================
class CrestTag extends StatefulWidget {
  const CrestTag({super.key, required this.memberId});

  final String memberId;

  @override
  State<CrestTag> createState() => _CrestTagState();
}

class _CrestTagState extends State<CrestTag> {
  CrestPublic? _c;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(CrestTag old) {
    super.didUpdateWidget(old);
    if (old.memberId != widget.memberId) {
      _c = null;
      _ask();
    }
  }

  Future<void> _ask() async {
    final String id = widget.memberId;
    if (id.isEmpty) return;
    final CrestPublic? c = await CrestService.instance.of(id);
    if (!mounted || id != widget.memberId) return;
    setState(() => _c = c);
  }

  @override
  Widget build(BuildContext context) {
    final CrestPublic? c = _c;
    if (c == null || c.rungName.isEmpty) return const SizedBox.shrink();
    final List<Color> cols = BellLook.of(c.wear).colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 7, 2),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Color col in cols)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(color: col, shape: BoxShape.circle),
            ),
          const SizedBox(width: 2),
          Text(
            c.rungName.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFF3ECFF),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/crest_tag.dart

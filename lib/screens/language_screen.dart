import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/l10n.dart';
import '../l10n/l10n_langs.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ivory_logo.dart';

/// Shows the language screen the first time the app is opened, and the
/// real screen (`child`) from then on. If the member skips nothing and
/// simply taps Continue, the app stays in the preselected language
/// (the phone's own language if Ivory speaks it, otherwise English).
class LanguageGate extends StatelessWidget {
  const LanguageGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return L10n.instance.chosen ? child : const LanguageScreen();
  }
}

/// ============================================================
/// CHOOSE YOUR LANGUAGE
///
/// Two columns of plain tiles, each language in its own script. English
/// is one tile among the others. The heading and the Continue button are
/// shown in the language that is selected, so a member who cannot read
/// English still sees a button they understand.
/// ============================================================
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.change = false});

  /// True when opened later from Profile or the sign-in screen.
  final bool change;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _sel;
  late List<LangInfo> _shown;
  bool _busy = false;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _shown = kLangs.where((LangInfo l) => l.defaultOn).toList();
    _sel = widget.change ? L10n.instance.code : _guess(_shown);
    _loadOn();
  }

  /// The phone's own language, if Ivory speaks it. Otherwise English.
  String _guess(List<LangInfo> from) {
    final List<Locale> locales =
        WidgetsBinding.instance.platformDispatcher.locales;
    for (final Locale loc in locales) {
      for (final LangInfo l in from) {
        if (l.code == loc.languageCode) return l.code;
      }
    }
    return 'en';
  }

  /// Asks the database which languages the house has switched on.
  Future<void> _loadOn() async {
    try {
      final dynamic r =
          await Supabase.instance.client.rpc<dynamic>('i18n_languages_list');
      if (r is! List) return;
      final Set<String> on = <String>{'en'};
      for (final dynamic e in r) {
        if (e is Map) on.add('${e['code']}');
      }
      final List<LangInfo> list =
          kLangs.where((LangInfo l) => on.contains(l.code)).toList();
      if (!mounted || list.isEmpty) return;
      setState(() {
        _shown = list;
        if (!_touched && !widget.change) _sel = _guess(list);
      });
    } catch (_) {
      // Offline or not set up yet: the built-in list is shown.
    }
  }

  Future<void> _go() async {
    if (_busy) return;
    setState(() => _busy = true);
    await L10n.instance.choose(_sel);
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.change && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LangInfo cur = langByCode(_sel);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              if (widget.change)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: IvoryColors.plum),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                )
              else
                const SizedBox(height: 14),
              const IvoryLogo(size: 64),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    cur.heading,
                    key: ValueKey<String>(cur.code),
                    textAlign: TextAlign.center,
                    textDirection:
                        cur.rtl ? TextDirection.rtl : TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: IvoryColors.plum,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 80,
                  ),
                  itemCount: _shown.length,
                  itemBuilder: (BuildContext c, int i) => _tile(_shown[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                child: IvoryGradientButton(
                  label: cur.go,
                  icon: Icons.arrow_forward,
                  busy: _busy,
                  onPressed: _busy ? null : _go,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(LangInfo l) {
    final bool on = l.code == _sel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() {
          _sel = l.code;
          _touched = true;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? IvoryColors.surfaceWarm : IvoryColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? IvoryColors.gold : IvoryColors.hairline,
              width: on ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.native,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection:
                          l.rtl ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: IvoryColors.plum,
                      ),
                    ),
                    if (l.native != l.english)
                      Text(
                        l.english,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: IvoryColors.textSoft,
                        ),
                      ),
                  ],
                ),
              ),
              if (on)
                const Icon(Icons.check_circle,
                    size: 22, color: IvoryColors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/language_screen.dart

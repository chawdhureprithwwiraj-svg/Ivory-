import 'package:flutter/material.dart';
import 'theme/ivory_theme.dart';

void main() {
  runApp(const IvoryApp());
}

class IvoryApp extends StatelessWidget {
  const IvoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ivory',
      debugShowCheckedModeBanner: false,
      theme: IvoryTheme.light(),
      home: const WelcomeScreen(),
    );
  }
}

/// Sprint 1 screen: proves the build pipeline works and locks in the
/// Ivory visual identity (no black anywhere - burgundy is the darkest tone).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const _IvoryMonogram(),
                  const SizedBox(height: 32),
                  ShaderMask(
                    shaderCallback: (Rect bounds) =>
                        IvoryColors.goldGradient.createShader(bounds),
                    child: const Text(
                      'IVORY',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 10,
                        color: Colors.white, // masked by the gold gradient
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Every story leaves a mark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1.1,
                      color: IvoryColors.burgundy.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const _StatusCard(),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Build pipeline works. Ready for Sprint 2.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('ENTER IVORY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The glowing ivory "I" monogram from the app icon, drawn in pure Flutter
/// so no image asset is needed for the first build.
class _IvoryMonogram extends StatelessWidget {
  const _IvoryMonogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(42),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: IvoryTheme.softShadow(blur: 28, y: 12),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: IvoryColors.cream,
            borderRadius: BorderRadius.circular(10),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: IvoryColors.peach.withValues(alpha: 0.55),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Text(
            'I',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: IvoryColors.burgundy,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Burgundy card with gold border - the reusable look for the whole feed.
class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    const List<_Milestone> milestones = <_Milestone>[
      _Milestone('GitHub repository + auto APK builds', true),
      _Milestone('Ivory design system locked in', true),
      _Milestone('Supabase backend & authentication', false),
      _Milestone('Community storytelling feed', false),
      _Milestone('Premium tiers & UPI payments', false),
      _Milestone('Agora live streaming & 1-on-1 calls', false),
      _Milestone('Mobile admin dashboard', false),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: IvoryTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'BUILD ROADMAP',
            style: TextStyle(
              color: IvoryColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 16),
          ...milestones.map(
            (_Milestone m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    m.done
                        ? Icons.check_circle
                        : Icons.lock_outline,
                    size: 19,
                    color: m.done ? IvoryColors.amber : IvoryColors.peach,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.label,
                      style: TextStyle(
                        color: m.done
                            ? IvoryColors.ivory
                            : IvoryColors.ivory.withValues(alpha: 0.6),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone {
  const _Milestone(this.label, this.done);
  final String label;
  final bool done;
}

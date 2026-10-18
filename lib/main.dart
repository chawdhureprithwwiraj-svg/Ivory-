import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'l10n/l10n.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/push_service.dart';
import 'theme/ivory_theme.dart';
import 'widgets/ivory_footer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The language the member chose last time (English if none yet).
  await L10n.instance.init();

  // If the keys have not been pasted in yet, the app still launches and
  // shows a friendly setup screen instead of crashing on a black screen.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    // Device push. If Firebase was never configured this returns false and
    // Ivory carries on with the in-app inbox alone.
    await PushService.initFirebase();

    // Quietly fetch any words the house has edited since last time.
    L10n.instance.refreshQuietly();
  }

  runApp(const IvoryApp());
}

class IvoryApp extends StatelessWidget {
  const IvoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Choosing a language repaints the whole app from the top.
    return ValueListenableBuilder<int>(
      valueListenable: L10n.instance.epoch,
      builder: (BuildContext context, int epoch, Widget? _) {
        return MaterialApp(
          key: ValueKey<int>(epoch),
          title: 'Ivory',
          debugShowCheckedModeBanner: false,
          theme: IvoryTheme.light(),
          // Right-to-left languages (Urdu) flip the page; then the
          // small-print footer, under every screen of the app.
          builder: (BuildContext c, Widget? child) => Directionality(
            textDirection:
                L10n.instance.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: IvoryFooter.wrap(c, child),
          ),
          home: SupabaseConfig.isConfigured
              ? const AuthGate()
              : const SetupNeededScreen(),
        );
      },
    );
  }
}

/// Listens to the Supabase session and shows either the login screen
/// or the home screen. Sessions persist, so a returning user stays
/// signed in after closing the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (BuildContext context, AsyncSnapshot<AuthState> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final Session? session =
            snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

        if (session != null) {
          return const MainShell();
        }
        // The language screen comes first, before sign-in and sign-up.
        return const LanguageGate(child: LoginScreen());
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ShaderMask(
                shaderCallback: (Rect b) =>
                    IvoryColors.goldGradient.createShader(b),
                child: const Text(
                  'IVORY',
                  style: TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const CircularProgressIndicator(color: IvoryColors.amber),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when lib/core/supabase_config.dart still has placeholder values.
class SetupNeededScreen extends StatelessWidget {
  const SetupNeededScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: IvoryTheme.card(highlighted: true, radius: 22),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SUPABASE KEYS MISSING',
                      style: TextStyle(
                        color: IvoryColors.plum,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Open lib/core/supabase_config.dart on GitHub and replace '
                      'the two placeholder values with your Project URL and '
                      'anon public key, then rebuild the APK.',
                      style: TextStyle(
                        color: IvoryColors.burgundy,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/main.dart

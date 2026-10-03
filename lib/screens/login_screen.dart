import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/ivory_theme.dart';
import '../widgets/ivory_field.dart';
import '../widgets/ivory_logo.dart';
import '../widgets/house_consent.dart';

/// Sign in / create account, in the Ivory Golden Edition style.
///
/// The whole form sits inside an AutofillGroup and the fields carry
/// proper autofill hints, so Android and Google Password Manager offer
/// to save the password and fill it next time.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  bool _remember = true;
  bool _adult = false;
  String? _message;
  bool _messageIsError = true;

  static const String _kRememberKey = 'ivory_remember_me';
  static const String _kEmailKey = 'ivory_saved_email';

  @override
  void initState() {
    super.initState();
    _restoreEmail();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Brings back the email from last time, so the only thing left to do
  /// is let the phone's password manager fill the password.
  Future<void> _restoreEmail() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool remember = prefs.getBool(_kRememberKey) ?? true;
      final String email = prefs.getString(_kEmailKey) ?? '';
      if (!mounted) return;
      setState(() {
        _remember = remember;
        if (remember && email.isNotEmpty && _emailCtrl.text.isEmpty) {
          _emailCtrl.text = email;
        }
      });
    } catch (_) {
      // First run, or storage unavailable - nothing to restore.
    }
  }

  Future<void> _rememberEmail() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberKey, _remember);
      if (_remember) {
        await prefs.setString(_kEmailKey, _emailCtrl.text.trim());
      } else {
        await prefs.remove(_kEmailKey);
      }
    } catch (_) {
      // Saving the email is a convenience, never a hard failure.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && !_adult) {
      setState(() {
        _messageIsError = true;
        _message = 'Tick the house promise first, then create the account.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.instance.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName:
              _nameCtrl.text.isEmpty ? 'Anonymous Reader' : _nameCtrl.text,
        );

        // The tick is recorded even before email confirmation, through
        // the narrow security-definer door in Postgres.
        try {
          await Supabase.instance.client.rpc<dynamic>(
            'record_signup_consent',
            params: <String, dynamic>{'email_in': _emailCtrl.text.trim()},
          );
        } catch (_) {
          // The promise was ticked; a recorder hiccup is not fatal.
        }

        if (!mounted) return;
        if (!AuthService.instance.isSignedIn) {
          setState(() {
            _messageIsError = false;
            _message =
                'Account created. Check your email to confirm, then sign in.';
            _isSignUp = false;
          });
        }
      } else {
        await AuthService.instance.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }

      await _rememberEmail();
      // Tells Android the login flow is finished, which is what makes
      // Google Password Manager offer "Save password?".
      TextInput.finishAutofillContext();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = AuthService.friendlyError(error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final String email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _messageIsError = true;
        _message = 'Enter your email above first, then tap Forgot password.';
      });
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _messageIsError = false;
        _message = 'Password reset link sent to $email.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = AuthService.friendlyError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // ---- the mark ----
                  const IvoryLogo(size: 92),
                  const SizedBox(height: 18),
                  Text('IVORY',
                      style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Every story leaves a mark',
                    style: TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      color: IvoryColors.textSoft,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---- the card ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    decoration:
                        IvoryTheme.card(highlighted: true, radius: 26),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: IvoryEyebrow(
                                _isSignUp ? 'Create account' : 'Sign in',
                                icon: _isSignUp
                                    ? Icons.person_add_alt
                                    : Icons.lock_open,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // The first thing anyone reads. It has to
                            // promise, not greet.
                            Text(
                              // Warm, promising, and clean: it sells
                              // the library and the voice, never a
                              // relationship.
                              _isSignUp
                                  ? 'Behind this door: real stories, a '
                                      'real voice, and a quiet place to '
                                      'keep them.'
                                  : 'Welcome back to your private world.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: IvoryTheme.displayFont,
                                fontSize: _isSignUp ? 15.5 : 14.5,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                color: IvoryColors.plum,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_isSignUp) ...<Widget>[
                              IvoryField(
                                controller: _nameCtrl,
                                label: 'Display name',
                                hint: 'How others will see you',
                                icon: Icons.person_outline,
                                autofillHints: const <String>[
                                  AutofillHints.name,
                                ],
                                validator: (String? v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Please enter at least 2 characters'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            IvoryField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'you@example.com',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const <String>[
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              validator: (String? v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email address'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            IvoryField(
                              controller: _passwordCtrl,
                              label: 'Password',
                              hint: 'At least 6 characters',
                              icon: Icons.lock_outline,
                              obscure: _obscure,
                              autofillHints: <String>[
                                _isSignUp
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              onSubmitted: (_) => _submit(),
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (String? v) =>
                                  (v == null || v.length < 6)
                                      ? 'Password must be at least 6 characters'
                                      : null,
                            ),

                            // ---- the house promise (sign-up only) ----
                            if (_isSignUp) ...<Widget>[
                              const SizedBox(height: 16),
                              AdultPromiseTile(
                                value: _adult,
                                onChanged: (bool v) =>
                                    setState(() => _adult = v),
                              ),
                            ],

                            // ---- remember me ----
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Checkbox(
                                  value: _remember,
                                  onChanged: (bool? v) =>
                                      setState(() => _remember = v ?? false),
                                  side: const BorderSide(
                                      color: IvoryColors.gold, width: 1.4),
                                  checkColor: IvoryColors.burgundy,
                                  fillColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (Set<WidgetState> states) =>
                                        states.contains(WidgetState.selected)
                                            ? IvoryColors.gold
                                            : Colors.transparent,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _remember = !_remember),
                                    child: Text(
                                      'Remember me on this phone',
                                      style: TextStyle(
                                        color: IvoryColors.textSoft,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_message != null) ...<Widget>[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: (_messageIsError
                                          ? IvoryColors.danger
                                          : IvoryColors.success)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _messageIsError
                                        ? IvoryColors.danger
                                            .withValues(alpha: 0.5)
                                        : IvoryColors.success
                                            .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    color: _messageIsError
                                        ? IvoryColors.danger
                                        : IvoryColors.burgundy,
                                    fontSize: 13.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 18),
                            IvoryGradientButton(
                              label: _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                              icon: _isSignUp
                                  ? Icons.auto_awesome
                                  : Icons.arrow_forward,
                              busy: _busy,
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _isSignUp = !_isSignUp;
                                        _message = null;
                                      }),
                              child: Text(
                                _isSignUp
                                    ? 'Already have an account? Sign in'
                                    : 'New to Ivory? Create an account',
                                style: const TextStyle(
                                  color: IvoryColors.plum,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            if (!_isSignUp)
                              TextButton(
                                onPressed: _busy ? null : _forgotPassword,
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: IvoryColors.textFaint,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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

// END OF FILE - lib/screens/login_screen.dart

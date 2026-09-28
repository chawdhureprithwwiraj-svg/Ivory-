import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/ivory_theme.dart';

/// Combined sign-in / sign-up screen in the Ivory palette.
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
  String? _message;
  bool _messageIsError = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
          displayName: _nameCtrl.text.isEmpty
              ? 'Anonymous Reader'
              : _nameCtrl.text,
        );
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: <Widget>[
                  const _Monogram(),
                  const SizedBox(height: 22),
                  ShaderMask(
                    shaderCallback: (Rect b) =>
                        IvoryColors.goldGradient.createShader(b),
                    child: const Text(
                      'IVORY',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Every story leaves a mark',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      color: IvoryColors.burgundy.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    decoration: BoxDecoration(
                      gradient: IvoryColors.cardGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: IvoryColors.gold.withValues(alpha: 0.55),
                        width: 1.2,
                      ),
                      boxShadow: IvoryTheme.softShadow(),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            _isSignUp ? 'CREATE ACCOUNT' : 'WELCOME BACK',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: IvoryColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isSignUp) ...<Widget>[
                            _IvoryField(
                              controller: _nameCtrl,
                              label: 'Display name',
                              hint: 'How others will see you',
                              icon: Icons.person_outline,
                              validator: (String? v) {
                                if (v == null || v.trim().length < 2) {
                                  return 'Please enter at least 2 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          _IvoryField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'you@example.com',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (String? v) {
                              if (v == null || !v.contains('@')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _IvoryField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            hint: 'At least 6 characters',
                            icon: Icons.lock_outline,
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: IvoryColors.burgundy,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                            validator: (String? v) {
                              if (v == null || v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          if (_message != null) ...<Widget>[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_messageIsError
                                        ? IvoryColors.danger
                                        : IvoryColors.success)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _messageIsError
                                      ? IvoryColors.peach
                                      : IvoryColors.amber,
                                ),
                              ),
                              child: Text(
                                _message!,
                                style: const TextStyle(
                                  color: IvoryColors.ivory,
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: IvoryColors.burgundy,
                                    ),
                                  )
                                : Text(
                                    _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                  ),
                          ),
                          const SizedBox(height: 10),
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
                                color: IvoryColors.peach,
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
                                  color: IvoryColors.ivory
                                      .withValues(alpha: 0.65),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: IvoryColors.amber,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'No phone number is ever collected.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: IvoryColors.burgundy.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
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

class _IvoryField extends StatelessWidget {
  const _IvoryField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: IvoryColors.burgundy, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: IvoryColors.burgundy, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: IvoryColors.cardGradient,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: IvoryColors.gold.withValues(alpha: 0.7),
          width: 2,
        ),
        boxShadow: IvoryTheme.softShadow(blur: 22, y: 10),
      ),
      child: Center(
        child: Container(
          width: 50,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: IvoryColors.cream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'I',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: IvoryColors.burgundy,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../services/business_enquiry_service.dart';
import '../theme/ivory_theme.dart';

/// A private, in-app doorway for business and creative enquiries.
/// No recipient email address is included in the client app.
class BusinessEnquiryScreen extends StatefulWidget {
  const BusinessEnquiryScreen({super.key});

  @override
  State<BusinessEnquiryScreen> createState() => _BusinessEnquiryScreenState();
}

class _BusinessEnquiryScreenState extends State<BusinessEnquiryScreen> {
  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _note;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final String text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _note = 'Write a note first, even if it is just a few lines.');
      return;
    }
    setState(() {
      _sending = true;
      _note = null;
    });
    try {
      await BusinessEnquiryService.instance.submit(text);
      if (!mounted) return;
      setState(() => _sent = true);
    } on BusinessEnquiryError catch (error) {
      if (mounted) setState(() => _note = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _note = 'The note could not be sent just now. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IvoryColors.surface,
      appBar: AppBar(
        title: const Text('BUSINESS & PARTNERSHIPS'),
        leading: IconButton(
          tooltip: 'Back to Ivory',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
            children: <Widget>[
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: IvoryColors.surface,
                      width: 4,
                    ),
                    boxShadow: IvoryTheme.softShadow(blur: 18, y: 7),
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: IvoryColors.burgundy,
                    size: 35,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const IvoryEyebrow(
                'A quiet door for thoughtful ideas',
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 10),
              Text(
                _sent ? 'Your note has arrived.' : 'Let’s make something meaningful.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 25,
                      height: 1.25,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _sent
                    ? 'Thank you for thinking of Ivory. Your message is in the private business inbox.'
                    : 'For a partnership, a press conversation, an event, or a creative idea—tell Ivory what you have in mind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: IvoryColors.textSoft,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: IvoryColors.surface,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: IvoryColors.hairline),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: IvoryColors.burgundy,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your note is private to Ivory. Her business email is never shown in the app.',
                        style: TextStyle(
                          color: IvoryColors.textSoft,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_sent) ...<Widget>[
                const SizedBox(height: 22),
                Text(
                  'YOUR NOTE',
                  style: const TextStyle(
                    color: IvoryColors.plum,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _message,
                  enabled: !_sending,
                  minLines: 6,
                  maxLines: 9,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell Ivory about the idea, the people behind it, and what you hope to create together…',
                    filled: true,
                    fillColor: IvoryColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: IvoryColors.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: IvoryColors.hairlineStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: IvoryColors.gold,
                        width: 1.7,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                if (_note != null) ...<Widget>[
                  Text(
                    _note!,
                    style: TextStyle(
                      color: IvoryColors.danger,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                IvoryGradientButton(
                  label: 'SEND A PRIVATE NOTE',
                  icon: Icons.send_rounded,
                  busy: _sending,
                  onPressed: _sending ? null : _send,
                ),
                const SizedBox(height: 10),
                Text(
                  'There is no email link here—just a private message form.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: IvoryColors.textFaint,
                    fontSize: 11.5,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(height: 22),
                IvoryGradientButton(
                  label: 'BACK TO IVORY',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/business_enquiry_screen.dart

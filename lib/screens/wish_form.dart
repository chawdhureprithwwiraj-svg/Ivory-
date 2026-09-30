import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';

/// The form a member fills in to make a wish: what they want, any
/// detail they care to add, and what it will cost. Lifted out of
/// wish_screen.dart so neither file grows past a comfortable paste.

class WishForm extends StatefulWidget {
  const WishForm({required this.category, required this.onDone});

  final WishCategory category;
  final VoidCallback onDone;

  @override
  State<WishForm> createState() => WishFormState();
}

class WishFormState extends State<WishForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _details = TextEditingController();
  late final TextEditingController _budget =
      TextEditingController(text: widget.category.basePriceInr.toString());
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await WishService.instance.makeWish(
        category: widget.category,
        title: _title.text,
        details: _details.text,
        budgetInr: int.parse(_budget.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your wish has been sent. Watch your inbox.'),
        ),
      );
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      decoration: const BoxDecoration(
        gradient: IvoryColors.pageGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: Container(
                  width: 46,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.category.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'From ₹${widget.category.basePriceInr} · usually ready in '
                '${widget.category.deliveryDays} days',
                style: TextStyle(
                  fontSize: 13,
                  color: IvoryColors.textSoft,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Give your wish a name',
                  hintText: 'A letter for a rainy Sunday',
                ),
                validator: (String? v) => (v == null || v.trim().length < 3)
                    ? 'Please name your wish'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _details,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Describe it in your own words',
                  hintText:
                      'The mood, the place, the names, how it should end...',
                  alignLabelWithHint: true,
                ),
                validator: (String? v) => (v == null || v.trim().length < 10)
                    ? 'Tell me a little more'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Your offer in ₹',
                  prefixText: '₹ ',
                ),
                validator: (String? v) {
                  final int? n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter an amount';
                  if (n < widget.category.basePriceInr) {
                    return 'This wish starts at ₹${widget.category.basePriceInr}';
                  }
                  return null;
                },
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style:
                      const TextStyle(color: IvoryColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              IvoryGradientButton(
                label: _sending ? 'SENDING...' : 'MAKE THIS WISH',
                icon: Icons.auto_awesome,
                busy: _sending,
                onPressed: _sending ? null : _submit,
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing is charged yet. I will reply in your inbox with a '
                'yes and a payment link, or with questions.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: IvoryColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/screens/wish_form.dart

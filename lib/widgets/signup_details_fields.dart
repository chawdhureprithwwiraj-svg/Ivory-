import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'ivory_field.dart';

class SignupPersonalDetails {
  const SignupPersonalDetails({this.phoneNumber, this.dateOfBirth});

  final String? phoneNumber;
  final String? dateOfBirth;
}

class SignupDetailsFields extends StatefulWidget {
  const SignupDetailsFields({super.key});

  @override
  SignupDetailsFieldsState createState() => SignupDetailsFieldsState();
}

class SignupDetailsFieldsState extends State<SignupDetailsFields> {
  final TextEditingController _phone = TextEditingController();
  DateTime? _birthday;

  SignupPersonalDetails get details => SignupPersonalDetails(
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        dateOfBirth: _dateOnly(_birthday),
      );

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _chooseBirthday() async {
    final DateTime today = DateTime.now();
    final DateTime latestAllowed = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? latestAllowed,
      firstDate: DateTime(1900),
      lastDate: latestAllowed,
      helpText: 'Choose your real birthday',
    );
    if (picked == null || !mounted) return;
    setState(() => _birthday = DateTime(picked.year, picked.month, picked.day));
  }

  static String? _dateOnly(DateTime? date) {
    if (date == null) return null;
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _birthdayLabel() {
    final DateTime? d = _birthday;
    if (d == null) return 'Tap to choose — or leave blank';
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        IvoryField(
          controller: _phone,
          label: 'Phone number (optional)',
          hint: 'Not needed to create or sign in',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
          validator: (String? value) {
            final String entered = value?.trim() ?? '';
            if (entered.isEmpty) return null;
            final int digits = entered.replaceAll(RegExp(r'\D'), '').length;
            return digits < 7 || digits > 15
                ? 'Enter a valid number, or leave this blank.'
                : null;
          },
        ),
        const SizedBox(height: 5),
        Text(
          'Optional. It is not used for sign-in or shown to other members.',
          style: TextStyle(
            color: IvoryColors.textFaint,
            fontSize: 11.8,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: _chooseBirthday,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of birth (optional)',
              prefixIcon: Icon(Icons.cake_outlined, size: 20),
              suffixIcon: Icon(Icons.calendar_month_outlined, size: 20),
            ),
            child: Text(
              _birthdayLabel(),
              style: TextStyle(
                color: _birthday == null
                    ? IvoryColors.textFaint
                    : IvoryColors.burgundy,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (_birthday != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _birthday = null),
              icon: const Icon(Icons.close_rounded, size: 15),
              label: const Text('Clear optional date'),
            ),
          ),
        const SizedBox(height: 5),
        Text(
          'Share your real birthday and Ivory will try to prepare a small '
          'birthday token. You may end up getting a true surprise\n'
          'Your birthday is optional and is not shown to other members.',
          style: TextStyle(
            color: IvoryColors.textFaint,
            fontSize: 11.8,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// END OF FILE - lib/widgets/signup_details_fields.dart

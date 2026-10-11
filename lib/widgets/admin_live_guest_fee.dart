import 'package:flutter/material.dart';

import '../theme/ivory_theme.dart';
import 'admin_bits.dart';

class AdminLiveGuestFee extends StatelessWidget {
  const AdminLiveGuestFee({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminLabel('Guest co-host fee per person'),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '0 = guest requests off'),
          ),
          const SizedBox(height: 5),
          Text(
            'Separate from the viewing pass. Set zero to turn guest places off.',
            style: TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
          ),
        ],
      );
}

// END OF FILE - lib/widgets/admin_live_guest_fee.dart

import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../theme/ivory_theme.dart';

/// ============================================================
/// THE THREE PANELS ON THE PAYMENT SCREEN THAT ARE PURE
/// DISPLAY.
///
/// Lifted out of checkout_screen.dart, which at 19,509 bytes
/// was the largest file in the app and over the size that can
/// be pasted reliably on a phone. Nothing about them changed
/// in the move.
///
/// All three are static: they say what has happened, they ask
/// nothing, and they read nothing that can change while the
/// screen is open. Keeping them away from the payment logic is
/// deliberate - the part of this screen that handles money
/// should be small enough to read in one sitting.
/// ============================================================
class CheckoutCards {
  const CheckoutCards._();

  /// Sent, and waiting on a human to confirm it.
  static Widget submitted(BuildContext context, String tierName) =>
      _statusCard(
        context,
        icon: Icons.hourglass_top_rounded,
        title: 'Pending verification',
        body: 'Thank you. Your payment is with us now. You will get a '
            'notification the moment $tierName is unlocked - '
            'usually within a few hours.',
        action: 'BACK TO MEMBERSHIPS',
      );

  /// An earlier payment is still being checked.
  static Widget pending(BuildContext context, IvoryPayment p) =>
      _statusCard(
        context,
        icon: Icons.hourglass_top_rounded,
        title: 'A payment is already being checked',
        body: '₹${p.amountInr} for ${p.tierName ?? 'a membership'} '
            '(UTR ${p.utr}) is still pending verification. Please wait for '
            'that one to be settled before sending another.',
        action: 'GO BACK',
      );

  static Widget _statusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String action,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: IvoryTheme.card(highlighted: true, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: IvoryColors.burgundy, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: IvoryTheme.displayFont,
                    color: IvoryColors.burgundy,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              color: IvoryColors.textSoft,
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          IvoryGradientButton(
            label: action,
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  /// The one thing that matters on a money screen: what the
  /// house will never ask you for.
  static Widget safetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IvoryColors.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IvoryColors.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.shield_outlined, color: IvoryColors.plum, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Each reference number can be used exactly once, and every '
              'payment is verified by hand before anything unlocks. We never '
              'ask for your PIN, OTP or card details.',
              style: TextStyle(
                color: IvoryColors.textFaint,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// END OF FILE - lib/widgets/checkout_cards.dart

import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../services/razorpay_service.dart';
import '../theme/ivory_theme.dart';

/// One row in "Your wishes" - the historical list further down
/// the page. The live gold cards at the top are a different
/// thing; this is the quieter record underneath them.
Widget wishStatusCard(Wish w, {required String mode}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: IvoryTheme.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  w.title,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  w.statusLabel.toUpperCase(),
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${w.categoryName} · ₹${w.budgetInr}',
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 12.5,
            ),
          ),
          if (w.adminReply != null && w.adminReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              w.adminReply!,
              style: TextStyle(
                color: IvoryColors.textSoft,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ],
          if (w.status == 'accepted' && mode == 'razorpay') ...<Widget>[
            const SizedBox(height: 12),
            RazorpayPayPanel(
              purpose: 'custom_request',
              customRequestId: w.id,
              label: w.title,
            ),
          ],
        ],
      ),
    ),
  );
}


// END OF FILE - lib/widgets/wish_status_card.dart

/// Where money should be sent. Read live from payment_settings, so the
/// UPI id is never compiled into the APK and can change any time.
class PaymentSettings {
  const PaymentSettings({
    required this.upiId,
    required this.payeeName,
    required this.noteTemplate,
    required this.instructions,
    this.supportNote,
  });

  final String upiId;
  final String payeeName;
  final String noteTemplate;
  final String instructions;
  final String? supportNote;

  bool get isConfigured =>
      upiId.contains('@') && !upiId.startsWith('yourname@');

  factory PaymentSettings.fromMap(Map<String, dynamic> m) => PaymentSettings(
        upiId: (m['upi_id'] as String?) ?? '',
        payeeName: (m['payee_name'] as String?) ?? 'Ivory',
        noteTemplate: (m['note_template'] as String?) ?? 'Ivory membership',
        instructions: (m['instructions'] as String?) ?? '',
        supportNote: m['support_note'] as String?,
      );

  /// Builds the standard UPI deep link every Indian payment app honours.
  Uri intentUri({required int amountInr, required String note}) {
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: <String, String>{
        'pa': upiId,
        'pn': payeeName,
        'am': amountInr.toString(),
        'cu': 'INR',
        'tn': note,
      },
    );
  }
}

/// A payment the member has submitted.
class IvoryPayment {
  const IvoryPayment({
    required this.id,
    required this.amountInr,
    required this.utr,
    required this.status,
    this.tierName,
    this.tierLevel,
    this.adminNote,
    this.screenshotUrl,
    this.payerName,
    this.createdAt,
  });

  final int id;
  final int amountInr;
  final String utr;
  final String status;
  final String? tierName;
  final int? tierLevel;
  final String? adminNote;
  final String? screenshotUrl;
  final String? payerName;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending verification';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Not verified';
      default:
        return status;
    }
  }

  factory IvoryPayment.fromMap(Map<String, dynamic> m) => IvoryPayment(
        id: (m['id'] as num).toInt(),
        amountInr: ((m['amount_inr'] as num?) ?? 0).toInt(),
        utr: (m['utr'] as String?) ?? '',
        status: (m['status'] as String?) ?? 'pending',
        tierName: m['tier_name'] as String?,
        tierLevel: (m['tier_level'] as num?)?.toInt(),
        adminNote: m['admin_note'] as String?,
        screenshotUrl: m['screenshot_url'] as String?,
        payerName: m['payer_name'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );
}

/// The membership currently running, if any.
class Membership {
  const Membership({
    required this.tierName,
    required this.tierLevel,
    required this.daysLeft,
    this.expiresAt,
  });

  final String tierName;
  final int tierLevel;
  final int daysLeft;
  final DateTime? expiresAt;

  factory Membership.fromMap(Map<String, dynamic> m) => Membership(
        tierName: (m['tier_name'] as String?) ?? 'Member',
        tierLevel: ((m['tier_level'] as num?) ?? 0).toInt(),
        daysLeft: ((m['days_left'] as num?) ?? 0).toInt(),
        expiresAt: DateTime.tryParse((m['expires_at'] as String?) ?? ''),
      );
}

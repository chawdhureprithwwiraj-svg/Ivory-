import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment.dart';

/// UPI payments. Every rule that matters - valid UTR, no duplicate UTR,
/// who may approve - lives in the database, so nothing here can be
/// talked out of it by a tampered app.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  SupabaseClient get _db => Supabase.instance.client;

  Future<PaymentSettings> fetchSettings() async {
    final Map<String, dynamic> row =
        await _db.from('payment_settings').select().eq('id', 1).single();
    return PaymentSettings.fromMap(row);
  }

  /// The tier currently running for this member, or null.
  Future<Membership?> fetchMembership() async {
    final List<dynamic> rows = await _db
        .from('my_membership')
        .select()
        .order('tier_level', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return Membership.fromMap(rows.first as Map<String, dynamic>);
  }

  Future<List<IvoryPayment>> fetchMyPayments() async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) return <IvoryPayment>[];
    final List<dynamic> rows = await _db
        .from('my_payments')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return rows
        .map((dynamic r) => IvoryPayment.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Admin: everything waiting, newest first.
  Future<List<IvoryPayment>> fetchAllPayments({String? status}) async {
    dynamic q = _db.from('my_payments').select();
    if (status != null) q = q.eq('status', status);
    final List<dynamic> rows =
        await q.order('created_at', ascending: false).limit(100);
    return rows
        .map((dynamic r) => IvoryPayment.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  /// Uploads the receipt screenshot to a private per-user folder and
  /// returns the storage path. Returns null if anything goes wrong -
  /// a missing screenshot must never block a real payment.
  Future<String?> uploadProof(File file) async {
    try {
      final String? uid = _db.auth.currentUser?.id;
      if (uid == null) return null;
      final String ext = file.path.split('.').last.toLowerCase();
      final String path =
          '$uid/${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
      await _db.storage.from('payment-proofs').upload(path, file);
      return path;
    } catch (_) {
      return null;
    }
  }

  /// A viewable link for a stored proof (the bucket is private).
  Future<String?> signedProofUrl(String path) async {
    try {
      return await _db.storage
          .from('payment-proofs')
          .createSignedUrl(path, 60 * 30);
    } catch (_) {
      return null;
    }
  }

  Future<int> submit({
    required int tierId,
    required String utr,
    String? screenshotPath,
  }) async {
    final dynamic id = await _db.rpc('submit_payment', params: <String, dynamic>{
      'tier_id_in': tierId,
      'utr_in': utr,
      'screenshot_url_in': screenshotPath,
    });
    return (id as num).toInt();
  }

  Future<void> approve(int paymentId) => _db.rpc(
        'approve_payment',
        params: <String, dynamic>{'payment_id_in': paymentId},
      );

  Future<void> reject(int paymentId, String? reason) => _db.rpc(
        'reject_payment',
        params: <String, dynamic>{
          'payment_id_in': paymentId,
          'reason_in': reason,
        },
      );

  /// Cheap housekeeping so an expired tier really does lock again.
  Future<void> expireOld() async {
    try {
      await _db.rpc('expire_subscriptions');
    } catch (_) {
      // Never let housekeeping break a launch.
    }
  }

  /// Admin: change where the money goes.
  Future<void> updateSettings({
    required String upiId,
    required String payeeName,
  }) async {
    await _db.from('payment_settings').update(<String, dynamic>{
      'upi_id': upiId.trim(),
      'payee_name': payeeName.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', 1);
  }

  /// Turns a Postgres error into something a reader understands.
  static String friendly(Object e) {
    final String m = e.toString();
    if (m.contains('already been submitted')) {
      return 'That reference number has already been used. Each UPI payment '
          'can only be submitted once.';
    }
    if (m.contains('does not look like a UTR')) {
      return 'That does not look right. Copy the 12-digit UTR or reference '
          'number from your payment receipt.';
    }
    if (m.contains('not available')) {
      return 'That membership is not available right now.';
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}

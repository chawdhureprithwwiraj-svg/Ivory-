import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wish.dart';

/// "Close your eyes and make a wish" - custom virtual requests.
class WishService {
  WishService._();
  static final WishService instance = WishService._();

  SupabaseClient get _db => Supabase.instance.client;

  /// The catalogue. Whatever rows are active, in whatever order the
  /// database says - the app never hardcodes a list or a price.
  Future<List<WishCategory>> fetchCategories() async {
    final List<dynamic> rows = await _db
        .from('wish_categories')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return rows
        .map((dynamic r) => WishCategory.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Wish>> fetchMyWishes() async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) return <Wish>[];
    final List<dynamic> rows = await _db
        .from('my_wishes')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return rows.map((dynamic r) => Wish.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// Admin view: every wish from everyone.
  Future<List<Wish>> fetchAllWishes() async {
    final List<dynamic> rows = await _db
        .from('my_wishes')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return rows.map((dynamic r) => Wish.fromMap(r as Map<String, dynamic>)).toList();
  }

  Future<void> makeWish({
    required WishCategory category,
    required String title,
    required String details,
    required int budgetInr,
  }) async {
    final String? uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('You need to be signed in to make a wish.');
    }
    await _db.from('custom_requests').insert(<String, dynamic>{
      'user_id': uid,
      'category_id': category.id,
      'title': title.trim(),
      'details': details.trim(),
      'budget_inr': budgetInr,
      'status': 'submitted',
    });
  }

  /// Admin: move a wish along. The database automatically notifies the
  /// person who made it.
  Future<void> updateStatus({
    required int wishId,
    required String status,
    String? adminReply,
    String? deliveryUrl,
  }) async {
    final Map<String, dynamic> patch = <String, dynamic>{'status': status};
    if (adminReply != null) patch['admin_reply'] = adminReply;
    if (deliveryUrl != null) patch['delivery_url'] = deliveryUrl;
    if (status == 'delivered') {
      patch['delivered_at'] = DateTime.now().toUtc().toIso8601String();
    }
    await _db.from('custom_requests').update(patch).eq('id', wishId);
  }
}

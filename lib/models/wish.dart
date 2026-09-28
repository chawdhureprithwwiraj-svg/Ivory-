/// A kind of wish that can be requested. These are DATA ROWS in
/// public.wish_categories - add, rename, reprice or retire one with a
/// single SQL statement and the app follows without a rebuild.
class WishCategory {
  const WishCategory({
    required this.id,
    required this.name,
    required this.basePriceInr,
    required this.deliveryDays,
    this.tagline,
    this.icon = 'auto_awesome',
  });

  final int id;
  final String name;
  final String? tagline;
  final String icon;
  final int basePriceInr;
  final int deliveryDays;

  String get priceLabel => '₹$basePriceInr onwards';

  factory WishCategory.fromMap(Map<String, dynamic> m) => WishCategory(
        id: (m['id'] as num).toInt(),
        name: (m['name'] as String?) ?? 'A Wish',
        tagline: m['tagline'] as String?,
        icon: (m['icon'] as String?) ?? 'auto_awesome',
        basePriceInr: ((m['base_price_inr'] as num?) ?? 999).toInt(),
        deliveryDays: ((m['delivery_days'] as num?) ?? 3).toInt(),
      );
}

/// A wish somebody has actually made.
class Wish {
  const Wish({
    required this.id,
    required this.categoryName,
    required this.title,
    required this.details,
    required this.budgetInr,
    required this.status,
    this.adminReply,
    this.deliveryUrl,
    this.requesterName,
    this.createdAt,
  });

  final int id;
  final String categoryName;
  final String title;
  final String details;
  final int budgetInr;
  final String status;
  final String? adminReply;
  final String? deliveryUrl;
  final String? requesterName;
  final DateTime? createdAt;

  factory Wish.fromMap(Map<String, dynamic> m) => Wish(
        id: (m['id'] as num).toInt(),
        categoryName: (m['category_name'] as String?) ?? 'A Wish',
        title: (m['title'] as String?) ?? '',
        details: (m['details'] as String?) ?? '',
        budgetInr: ((m['budget_inr'] as num?) ?? 0).toInt(),
        status: (m['status'] as String?) ?? 'submitted',
        adminReply: m['admin_reply'] as String?,
        deliveryUrl: m['delivery_url'] as String?,
        requesterName: m['requester_name'] as String?,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? ''),
      );

  static const List<String> allStatuses = <String>[
    'submitted',
    'accepted',
    'in_progress',
    'delivered',
    'declined',
  ];

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Received';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'Being made';
      case 'delivered':
        return 'Delivered';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }
}

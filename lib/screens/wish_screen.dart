import 'package:flutter/material.dart';

import '../models/wish.dart';
import '../services/wish_service.dart';
import '../theme/ivory_theme.dart';

/// Material icons the database is allowed to name, so wish categories
/// can pick their own look without a rebuild.
IconData wishIcon(String name) {
  const Map<String, IconData> icons = <String, IconData>{
    'auto_awesome': Icons.auto_awesome,
    'auto_stories': Icons.auto_stories,
    'graphic_eq': Icons.graphic_eq,
    'movie_creation': Icons.movie_creation,
    'drafts': Icons.drafts,
    'favorite': Icons.favorite,
    'nightlight': Icons.nightlight_round,
    'mic': Icons.mic,
    'photo_camera': Icons.photo_camera,
    'card_giftcard': Icons.card_giftcard,
    'edit_note': Icons.edit_note,
    'videocam': Icons.videocam,
  };
  return icons[name] ?? Icons.auto_awesome;
}

class WishScreen extends StatefulWidget {
  const WishScreen({super.key});

  @override
  State<WishScreen> createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  List<WishCategory> _categories = <WishCategory>[];
  List<Wish> _mine = <Wish>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<WishCategory> cats =
          await WishService.instance.fetchCategories();
      final List<Wish> mine = await WishService.instance.fetchMyWishes();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _mine = mine;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _startingPrice => _categories.isEmpty
      ? 999
      : _categories
          .map((WishCategory c) => c.basePriceInr)
          .reduce((int a, int b) => a < b ? a : b);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: IvoryColors.pageGradient),
      child: RefreshIndicator(
        color: IvoryColors.burgundy,
        backgroundColor: IvoryColors.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
          children: <Widget>[
            _hero(),
            const SizedBox(height: 24),
            Text(
              'What would you like made?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Every wish is virtual, personal, and made only for you.',
              style: TextStyle(
                fontSize: 13.5,
                color: IvoryColors.textSoft,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 50),
                child: Center(
                  child: CircularProgressIndicator(color: IvoryColors.burgundy),
                ),
              )
            else if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: IvoryColors.danger, fontSize: 13),
              )
            else
              ..._categories.map(_categoryCard),
            if (_mine.isNotEmpty) ...<Widget>[
              const SizedBox(height: 28),
              Text(
                'Your wishes',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              ..._mine.map(_wishStatusCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: IvoryColors.deepGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: IvoryColors.gold, width: 1.4),
        boxShadow: IvoryTheme.softShadow(blur: 22, y: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    color: IvoryColors.burgundy, size: 24),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  'THE WISH',
                  style: TextStyle(
                    color: IvoryColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Just close your eyes\nand make a wish',
            style: TextStyle(
              fontFamily: IvoryTheme.displayFont,
              color: IvoryColors.cream,
              fontSize: 27,
              height: 1.22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Request anything from me — entirely virtual. A story with your '
            'name in it, a voice note meant only for you, a vignette shot to '
            'your brief. You describe it, I make it.',
            style: TextStyle(
              color: IvoryColors.cream.withValues(alpha: 0.84),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: IvoryColors.goldGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  '₹$_startingPrice onwards',
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Virtual only · Consensual · Discreet',
                  style: TextStyle(
                    color: IvoryColors.cream.withValues(alpha: 0.7),
                    fontSize: 11.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(WishCategory c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openWishForm(c),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: IvoryTheme.card(),
            child: Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: IvoryColors.goldGradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(wishIcon(c.icon),
                      color: IvoryColors.burgundy, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (c.tagline != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          c.tagline!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: IvoryColors.textSoft,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Text(
                            c.priceLabel,
                            style: const TextStyle(
                              color: IvoryColors.plum,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '~${c.deliveryDays} days',
                            style: TextStyle(
                              fontSize: 12,
                              color: IvoryColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: IvoryColors.plum),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wishStatusCard(Wish w) {
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
          ],
        ),
      ),
    );
  }

  void _openWishForm(WishCategory c) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _WishForm(
          category: c,
          onDone: () {
            Navigator.of(context).pop();
            _load();
          },
        ),
      ),
    );
  }
}

class _WishForm extends StatefulWidget {
  const _WishForm({required this.category, required this.onDone});

  final WishCategory category;
  final VoidCallback onDone;

  @override
  State<_WishForm> createState() => _WishFormState();
}

class _WishFormState extends State<_WishForm> {
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

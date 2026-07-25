import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../services/cart_service.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String id;
  const EquipmentDetailScreen({super.key, required this.id});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  int _quantity = 1;
  int _days = 1;
  bool _isFav = false;

  static final Map<String, Map<String, dynamic>> _mockDetails = {
    '1': {
      'id': '1',
      'name': 'Professional PA System 5000W',
      'price': '₹1,500/day',
      'priceAmount': 1500.0,
      'emoji': '🎤',
      'category': 'Sound',
      'description': 'High-power professional PA system for concerts and events.',
      'rating': '4.8',
      'vendorId': 'mock_vendor_1',
    },
    '2': {
      'id': '2',
      'name': 'LED Stage Lighting Kit',
      'price': '₹2,000/day',
      'priceAmount': 2000.0,
      'emoji': '💡',
      'category': 'Lighting',
      'description': 'RGB stage lights with controller and stands.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_2',
    },
    '3': {
      'id': '3',
      'name': 'Portable Stage Platform',
      'price': '₹3,000/day',
      'priceAmount': 3000.0,
      'emoji': '🎭',
      'category': 'Staging',
      'description': 'Sturdy modular staging platforms for events.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_3',
    },
    '4': {
      'id': '4',
      'name': 'Wireless Microphone Set',
      'price': '₹800/day',
      'priceAmount': 800.0,
      'emoji': '🎙️',
      'category': 'Sound',
      'description': 'Dual wireless handheld microphones with receiver.',
      'rating': '4.6',
      'vendorId': 'mock_vendor_1',
    },
    '5': {
      'id': '5',
      'name': '4K Projector & Screen',
      'price': '₹1,200/day',
      'priceAmount': 1200.0,
      'emoji': '📽️',
      'category': 'AV',
      'description': 'High brightness 4K projector with large screen.',
      'rating': '4.8',
      'vendorId': 'mock_vendor_2',
    },
    '6': {
      'id': '6',
      'name': 'DJ Controller Setup',
      'price': '₹1,800/day',
      'priceAmount': 1800.0,
      'emoji': '🎛️',
      'category': 'Sound',
      'description': 'Pioneer DJ controller with laptop stand.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_1',
    },
    '7': {
      'id': '7',
      'name': 'Chiavari Chair Set (50)',
      'price': '₹2,500/day',
      'priceAmount': 2500.0,
      'emoji': '🪑',
      'category': 'Furniture',
      'description': 'Elegant wooden chairs for receptions and gala events.',
      'rating': '4.5',
      'vendorId': 'mock_vendor_3',
    },
    '8': {
      'id': '8',
      'name': 'Moving Head Spot Light',
      'price': '₹900/day',
      'priceAmount': 900.0,
      'emoji': '🔦',
      'category': 'Lighting',
      'description': 'DMX controlled moving head light for concerts.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_2',
    },
    '9': {
      'id': '9',
      'name': 'Shamiyana Marquee Tent (30x30 ft)',
      'price': '₹4,500/day',
      'priceAmount': 4500.0,
      'emoji': '⛺',
      'category': 'Tent',
      'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_3',
    },
    '10': {
      'id': '10',
      'name': 'Stage & Floral Decorations',
      'price': '₹8,000/day',
      'priceAmount': 8000.0,
      'emoji': '💐',
      'category': 'Decor',
      'description': 'Complete wedding and event stage floral decoration with custom theme backdrop and entry arch.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_3',
    },
    '11': {
      'id': '11',
      'name': 'Buffet Food Tables (Set of 10)',
      'price': '₹1,500/day',
      'priceAmount': 1500.0,
      'emoji': '🍽️',
      'category': 'Furniture',
      'description': '10 heavy-duty stainless steel buffet food tables with elegant satin cloth coverings.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_3',
    },
    'sample_tent_1': {
      'id': 'sample_tent_1',
      'name': 'Shamiyana Marquee Tent (30x30 ft)',
      'price': '₹4,500/day',
      'priceAmount': 4500.0,
      'emoji': '⛺',
      'category': 'Tent',
      'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_3',
    },
    'sample_decor_1': {
      'id': 'sample_decor_1',
      'name': 'Stage & Floral Decorations',
      'price': '₹8,000/day',
      'priceAmount': 8000.0,
      'emoji': '💐',
      'category': 'Decor',
      'description': 'Complete wedding & event stage floral decoration with custom theme backdrop and entry arch.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_3',
    },
    'sample_food_1': {
      'id': 'sample_food_1',
      'name': 'Buffet Food Tables (Set of 10)',
      'price': '₹1,500/day',
      'priceAmount': 1500.0,
      'emoji': '🍽️',
      'category': 'Furniture',
      'description': '10 heavy-duty stainless steel buffet food tables with elegant satin cloth coverings.',
      'rating': '4.7',
      'vendorId': 'mock_vendor_3',
    },
  };

  Future<Map<String, dynamic>?> _loadItem() async {
    final fsItem = await FirebaseService().getEquipmentById(widget.id);
    if (fsItem != null) return fsItem;
    if (_mockDetails.containsKey(widget.id)) {
      return _mockDetails[widget.id];
    }
    
    // Dynamic matching by string ID
    final lowercaseId = widget.id.toLowerCase();
    if (lowercaseId.contains('tent') || lowercaseId == '9') {
      return _mockDetails['sample_tent_1'];
    }
    if (lowercaseId.contains('decor') || lowercaseId == '10') {
      return _mockDetails['sample_decor_1'];
    }
    if (lowercaseId.contains('food') || lowercaseId.contains('buffet') || lowercaseId == '11') {
      return _mockDetails['sample_food_1'];
    }

    // Default fallback item
    return {
      'id': widget.id,
      'name': 'Shamiyana Marquee Tent (30x30 ft)',
      'price': '₹4,500/day',
      'priceAmount': 4500.0,
      'emoji': '⛺',
      'category': 'Tent',
      'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
      'rating': '4.9',
      'vendorId': 'mock_vendor_3',
    };
  }

  void _addToCart(Map<String, dynamic> item, {bool navigateToCart = false}) {
    final priceAmount = item['priceAmount'] != null
        ? (item['priceAmount'] as num).toDouble()
        : 1000.0;

    final cartItem = CartItem(
      id: item['id'] as String? ?? widget.id,
      name: item['name'] as String? ?? 'Equipment Item',
      price: priceAmount,
      qty: _quantity,
      days: _days,
      emoji: item['emoji'] as String? ?? '⛺',
      vendorId: item['vendorId'] as String? ?? '',
    );

    CartService().addItem(cartItem);

    if (navigateToCart) {
      context.go('/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${cartItem.name} added to cart!',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadItem(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final item = snapshot.data ?? {
          'id': 'sample_tent_1',
          'name': 'Shamiyana Marquee Tent (30x30 ft)',
          'price': '₹4,500/day',
          'priceAmount': 4500.0,
          'emoji': '⛺',
          'category': 'Tent',
          'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
          'rating': '4.9',
          'vendorId': 'mock_vendor_3',
        };

        final priceAmount = item['priceAmount'] != null
            ? (item['priceAmount'] as num).toDouble()
            : 0.0;
        final rawPriceStr = item['price'] as String? ?? '';
        final displayPrice = priceAmount > 0
            ? '₹${priceAmount.toStringAsFixed(0)}/day'
            : rawPriceStr.isNotEmpty
                ? rawPriceStr.replaceAll('\$', '₹')
                : 'Price on request';
        final name = item['name'] as String? ?? 'Shamiyana Marquee Tent (30x30 ft)';
        final emoji = item['emoji'] as String? ?? '⛺';
        final category = item['category'] as String? ?? 'Tent';
        final description = item['description'] as String? ?? 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.';
        final rating = item['rating'] ?? '4.9';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── App Bar Header with Banner Emoji ─────────────────────────────
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.softShadow,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                      ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.softShadow,
                        ),
                        child: IconButton(
                          onPressed: () => setState(() => _isFav = !_isFav),
                          icon: Icon(
                            _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFav ? const Color(0xFFEF4444) : AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.backgroundGradient,
                        ),
                        child: Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1F4F46E5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 80)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Detail Cards Body ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.bubbleShadow,
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Item Name
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Rating & Location row
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '$rating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 4),
                              const Text(
                                'Verified Vendor Partner',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price tag
                          Text(
                            displayPrice,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quantity selector card
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      _QtyBtn(
                                        icon: Icons.remove_rounded,
                                        onTap: () {
                                          if (_quantity > 1) {
                                            setState(() => _quantity--);
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          '$_quantity',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      _QtyBtn(
                                        icon: Icons.add_rounded,
                                        onTap: () => setState(() => _quantity++),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Rental Duration selector card
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Rental Duration',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Row(
                                    children: [
                                      _QtyBtn(
                                        icon: Icons.remove_rounded,
                                        onTap: () {
                                          if (_days > 1) {
                                            setState(() => _days--);
                                          }
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Text(
                                          '$_days day${_days > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      _QtyBtn(
                                        icon: Icons.add_rounded,
                                        onTap: () => setState(() => _days++),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Description Card
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Bottom Fixed Action Buttons (Add to Cart & Book Now) ───────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F0F172A),
                        blurRadius: 20,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Add to Cart (Outline Button)
                      Expanded(
                        child: AppButton(
                          text: 'Add to Cart',
                          variant: ButtonVariant.outline,
                          onPressed: () => _addToCart(item),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Book Now (Filled Gradient Button)
                      Expanded(
                        child: AppButton(
                          text: 'Book Now',
                          variant: ButtonVariant.primary,
                          onPressed: () => _addToCart(item, navigateToCart: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

// ── Real-world photo URLs by category/keyword (Unsplash) ─────────────────────
String _itemImageUrl(String name, String category) {
  final n = name.toLowerCase();
  final c = category.toLowerCase();
  // Name-specific overrides
  if (n.contains('shamiyana') || n.contains('marquee') || n.contains('tent')) {
    return 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80';
  }
  if (n.contains('floral') || n.contains('decor') || n.contains('flower')) {
    return 'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80';
  }
  if (n.contains('buffet') || n.contains('food table') || n.contains('catering')) {
    return 'https://images.unsplash.com/photo-1555244162-803834f70033?w=600&q=80';
  }
  if (n.contains('pa system') || n.contains('speaker') || n.contains('sound system')) {
    return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80';
  }
  if (n.contains('microphone') || n.contains('mic') || n.contains('wireless mic')) {
    return 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600&q=80';
  }
  if (n.contains('dj') || n.contains('controller') || n.contains('mixing')) {
    return 'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=600&q=80';
  }
  if (n.contains('projector') || n.contains('screen') || n.contains('av')) {
    return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=600&q=80';
  }
  if (n.contains('stage') && (n.contains('light') || n.contains('led'))) {
    return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80';
  }
  if (n.contains('moving head') || n.contains('spotlight') || n.contains('strobe')) {
    return 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80';
  }
  if (n.contains('chiavari') || n.contains('chair') || n.contains('seating')) {
    return 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=600&q=80';
  }
  if (n.contains('table') || n.contains('furniture') || n.contains('banquet')) {
    return 'https://images.unsplash.com/photo-1578874691223-64558a3ca096?w=600&q=80';
  }
  if (n.contains('stage platform') || n.contains('stage') || n.contains('staging')) {
    return 'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=600&q=80';
  }
  if (n.contains('generator') || n.contains('power')) {
    return 'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=600&q=80';
  }
  // Category fallbacks
  switch (c) {
    case 'tent': return 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80';
    case 'decor': return 'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80';
    case 'sound': return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80';
    case 'lighting': return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80';
    case 'staging': return 'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=600&q=80';
    case 'av': return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=600&q=80';
    case 'furniture': return 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=600&q=80';
    default: return 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&q=80';
  }
}

class VendorItemsScreen extends StatefulWidget {
  final String vendorId;
  const VendorItemsScreen({super.key, required this.vendorId});

  @override
  State<VendorItemsScreen> createState() => _VendorItemsScreenState();
}

class _VendorItemsScreenState extends State<VendorItemsScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: service.getUserById(widget.vendorId),
        builder: (context, vendorSnap) {
          final vendor = vendorSnap.data ??
              UserModel(
                id: widget.vendorId,
                name: 'Verified Partner',
                email: '',
                phone: '',
                location: 'Local Region',
                role: 'Vendor',
                createdAt: DateTime.now(),
                shopName: 'Partner Shop',
              );

          return Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              GradientHeader(
                title: vendor.shopName ?? 'Equipment Catalog',
                subtitle: 'By ${vendor.name} • ${vendor.location}',
                leading: IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                ),
              ),

              // ── Items from Firestore ─────────────────────────────────────────
              Expanded(
                child: Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.backgroundGradient),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: service.getEquipmentByVendor(widget.vendorId),
                    builder: (context, itemsSnap) {
                      if (itemsSnap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.primary),
                        );
                      }

                      final firestoreItems = itemsSnap.data ?? [];
                      final sampleItems = [
                        {
                          'id': 'sample_tent_1',
                          'name': 'Shamiyana Marquee Tent (30x30 ft)',
                          'price': '₹4,500/day',
                          'priceAmount': 4500.0,
                          'category': 'Tent',
                          'emoji': '⛺',
                          'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
                          'rating': '4.9',
                        },
                        {
                          'id': 'sample_decor_1',
                          'name': 'Stage & Floral Decorations',
                          'price': '₹8,000/day',
                          'priceAmount': 8000.0,
                          'category': 'Decor',
                          'emoji': '💐',
                          'description': 'Complete wedding & event stage floral decoration with custom theme backdrop and entry arch.',
                          'rating': '4.9',
                        },
                        {
                          'id': 'sample_food_1',
                          'name': 'Buffet Food Tables (Set of 10)',
                          'price': '₹1,500/day',
                          'priceAmount': 1500.0,
                          'category': 'Furniture',
                          'emoji': '🍽️',
                          'description': '10 heavy-duty stainless steel buffet food tables with elegant satin cloth coverings.',
                          'rating': '4.7',
                        },
                      ];

                      final existingNames = firestoreItems
                          .map((e) => (e['name'] as String? ?? '').toLowerCase())
                          .toSet();
                      final allItems = [
                        ...firestoreItems,
                        ...sampleItems.where((s) =>
                            !existingNames.contains((s['name'] as String).toLowerCase())),
                      ];

                      if (allItems.isEmpty) {
                        return _EmptyState(
                            shopName: vendor.shopName ?? vendor.name);
                      }

                      // Build category filter list from actual item categories
                      final categories = <String>{};
                      for (final item in allItems) {
                        final cat = item['category'] as String? ?? '';
                        if (cat.isNotEmpty) categories.add(cat);
                      }
                      final filterList = [
                        'All',
                        ...categories.toList()..sort()
                      ];

                      final items = _selectedCategory == 'All'
                          ? allItems
                          : allItems
                              .where((i) =>
                                  (i['category'] as String? ?? '') ==
                                  _selectedCategory)
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Category filter chips ────────────────────────────
                          if (filterList.length > 1)
                            SizedBox(
                              height: 52,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                scrollDirection: Axis.horizontal,
                                itemCount: filterList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final cat = filterList[i];
                                  final sel = cat == _selectedCategory;
                                  return GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedCategory = cat),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: sel
                                            ? AppColors.primaryGradient
                                            : null,
                                        color: sel
                                            ? null
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sel
                                              ? AppColors.primary
                                              : const Color(0xFFE2E8F0),
                                          width: 1.2,
                                        ),
                                        boxShadow: sel ? AppColors.bubbleShadow : null,
                                      ),
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: sel
                                              ? Colors.white
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          // ── Item count ───────────────────────────────────────
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 4),
                            child: Text(
                              '${items.length} item${items.length == 1 ? '' : 's'} available',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // ── Grid ─────────────────────────────────────────────
                          Expanded(
                            child: items.isEmpty
                                ? Center(
                                    child: Text(
                                      'No items in "$_selectedCategory"',
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 110),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.75,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (_, index) =>
                                        _ItemCard(item: items[index]),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Item Card ────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Support both pre-formatted price string and raw amount
    final price = item['price'] as String? ?? '';
    final priceAmount = item['priceAmount'];
    final displayPrice = price.isNotEmpty
        ? price.replaceAll('\$', '₹')
        : priceAmount != null
            ? '₹${priceAmount.toStringAsFixed(0)}/day'
            : 'Price on request';

    final category = item['category'] as String? ?? '';
    final name = item['name'] as String? ?? 'Equipment Item';
    final rating = item['rating'] ?? '4.5';

    return GlassCard(
      onTap: () => context.push('/equipment-detail/${item['id']}'),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photo fills available space ───────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: double.infinity,
                child: Image.network(
                  _itemImageUrl(name, category),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: AppColors.textSecondary, size: 28),
                    ),
                  ),
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : Container(
                          color: const Color(0xFFF5F0E8),
                          child: const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // ── Category badge ───────────────────────────────────────────────
          if (category.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

          const SizedBox(height: 3),

          // ── Name ─────────────────────────────────────────────────────────
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 4),

          // ── Price + rating ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  displayPrice,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Row(children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                Text(
                  ' $rating',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String shopName;
  const _EmptyState({required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                shopName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "This vendor hasn't added any items yet.\nCheck back soon!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

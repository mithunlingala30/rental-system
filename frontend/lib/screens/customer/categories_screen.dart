import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';

// ── Real-world photo URLs by category/keyword ────────────────────────────
String _itemImageUrl(String name, String category) {
  final n = name.toLowerCase();
  final c = category.toLowerCase();
  if (n.contains('shamiyana') || n.contains('marquee') || n.contains('tent')) {
    return 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80';
  }
  if (n.contains('floral') || n.contains('decor') || n.contains('flower') || n.contains('decoration')) {
    return 'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80';
  }
  if (n.contains('buffet') || n.contains('food table') || n.contains('catering')) {
    return 'https://images.unsplash.com/photo-1555244162-803834f70033?w=600&q=80';
  }
  if (n.contains('pa system') || n.contains('speaker') || n.contains('5000')) {
    return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=600&q=80';
  }
  if (n.contains('microphone') || n.contains('mic') || n.contains('wireless mic')) {
    return 'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600&q=80';
  }
  if (n.contains('dj') || n.contains('controller') || n.contains('mixing')) {
    return 'https://images.unsplash.com/photo-1571266028243-3716f02d2d2e?w=600&q=80';
  }
  if (n.contains('projector') || n.contains('4k') || n.contains('screen')) {
    return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=600&q=80';
  }
  if (n.contains('led') || n.contains('stage light')) {
    return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80';
  }
  if (n.contains('moving head') || n.contains('spot light')) {
    return 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&q=80';
  }
  if (n.contains('chiavari') || n.contains('chair')) {
    return 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=600&q=80';
  }
  if (n.contains('stage platform') || n.contains('portable stage')) {
    return 'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=600&q=80';
  }
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

// ─── Categories Screen ────────────────────────────────────────────────────────
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim();
      });
    });
    _loadUserCity();
  }

  Future<void> _loadUserCity() async {
    final userProfile = await FirebaseService().getCurrentUserProfile();
    if (userProfile != null &&
        userProfile.location.isNotEmpty &&
        userProfile.location != 'Not set') {
      if (mounted && _searchCtrl.text.isEmpty) {
        _searchCtrl.text = userProfile.location;
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Pre-configured mock vendors to show when firestore users list is empty
  static final _mockVendors = [
    UserModel(
      id: 'mock_vendor_1',
      name: 'Sarah Connor',
      email: 'sarah@prosound.com',
      phone: '+1 (555) 123-4567',
      location: 'New York',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'ProSound & Stage Rentals',
      pincode: '10001',
    ),
    UserModel(
      id: 'mock_vendor_2',
      name: 'James Carter',
      email: 'james@luxlighting.com',
      phone: '+1 (555) 987-6543',
      location: 'Chicago',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'Lux Lighting & FX',
      pincode: '60601',
    ),
    UserModel(
      id: 'mock_vendor_3',
      name: 'Elena Rostova',
      email: 'elena@elitedecor.com',
      phone: '+1 (555) 456-7890',
      location: 'New York',
      role: 'Vendor',
      createdAt: DateTime.now(),
      shopName: 'Elite Stage & Staging',
      pincode: '10003',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Browse',
            subtitle: 'Find verified vendors in your city',
            bottom: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8E0D4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                  color: Color(0xFF5C1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search city name...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8B7355),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF5C1A1A)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF5C1A1A)),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: StreamBuilder<List<UserModel>>(
                stream: service.getVendorsByCity(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }

                  if (_searchQuery.isEmpty) {
                    return const Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(32),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                color: AppColors.primary,
                                size: 64,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Search Vendors by City',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please type a city name in the search bar above to view registered vendors.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Use fetched vendors, fall back to matching mock vendors if Firestore has no vendors
                  var vendors = snapshot.data ?? [];
                  if (vendors.isEmpty) {
                    final q = _searchQuery.toLowerCase();
                    vendors = _mockVendors
                        .where((v) => v.location.toLowerCase().contains(q))
                        .toList();
                  }

                  if (vendors.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: GlassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  color: AppColors.textSecondary, size: 64),
                              const SizedBox(height: 16),
                              const Text('No Vendors Found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              Text('We couldn\'t find any active vendors in "$_searchQuery". Try another city like "New York" or "Chicago".',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                    itemCount: vendors.length,
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          onTap: () => context.push('/vendor-items/${vendor.id}'),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppColors.accentGradient,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x338B5CF6),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.store_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendor.shopName ?? 'Event Partner',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Owner: ${vendor.name}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.primary,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${vendor.location} (PIN: ${vendor.pincode ?? "N/A"})',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Equipment Listing Screen ─────────────────────────────────────────────────
class EquipmentListingScreen extends StatefulWidget {
  const EquipmentListingScreen({super.key});

  @override
  State<EquipmentListingScreen> createState() => _EquipmentListingScreenState();
}

class _EquipmentListingScreenState extends State<EquipmentListingScreen> {
  String _selected = 'All';
  final _filters = ['All', 'Tent', 'Decor', 'Furniture', 'Sound', 'Lighting', 'Staging', 'AV'];

  final _items = [
    {'id': '1', 'name': 'Professional PA System 5000W', 'price': '₹1500/day', 'emoji': '🎤', 'rating': '4.8', 'cat': 'Sound'},
    {'id': '2', 'name': 'LED Stage Lighting Kit', 'price': '₹2000/day', 'emoji': '💡', 'rating': '4.9', 'cat': 'Lighting'},
    {'id': '3', 'name': 'Portable Stage Platform', 'price': '₹3000/day', 'emoji': '🎭', 'rating': '4.7', 'cat': 'Staging'},
    {'id': '4', 'name': 'Wireless Microphone Set', 'price': '₹800/day', 'emoji': '🎙️', 'rating': '4.6', 'cat': 'Sound'},
    {'id': '5', 'name': '4K Projector & Screen', 'price': '₹1200/day', 'emoji': '📽️', 'rating': '4.8', 'cat': 'AV'},
    {'id': '6', 'name': 'DJ Controller Setup', 'price': '₹1800/day', 'emoji': '🎛️', 'rating': '4.7', 'cat': 'Sound'},
    {'id': '7', 'name': 'Chiavari Chair Set (50)', 'price': '₹2500/day', 'emoji': '🪑', 'rating': '4.5', 'cat': 'Furniture'},
    {'id': '8', 'name': 'Moving Head Spot Light', 'price': '₹900/day', 'emoji': '🔦', 'rating': '4.9', 'cat': 'Lighting'},
    {'id': '9', 'name': 'Shamiyana Tent (30x30 ft)', 'price': '₹4500/day', 'emoji': '⛺', 'rating': '4.9', 'cat': 'Tent'},
    {'id': '10', 'name': 'Event & Stage Decorations', 'price': '₹8000/day', 'emoji': '💐', 'rating': '4.9', 'cat': 'Decor'},
    {'id': '11', 'name': 'Buffet Food Tables (Set of 10)', 'price': '₹1500/day', 'emoji': '🍽️', 'rating': '4.7', 'cat': 'Furniture'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selected == 'All'
        ? _items
        : _items.where((i) => i['cat'] == _selected).toList();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Equipment',
            subtitle: '${filtered.length} items available',
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            ),
          ),
          // Filter chips
          Container(
            color: AppColors.background,
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _selected == _filters[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = _filters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.primaryGradient : null,
                        color: active ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppColors.primary : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: active ? AppColors.bubbleShadow : null,
                      ),
                      child: Text(_filters[i],
                          style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  return GlassCard(
                    onTap: () => context.go('/equipment-detail/${item['id']}'),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image fills remaining vertical space
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: double.infinity,
                              child: Image.network(
                                _itemImageUrl(
                                  item['name'] as String? ?? '',
                                  item['cat'] as String? ?? '',
                                ),
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
                                              strokeWidth: 2,
                                              color: AppColors.primary),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(item['name'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: AppColors.textPrimary,
                                height: 1.2)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                (item['price'] as String? ?? '').replaceAll(r'$', '₹'),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11)),
                            ),
                            Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 12),
                              Text(' ${item['rating']}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary)),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

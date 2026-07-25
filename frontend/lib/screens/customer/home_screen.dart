import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    return StreamBuilder<UserModel?>(
      stream: service.userProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final user = snapshot.data;
        final isVendor = user?.role == 'Vendor';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F0E8),
          body: FadeTransition(
            opacity: _fadeAnim,
            child: isVendor
                ? _VendorDashboard(user: user)
                : _CustomerDashboard(user: user),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOMER DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _CustomerDashboard extends StatelessWidget {
  final UserModel? user;
  const _CustomerDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Sticky header ───────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          collapsedHeight: 70,
          pinned: true,
          backgroundColor: const Color(0xFF5C1A1A),
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _CustomerHeroBanner(user: user),
          ),
          actions: [
            IconButton(
              onPressed: () => context.go('/notifications'),
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/profile'),
              child: Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Search bar ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: GestureDetector(
              onTap: () => context.go('/categories'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Color(0xFF5C1A1A), size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Search vendors, equipment...',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Filter',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Category pills ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _CategoryPill(label: '🎪 All', selected: true),
                _CategoryPill(label: '⛺ Tent'),
                _CategoryPill(label: '💡 Lighting'),
                _CategoryPill(label: '🎤 Sound'),
                _CategoryPill(label: '🪑 Furniture'),
                _CategoryPill(label: '🎭 Staging'),
                _CategoryPill(label: '📽️ AV'),
              ],
            ),
          ),
        ),

        // ── Quick action tiles (2 big + 2 small) ────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _BigActionCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80',
                        label: 'Browse\nVendors',
                        icon: Icons.storefront_rounded,
                        color: const Color(0xFF5C1A1A),
                        onTap: () => context.go('/categories'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigActionCard(
                        imageUrl:
                            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&q=80',
                        label: 'My\nBookings',
                        icon: Icons.receipt_long_rounded,
                        color: const Color(0xFF1B5E20),
                        onTap: () => context.go('/booking-history'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.local_shipping_rounded,
                        label: 'Track Order',
                        color: const Color(0xFFE65100),
                        onTap: () => context.go('/order-tracking'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Cart',
                        color: const Color(0xFF6A1B9A),
                        onTap: () => context.go('/cart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chat',
                        color: const Color(0xFF01579B),
                        onTap: () => context.go('/chat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallActionCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Pick',
                        color: const Color(0xFF880E4F),
                        onTap: () => context.go('/ai-recommendations'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Promo banner ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _PromoBanner(
              imageUrl:
                  'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&q=80',
              title: 'Plan Your Dream Event',
              subtitle: 'Rent premium equipment from top-rated local vendors',
              buttonLabel: 'Explore Now',
              onTap: () => context.go('/categories'),
            ),
          ),
        ),

        // ── Featured categories ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Browse by Category'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _CategoryCard(
                        label: 'Tents',
                        emoji: '⛺',
                        imageUrl:
                            'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=300&q=80',
                      ),
                      _CategoryCard(
                        label: 'Lighting',
                        emoji: '💡',
                        imageUrl:
                            'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=300&q=80',
                      ),
                      _CategoryCard(
                        label: 'Sound',
                        emoji: '🎤',
                        imageUrl:
                            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=300&q=80',
                      ),
                      _CategoryCard(
                        label: 'Decor',
                        emoji: '💐',
                        imageUrl:
                            'https://images.unsplash.com/photo-1519741497674-611481863552?w=300&q=80',
                      ),
                      _CategoryCard(
                        label: 'Staging',
                        emoji: '🎭',
                        imageUrl:
                            'https://images.unsplash.com/photo-1505236858219-8359eb29e329?w=300&q=80',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Testimonial strip ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Why EventSphere?'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatChip(
                        icon: Icons.verified_rounded,
                        value: '500+',
                        label: 'Vendors'),
                    const SizedBox(width: 10),
                    _StatChip(
                        icon: Icons.event_rounded,
                        value: '10K+',
                        label: 'Events'),
                    const SizedBox(width: 10),
                    _StatChip(
                        icon: Icons.star_rounded,
                        value: '4.8★',
                        label: 'Rating'),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── AI Banner ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: GestureDetector(
              onTap: () => context.go('/ai-recommendations'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✨ Smart AI Planner',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                              'Get personalized equipment picks for your event',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Try Now',
                          style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VENDOR DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _VendorDashboard extends StatelessWidget {
  final UserModel? user;
  const _VendorDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();
    final uid = user?.id ?? '';

    return CustomScrollView(
      slivers: [
        // ── Vendor hero header ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5C1A1A), Color(0xFF8B2222)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white38, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'V',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good day, ${user?.name.split(' ')[0] ?? 'Vendor'}! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.shopName ?? 'Your Shop',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.go('/notifications'),
                          icon: const Badge(
                            label: Text('2'),
                            child: Icon(Icons.notifications_none_rounded,
                                color: Colors.white, size: 26),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: const Icon(Icons.settings_outlined,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // ── Live stats row ─────────────────────────────────────
                    StreamBuilder<List<OrderModel>>(
                      stream: service.getOrdersForVendor(uid),
                      builder: (context, snap) {
                        final orders = snap.data ?? [];
                        final pending = orders
                            .where((o) => o.status == 'Processing')
                            .length;
                        final active = orders
                            .where((o) =>
                                o.status == 'Confirmed' ||
                                o.status == 'Prepared' ||
                                o.status == 'Out for Delivery')
                            .length;
                        final completed = orders
                            .where((o) => o.status == 'Delivered' || o.status == 'Completed')
                            .length;
                        return Row(
                          children: [
                            _VendorStatCard(
                              value: '$pending',
                              label: 'Pending',
                              icon: Icons.hourglass_top_rounded,
                              color: const Color(0xFFFF9800),
                            ),
                            const SizedBox(width: 10),
                            _VendorStatCard(
                              value: '$active',
                              label: 'Active',
                              icon: Icons.local_shipping_rounded,
                              color: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 10),
                            _VendorStatCard(
                              value: '$completed',
                              label: 'Completed',
                              icon: Icons.done_all_rounded,
                              color: const Color(0xFF2196F3),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Vendor quick actions ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _VendorActionTile(
                      icon: Icons.inventory_2_rounded,
                      label: 'My Inventory',
                      sub: 'Add & manage items',
                      colors: const [Color(0xFF5C1A1A), Color(0xFF8B2222)],
                      onTap: () => context.go('/add-product'),
                    ),
                    _VendorActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Orders',
                      sub: 'View all requests',
                      colors: const [Color(0xFF1565C0), Color(0xFF0288D1)],
                      onTap: () => context.go('/vendor-orders'),
                    ),
                    _VendorActionTile(
                      icon: Icons.forum_rounded,
                      label: 'Customer Chat',
                      sub: 'Message customers',
                      colors: const [Color(0xFF2E7D32), Color(0xFF43A047)],
                      onTap: () => context.go('/chat'),
                    ),
                    _VendorActionTile(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      sub: 'Shop & account info',
                      colors: const [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Recent orders ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionTitle(title: 'Recent Orders'),
                    GestureDetector(
                      onTap: () => context.go('/vendor-orders'),
                      child: const Text('See all',
                          style: TextStyle(
                              color: Color(0xFF5C1A1A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<OrderModel>>(
                  stream: service.getOrdersForVendor(uid),
                  builder: (context, snap) {
                    final orders = snap.data ?? [];
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('No orders yet',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      );
                    }
                    final recent = orders.take(3).toList();
                    return Column(
                      children: recent
                          .map((o) => _RecentOrderTile(order: o))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Tip card ─────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded,
                      color: Color(0xFFF57F17), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡 Pro Tip',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF57F17))),
                        SizedBox(height: 4),
                        Text(
                            'Add high-quality photos to your items to get 3x more bookings.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF5D4037))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _CustomerHeroBanner extends StatelessWidget {
  final UserModel? user;
  const _CustomerHeroBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.network(
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=900&q=80',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF5C1A1A)),
        ),
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xDD5C1A1A), Color(0x885C1A1A)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  user != null
                      ? 'Hello, ${user!.name.split(' ')[0]}! 👋'
                      : 'Welcome to EventSphere',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find top vendors & rent premium event equipment',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D1B1B),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final bool selected;
  const _CategoryPill({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF5C1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: selected
                ? const Color(0xFF5C1A1A)
                : Colors.grey.shade300),
        boxShadow: selected
            ? [
                BoxShadow(
                    color: const Color(0xFF5C1A1A).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade700,
          fontWeight:
              selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final String imageUrl;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BigActionCard({
    required this.imageUrl,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: color.withValues(alpha: 0.3))),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: color.withValues(alpha: 0.25), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _PromoBanner({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFF5C1A1A))),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xCC000000), Color(0x44000000)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C1A1A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(buttonLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final String emoji;
  final String imageUrl;

  const _CategoryCard({
    required this.label,
    required this.emoji,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF5C1A1A))),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF5C1A1A), size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2D1B1B))),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// Vendor-specific widgets

class _VendorStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _VendorStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _VendorActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final List<Color> colors;
  final VoidCallback onTap;

  const _VendorActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: colors[0].withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon,
                  size: 70,
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'Processing': return const Color(0xFFFF9800);
      case 'Confirmed': return const Color(0xFF2196F3);
      case 'Out for Delivery': return const Color(0xFF9C27B0);
      case 'Delivered': return const Color(0xFF4CAF50);
      case 'Rejected': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D1B1B))),
                Text(
                  order.items.map((i) => i.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(order.status,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

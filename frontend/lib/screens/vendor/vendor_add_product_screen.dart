import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';

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

class VendorAddProductScreen extends StatefulWidget {
  const VendorAddProductScreen({super.key});

  @override
  State<VendorAddProductScreen> createState() => _VendorAddProductScreenState();
}

class _VendorAddProductScreenState extends State<VendorAddProductScreen> {
  String _selectedCategoryFilter = 'All';
  final Set<String> _deletedSampleIds = {};

  void _openAddSheet([Map<String, dynamic>? initialItem]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.98,
        expand: false,
        builder: (_, scrollController) =>
            _AddItemSheet(scrollController: scrollController, initialItem: initialItem),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1938),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(item['emoji'] as String? ?? '🗑️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete Item?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${item['name']}" from your inventory?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final itemId = item['id'] as String? ?? '';
              if (itemId.startsWith('sample_')) {
                setState(() {
                  _deletedSampleIds.add(itemId);
                });
              } else if (itemId.isNotEmpty) {
                final service = FirebaseService();
                await service.deleteEquipment(itemId);
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Icon(Icons.delete_outline_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Item removed from inventory',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = FirebaseService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            const GradientHeader(
              title: 'My Inventory',
              subtitle: 'Manage your listed equipment',
            ),

            // ── Items from Firestore + Default Inventory ─────────────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.getEquipmentByVendor(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  final firestoreItems = snap.data ?? [];

                  // Default catalog items
                  final sampleItems = [
                    {
                      'id': 'sample_tent_1',
                      'name': 'Shamiyana Marquee Tent (30x30 ft)',
                      'price': '₹4,500/day',
                      'priceAmount': 4500.0,
                      'category': 'Tent',
                      'emoji': '⛺',
                      'description': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
                      'quantity': 2,
                      'quality': 'Brand New',
                    },
                    {
                      'id': 'sample_decor_1',
                      'name': 'Stage & Floral Decorations',
                      'price': '₹8,000/day',
                      'priceAmount': 8000.0,
                      'category': 'Decor',
                      'emoji': '💐',
                      'description': 'Complete wedding & event stage floral decoration with custom theme backdrop and entry arch.',
                      'quantity': 1,
                      'quality': 'Brand New',
                    },
                    {
                      'id': 'sample_food_1',
                      'name': 'Buffet Food Tables (Set of 10)',
                      'price': '₹1,500/day',
                      'priceAmount': 1500.0,
                      'category': 'Furniture',
                      'emoji': '🍽️',
                      'description': '10 heavy-duty stainless steel buffet food tables with elegant satin cloth coverings.',
                      'quantity': 10,
                      'quality': 'Like New',
                    },
                  ];

                  final existingNames = firestoreItems
                      .map((e) => (e['name'] as String? ?? '').toLowerCase())
                      .toSet();
                  final allItems = [
                    ...firestoreItems,
                    ...sampleItems.where((s) =>
                        !_deletedSampleIds.contains(s['id']) &&
                        !existingNames.contains((s['name'] as String).toLowerCase())),
                  ];

                  if (allItems.isEmpty) {
                    return _EmptyInventory(onAdd: () => _openAddSheet());
                  }

                  // Build category list
                  final cats = <String>{'All'};
                  for (final item in allItems) {
                    final c = item['category'] as String? ?? '';
                    if (c.isNotEmpty) cats.add(c);
                  }
                  final catList = cats.toList()..sort();

                  final displayItems = _selectedCategoryFilter == 'All'
                      ? allItems
                      : allItems
                          .where((i) =>
                              (i['category'] as String? ?? '') ==
                              _selectedCategoryFilter)
                          .toList();

                  return Column(
                    children: [
                      // Category Filter bar
                      if (catList.length > 2)
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: catList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final cat = catList[i];
                              final sel = cat == _selectedCategoryFilter;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedCategoryFilter = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient:
                                        sel ? AppColors.accentGradient : null,
                                    color: sel
                                        ? null
                                        : Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: sel
                                          ? Colors.transparent
                                          : Colors.white.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          sel ? FontWeight.bold : FontWeight.normal,
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

                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: displayItems.length,
                          itemBuilder: (_, i) {
                            final item = displayItems[i];
                            return _VendorItemCard(
                              item: item,
                              onEdit: () => _openAddSheet(item),
                              onDelete: () => _confirmDelete(item),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Floating Add Button ──────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GestureDetector(
          onTap: () => _openAddSheet(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Vendor Item Card (inventory view) ───────────────────────────────────────
class _VendorItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VendorItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priceAmount = item['priceAmount'];
    final priceStr = item['price'] as String? ?? '';
    String displayPrice;
    if (priceAmount != null) {
      displayPrice = '₹${(priceAmount as num).toStringAsFixed(0)}/day';
    } else if (priceStr.isNotEmpty) {
      displayPrice = priceStr.replaceAll('\$', '₹');
    } else {
      displayPrice = 'Price N/A';
    }

    final qty = item['quantity'] ?? 1;

    return GestureDetector(
      onTap: onEdit,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-world photo with Edit & Delete action buttons
            Expanded(
              child: Stack(
                children: [
                  // Full photo background
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _itemImageUrl(
                          item['name'] as String? ?? '',
                          item['category'] as String? ?? '',
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: AppColors.textSecondary, size: 28),
                          ),
                        ),
                        loadingBuilder: (_, child, prog) => prog == null
                            ? child
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F0E8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.accent),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Dark bottom gradient
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Edit & Delete buttons (top-right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Category badge & Quantity badge
            Row(
              children: [
                if ((item['category'] as String? ?? '').isNotEmpty)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['category'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Qty: $qty',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Name
            Text(
              item['name'] as String? ?? 'Item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Price
            Text(
              displayPrice,
              style: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Inventory ──────────────────────────────────────────────────────────
class _EmptyInventory extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyInventory({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.accent, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Items Listed Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the button below to add your\nfirst equipment item.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Add Your First Item',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Item Bottom Sheet ───────────────────────────────────────────────
class _AddItemSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Map<String, dynamic>? initialItem;
  const _AddItemSheet({
    required this.scrollController,
    this.initialItem,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  int _quantity = 1;
  String _selectedQuality = 'Brand New';
  String _selectedCategory = 'Sound';
  String _selectedEmoji = '🎤';
  bool _isLoading = false;

  static const _categories = [
    'Tent', 'Decor', 'Furniture', 'Catering', 'Sound', 'Lighting', 'Staging', 'AV', 'Other'
  ];

  static const _emojiOptions = [
    '⛺', '💐', '🍽️', '🎪', '🎤', '🎙️', '🎛️', '💡', '🔦', '🎭',
    '📽️', '🎊', '🎉', '🪑', '🍷', '🍲', '🌿',
    '🎸', '🥁', '🎷', '🎺', '🎻', '🔊', '📸', '🎬', '🎥',
  ];

  static const _quickPresets = [
    {
      'name': 'Shamiyana Tent (30x30 ft)',
      'price': '4500',
      'category': 'Tent',
      'emoji': '⛺',
      'desc': 'Waterproof traditional Shamiyana marquee tent with decorative side curtains and ceiling drape.',
      'quantity': 2,
      'quality': 'Brand New',
    },
    {
      'name': 'Event & Stage Decorations',
      'price': '8000',
      'category': 'Decor',
      'emoji': '💐',
      'desc': 'Complete wedding and event stage floral decoration with custom theme backdrop and entry arch.',
      'quantity': 1,
      'quality': 'Brand New',
    },
    {
      'name': 'Buffet Food Tables (Set of 10)',
      'price': '1500',
      'category': 'Furniture',
      'emoji': '🍽️',
      'desc': '10 heavy-duty stainless steel buffet food tables with elegant satin cloth coverings.',
      'quantity': 10,
      'quality': 'Like New',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameCtrl.text = item['name'] as String? ?? '';

      final pAmt = item['priceAmount'];
      if (pAmt != null) {
        _priceCtrl.text = (pAmt as num).toStringAsFixed(0);
      } else {
        final pStr = (item['price'] as String? ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
        _priceCtrl.text = pStr;
      }

      _descCtrl.text = item['description'] as String? ?? '';
      if (item.containsKey('quantity')) {
        final q = item['quantity'];
        _quantity = q is int ? q : (int.tryParse('$q') ?? 1);
      }
      if (item.containsKey('quality')) {
        _selectedQuality = item['quality'] as String? ?? 'Brand New';
      }
      if (item.containsKey('category')) {
        _selectedCategory = item['category'] as String? ?? 'Sound';
      }
      if (item.containsKey('emoji')) {
        _selectedEmoji = item['emoji'] as String? ?? '🎤';
      }
    }
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _nameCtrl.text = preset['name'] as String? ?? '';
      _priceCtrl.text = preset['price'] as String? ?? '';
      _selectedCategory = preset['category'] as String? ?? 'Sound';
      _selectedEmoji = preset['emoji'] as String? ?? '🎤';
      _descCtrl.text = preset['desc'] as String? ?? '';
      if (preset.containsKey('quantity')) _quantity = preset['quantity'] as int;
      if (preset.containsKey('quality')) _selectedQuality = preset['quality'] as String;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final service = FirebaseService();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final cleanPriceStr = _priceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final priceNum = double.tryParse(cleanPriceStr) ?? 0.0;

      final data = {
        'name': _nameCtrl.text.trim(),
        'price': '₹$cleanPriceStr/day',
        'priceAmount': priceNum,
        'quantity': _quantity,
        'quality': _selectedQuality,
        'category': _selectedCategory,
        'emoji': _selectedEmoji,
        'description': _descCtrl.text.trim(),
        'vendorId': uid,
        'rating': widget.initialItem?['rating'] ?? '4.5',
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (widget.initialItem == null) {
        data['createdAt'] = DateTime.now().toIso8601String();
        await service.addEquipment(data);
      } else {
        final itemId = widget.initialItem!['id'] as String? ?? '';
        if (itemId.isNotEmpty && !itemId.startsWith('sample_')) {
          await service.updateEquipment(itemId, data);
        } else {
          // If editing a sample item, add it as a new Firestore item
          data['createdAt'] = DateTime.now().toIso8601String();
          await service.addEquipment(data);
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // close sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              widget.initialItem == null ? 'Item added to inventory!' : 'Item updated!',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFEF4444),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialItem != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11102A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Sheet title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Inventory Item' : 'Add New Item',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0x12FFFFFF)),

          // Scrollable form — uses the DraggableScrollableSheet controller
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick Presets ─────────────────────────────────────
                    _label('Quick Presets'),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickPresets.map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _applyPreset(p),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p['emoji'] as String, style: const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      p['name'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Emoji picker ───────────────────────────────────────
                    _label('Choose Icon'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _emojiOptions.map((e) {
                        final sel = e == _selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedEmoji = e),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6366F1)
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: sel
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(e,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // ── Name ───────────────────────────────────────────────
                    _label('Item Name'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _nameCtrl,
                      hint: 'e.g. Professional PA System 5000W',
                      prefix: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.accent, size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter an item name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── Price ──────────────────────────────────────────────
                    _label('Price Per Day (₹)'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _priceCtrl,
                      hint: 'e.g. 1500',
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.currency_rupee_rounded,
                          color: Color(0xFF10B981), size: 20),
                      suffix: const Text('/day',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a price';
                        }
                        final clean = v.replaceAll(RegExp(r'[^0-9.]'), '');
                        if (double.tryParse(clean) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Quantity (Stock) ───────────────────────────────────
                    _label('Quantity Available'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Decrement button (-)
                        GestureDetector(
                          onTap: () {
                            if (_quantity > 1) setState(() => _quantity--);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: const Icon(Icons.remove_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Display Quantity
                        Container(
                          width: 56,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Increment button (+)
                        GestureDetector(
                          onTap: () => setState(() => _quantity++),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Quick Quantity Presets
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [1, 2, 5, 10, 20, 50].map((q) {
                                final sel = _quantity == q;
                                return GestureDetector(
                                  onTap: () => setState(() => _quantity = q),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.accent
                                          : Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.accent
                                            : Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Text(
                                      '$q',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: sel
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: sel ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Quality & Condition ───────────────────────────────
                    _label('Quality & Condition'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': 'Brand New', 'icon': '🌟'},
                        {'label': 'Like New', 'icon': '⭐'},
                        {'label': 'Good Condition', 'icon': '👍'},
                        {'label': 'Fair / Standard', 'icon': '🔧'},
                      ].map((item) {
                        final label = item['label']!;
                        final icon = item['icon']!;
                        final sel = _selectedQuality == label;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedQuality = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : Colors.white.withValues(alpha: 0.07),
                              border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        sel ? FontWeight.bold : FontWeight.w400,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Category ───────────────────────────────────────────
                    _label('Category'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: sel
                                  ? const LinearGradient(colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ])
                                  : null,
                              color: sel
                                  ? null
                                  : Colors.white.withValues(alpha: 0.07),
                              border: Border.all(
                                color: sel
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // ── Description ────────────────────────────────────────
                    Row(children: [
                      _label('Description'),
                      const SizedBox(width: 6),
                      Text('(optional)',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6))),
                    ]),
                    const SizedBox(height: 8),
                    _field(
                      controller: _descCtrl,
                      hint: 'Specs, condition, accessories...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // ── Live Preview ───────────────────────────────────────
                    const Text(
                      'Live Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PreviewCard(
                      emoji: _selectedEmoji,
                      name: _nameCtrl.text,
                      category: _selectedCategory,
                      price: _priceCtrl.text,
                      quantity: _quantity,
                      quality: _selectedQuality,
                    ),
                    const SizedBox(height: 24),

                    // ── Submit Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : AppColors.accentGradient,
                            color:
                                _isLoading ? Colors.white10 : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isEditing ? 'Save Changes' : 'Add to Inventory',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}), // live preview update
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        prefixIcon: prefix,
        suffix: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Live Preview Card ────────────────────────────────────────────────────────
class _PreviewCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String category;
  final String price;
  final int quantity;
  final String quality;

  const _PreviewCard({
    required this.emoji,
    required this.name,
    required this.category,
    required this.price,
    this.quantity = 1,
    this.quality = 'Brand New',
  });

  @override
  Widget build(BuildContext context) {
    final cleanPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
    final displayPrice =
        cleanPrice.isEmpty ? '₹0/day' : '₹$cleanPrice/day';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Emoji box
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accent.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.15),
              ]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Item Name' : name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: name.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // Price in INR
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),

                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Quality badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quality,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

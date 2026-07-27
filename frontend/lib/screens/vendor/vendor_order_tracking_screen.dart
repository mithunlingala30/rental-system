import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../models/order_model.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Deterministic order code from Firestore doc ID ───────────────────────────
/// Produces a code like  AL·KQNX·5283  from any Firestore document ID.
/// The 4 letters + 4 digits are seeded by the doc-id's hashCode so the
/// same order always gets the same code.
String _orderCodeFromId(String docId) {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const digits  = '0123456789';
  final rng = math.Random(docId.hashCode.abs());
  final alpha = List.generate(4, (_) => letters[rng.nextInt(letters.length)]).join();
  final nums  = List.generate(4, (_) => digits[rng.nextInt(digits.length)]).join();
  return 'AL$alpha$nums';
}

// ─── Tracking steps shared between vendor & customer views ────────────────────
const _trackingLabels = [
  'Order Placed',
  'Order Confirmed',
  'Equipment Prepared',
  'Out for Delivery',
  'Delivered',
];

const _trackingIcons = [
  Icons.shopping_bag_outlined,
  Icons.check_circle_outline_rounded,
  Icons.inventory_2_outlined,
  Icons.local_shipping_outlined,
  Icons.home_rounded,
];

// ─── Vendor Order Tracking Screen ─────────────────────────────────────────────
class VendorOrderTrackingScreen extends StatefulWidget {
  const VendorOrderTrackingScreen({super.key});

  @override
  State<VendorOrderTrackingScreen> createState() =>
      _VendorOrderTrackingScreenState();
}

class _VendorOrderTrackingScreenState
    extends State<VendorOrderTrackingScreen> {
  final _service = FirebaseService();
  String _filterStatus = 'All';
  DateTime? _selectedDate = DateTime.now();

  static const _filters = ['All', 'Pending', 'Confirmed', 'Delivered', 'Rejected'];

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            const GradientHeader(
              title: 'Rental Requests',
              subtitle: 'Manage customer orders',
            ),

            // ── High-Visibility Date Selector Banner ─────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Viewing All Booking Dates'
                              : _isToday(_selectedDate!)
                                  ? 'Showing Today\'s Bookings (${_formatDate(_selectedDate!)})'
                                  : 'Showing Bookings for ${_formatDate(_selectedDate!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // "Today" Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDate = DateTime.now()),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: (_selectedDate != null && _isToday(_selectedDate!))
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: (_selectedDate != null && _isToday(_selectedDate!))
                                  ? AppColors.bubbleShadow
                                  : null,
                            ),
                            child: Text(
                              '📅 Today',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: (_selectedDate != null && _isToday(_selectedDate!))
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // "Pick Date" Button
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: (_selectedDate != null && !_isToday(_selectedDate!))
                                  ? AppColors.primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: (_selectedDate != null && !_isToday(_selectedDate!))
                                  ? AppColors.bubbleShadow
                                  : null,
                            ),
                            child: Text(
                              _selectedDate != null && !_isToday(_selectedDate!)
                                  ? _formatDate(_selectedDate!)
                                  : '🗓️ Select Date',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: (_selectedDate != null && !_isToday(_selectedDate!))
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // "All Dates" Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedDate = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _selectedDate == null
                                  ? AppColors.accent
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'All Dates',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedDate == null
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Status Filter Chips ──────────────────────────────────────────
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = f == _filterStatus;
                  return GestureDetector(
                    onTap: () => setState(() => _filterStatus = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.accentGradient : null,
                        color: selected
                            ? null
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // ── Orders List ───────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: _service.getOrdersForVendor(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                    );
                  }

                  final all = snapshot.data ?? [];
                  var orders = _filterStatus == 'All'
                      ? all
                      : all.where((o) {
                          if (_filterStatus == 'Pending') {
                            return o.status == 'Processing';
                          }
                          return o.status == _filterStatus;
                        }).toList();

                  if (_selectedDate != null) {
                    orders = orders.where((o) =>
                        o.createdAt.year == _selectedDate!.year &&
                        o.createdAt.month == _selectedDate!.month &&
                        o.createdAt.day == _selectedDate!.day).toList();
                  }

                  if (orders.isEmpty) {
                    return _EmptyState(
                      filter: _filterStatus,
                      selectedDate: _selectedDate,
                      onClearDate: () => setState(() => _selectedDate = null),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      service: _service,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  final DateTime? selectedDate;
  final VoidCallback? onClearDate;

  const _EmptyState({
    required this.filter,
    this.selectedDate,
    this.onClearDate,
  });

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final dateText = selectedDate != null
        ? (_isToday(selectedDate!)
            ? 'Today (${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year})'
            : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}')
        : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.accent, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              dateText != null
                  ? 'No $filter bookings on $dateText'
                  : (filter == 'All' ? 'No bookings yet' : 'No $filter bookings'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dateText != null
                  ? 'Bookings placed by customers for $dateText will appear here.'
                  : 'Bookings from customers will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            if (selectedDate != null && onClearDate != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onClearDate,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('View All Dates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final FirebaseService service;

  const _OrderCard({required this.order, required this.service});

  Color get _statusColor {
    return switch (order.status) {
      'Confirmed' => const Color(0xFF10B981),
      'Delivered' => const Color(0xFF3B82F6),
      'Rejected' => const Color(0xFFEF4444),
      'Out for Delivery' => const Color(0xFFF59E0B),
      'Prepared' => const Color(0xFF8B5CF6),
      'Return Requested' => const Color(0xFFEC4899),
      'Returned' => const Color(0xFF6366F1),
      'Completed' => const Color(0xFF10B981),
      _ => const Color(0xFFF59E0B), // Processing / Pending
    };
  }

  bool get _isPending => order.status == 'Processing';
  bool get _isRejected => order.status == 'Rejected';
  bool get _isDelivered => order.status == 'Delivered';
  bool get _isReturnRequested => order.status == 'Return Requested';
  bool get _isReturned => order.status == 'Returned';
  bool get _isCompleted => order.status == 'Completed';
  bool get _canUpdateTracking =>
      !_isPending && !_isRejected && !_isDelivered &&
      !_isReturnRequested && !_isReturned && !_isCompleted;


  @override
  Widget build(BuildContext context) {
    final orderCode = _orderCodeFromId(order.id);
    final alphaCode = orderCode.substring(0, 6); // "ALXXXX"
    final numCode   = orderCode.substring(6);    // "NNNN"

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top Header bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _statusColor.withValues(alpha: 0.12),
                    _statusColor.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: _statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName.isEmpty ? 'Customer' : order.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (order.phone.isNotEmpty)
                          Text(order.phone,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        if (order.address.isNotEmpty)
                          Text(order.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${order.createdAt.day.toString().padLeft(2, '0')}/'
                                '${order.createdAt.month.toString().padLeft(2, '0')}/'
                                '${order.createdAt.year}  '
                                '${order.createdAt.hour.toString().padLeft(2, '0')}:'
                                '${order.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isPending ? 'PLACED' : order.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Order Code ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                border: Border.symmetric(
                  horizontal: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ORDER CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: orderCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied $orderCode',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: alphaCode,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 4,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              TextSpan(
                                text: numCode,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 4,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Order Summary ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items
                  if (order.items.isNotEmpty)
                    Text(
                      order.items
                              .take(2)
                              .map((i) => '${i.name} ×${i.quantity}')
                              .join(', ') +
                          (order.items.length > 2
                              ? ' +${order.items.length - 2} more'
                              : ''),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.currency_rupee_rounded,
                        label: '₹${order.total.toStringAsFixed(0)}',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: order.city.isEmpty ? 'N/A' : order.city,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── Big Call & Chat Buttons ──────────────────────────────────────
            if (order.phone.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Call button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final uri =
                              Uri(scheme: 'tel', path: order.phone);
                          try {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } catch (_) {
                            // Phone app unavailable
                          }
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chat button
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          // WhatsApp deep link
                          final phone =
                              order.phone.replaceAll(RegExp(r'[^\d]'), '');
                          final uri = Uri.parse(
                              'https://wa.me/$phone?text=Hi%20${Uri.encodeComponent(order.customerName)}%2C%20regarding%20order%20$orderCode');
                          try {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } catch (_) {
                            // WhatsApp not installed
                          }
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_rounded,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Track Location button ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: GestureDetector(
                  onTap: () async {
                    final parts = [
                      if (order.address.isNotEmpty) order.address,
                      if (order.city.isNotEmpty) order.city,
                      if (order.zip.isNotEmpty) order.zip,
                    ];
                    final query = Uri.encodeComponent(parts.join(', '));

                    // Try native Google Maps app first
                    final mapsAppUri = Uri.parse('geo:0,0?q=$query');
                    // Browser fallback
                    final mapsBrowserUri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$query');

                    try {
                      final launched = await launchUrl(
                        mapsAppUri,
                        mode: LaunchMode.externalApplication,
                      );
                      if (!launched) {
                        await launchUrl(
                          mapsBrowserUri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (_) {
                      await launchUrl(
                        mapsBrowserUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFE11D48), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.near_me_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Track Delivery Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (order.address.isNotEmpty ||
                                  order.city.isNotEmpty)
                                Text(
                                  [
                                    if (order.address.isNotEmpty)
                                      order.address,
                                    if (order.city.isNotEmpty) order.city,
                                  ].join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.82),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'Open',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ],

            // ── Accept / Reject / Tracking Actions ──────────────────────────
            if (_isPending) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () => _confirmReject(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _ActionButton(
                        label: 'Accept Order',
                        icon: Icons.check_rounded,
                        color: const Color(0xFF10B981),
                        filled: true,
                        onTap: () => _accept(context),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_canUpdateTracking) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: _TrackingUpdater(order: order, service: service),
              ),
              _DeliveryPinCard(
                order: order,
                service: service,
                correctPin: numCode,
              ),
            ] else if (_isDelivered) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered on ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ] else if (_isReturnRequested) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await service.confirmReturn(order.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Items Return Confirmed!'),
                            backgroundColor: Color(0xFF6366F1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.inventory_rounded, size: 20),
                    label: const Text('Confirm Items Returned',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ),
            ] else if (_isReturned) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Color(0xFF6366F1), size: 18),
                      SizedBox(width: 8),
                      Text('Items Returned • Awaiting Customer Rating',
                          style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ] else if (_isCompleted) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Completed • Rating: ${order.rating > 0 ? "${order.rating.toStringAsFixed(1)} ★" : "No rating"}',
                      style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ] else if (_isRejected) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Order rejected',
                        style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    try {
      await service.acceptOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack('Order accepted! Update tracking below.', 0xFF10B981),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(_snack('Error: $e', 0xFFEF4444));
      }
    }
  }

  Future<void> _confirmReject(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF11102A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Order?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to reject this booking from ${order.customerName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.rejectOrder(order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('Order rejected.', 0xFFEF4444));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('Error: $e', 0xFFEF4444));
        }
      }
    }
  }

  SnackBar _snack(String msg, int colorHex) => SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Color(colorHex),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

// ─── Tracking Updater ─────────────────────────────────────────────────────────
class _TrackingUpdater extends StatefulWidget {
  final OrderModel order;
  final FirebaseService service;

  const _TrackingUpdater({required this.order, required this.service});

  @override
  State<_TrackingUpdater> createState() => _TrackingUpdaterState();
}

class _TrackingUpdaterState extends State<_TrackingUpdater> {
  late int _step;
  late TextEditingController _noteCtrl;
  bool _loading = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _step = widget.order.trackingStep.clamp(1, 4);
    _noteCtrl = TextEditingController(text: widget.order.trackingNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini step progress bar
        _MiniProgress(current: widget.order.trackingStep),
        const SizedBox(height: 10),

        // Toggle update panel
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.edit_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                _expanded ? 'Close update panel' : 'Update tracking',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        if (_expanded) ...[
          const SizedBox(height: 14),

          // Step selector
          const Text(
            'Set current stage',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (i) {
              final stepIdx = i + 1; // 1..4
              final selected = stepIdx == _step;
              return GestureDetector(
                onTap: () => setState(() => _step = stepIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.accentGradient : null,
                    color: selected
                        ? null
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_trackingIcons[stepIdx],
                          size: 14,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _trackingLabels[stepIdx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Note field
          TextFormField(
            controller: _noteCtrl,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            maxLines: 2,
            decoration: InputDecoration(
              hintText:
                  'Optional note (e.g. "Driver on the way, ETA 30 min")',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: _loading
                      ? null
                      : AppColors.accentGradient,
                  color: _loading ? Colors.white10 : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  padding:
                      const EdgeInsets.symmetric(vertical: 13),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Tracking Update',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await widget.service
          .updateTracking(widget.order.id, _step, _noteCtrl.text.trim());
      if (mounted) {
        setState(() => _expanded = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tracking updated!',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Mini progress bar ────────────────────────────────────────────────────────
class _MiniProgress extends StatelessWidget {
  final int current; // 0-4
  const _MiniProgress({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final done = i <= current;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      done ? AppColors.accent : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              if (i < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: done && i < current
                        ? AppColors.accent
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Small helper widgets ─────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: filled ? 0.4 : 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delivery PIN Confirmation Card Widget ────────────────────────────────────
class _DeliveryPinCard extends StatefulWidget {
  final OrderModel order;
  final FirebaseService service;
  final String correctPin;

  const _DeliveryPinCard({
    required this.order,
    required this.service,
    required this.correctPin,
  });

  @override
  State<_DeliveryPinCard> createState() => _DeliveryPinCardState();
}

class _DeliveryPinCardState extends State<_DeliveryPinCard> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final inputPin = _pinCtrl.text.trim();
    if (inputPin.length < 4) {
      setState(() => _error = 'Please enter all 4 digits');
      return;
    }

    if (inputPin == widget.correctPin) {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        await widget.service.markDelivered(widget.order.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Delivery Confirmed! Order marked as Delivered.'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Error: $e';
          });
        }
      }
    } else {
      setState(() => _error = 'Incorrect PIN! Ask customer for the last 4 digits of order code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🔑 ', style: TextStyle(fontSize: 16)),
              Text(
                'DELIVERY PIN CONFIRMATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF78350F),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ask the customer for the last 4 digits of their order code. Correct PIN auto-completes the order.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF92400E),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _error != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 16,
                color: Color(0xFF1E293B),
              ),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: '- - - -',
                hintStyle: TextStyle(
                  letterSpacing: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              onChanged: (val) {
                if (val.length == 4) {
                  _verifyPin();
                }
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _loading ? null : _verifyPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B1D2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'CONFIRM DELIVERY ✓',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


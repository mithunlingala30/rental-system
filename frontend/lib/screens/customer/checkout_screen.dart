import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../services/cart_service.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';

// -----------------------------------------------------------------------------
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _instructionsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _eventNameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService();
    final cartItems = cart.items;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Checkout',
            subtitle: 'Finalize your equipment rental',
            leading: IconButton(
              onPressed: () => context.go('/cart'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Delivery address details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delivery Address',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Full Name',
                            hint: 'John Doe',
                            controller: _nameController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Phone',
                            hint: '9876543210',
                            keyboardType: TextInputType.phone,
                            controller: _phoneController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Address',
                            hint: '123 Event Avenue, Suite 4',
                            controller: _addressController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: AppInput(
                                label: 'City',
                                hint: 'New York',
                                controller: _cityController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppInput(
                                label: 'ZIP',
                                hint: '10001',
                                controller: _zipController,
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event info
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Event Details',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Event Name',
                            hint: 'My Wedding Reception',
                            controller: _eventNameController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter event name' : null,
                          ),
                          const SizedBox(height: 12),
                          AppInput(
                            label: 'Special Instructions',
                            hint: 'Any setup notes...',
                            maxLines: 3,
                            controller: _instructionsController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order summary
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          if (cartItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text('No items in cart', style: TextStyle(color: AppColors.textSecondary)),
                            )
                          else
                            ...cartItems.map((item) => _Row(
                                  label: '${item.name} \u00D7 ${item.qty} (${item.days} day${item.days == 1 ? '' : 's'})',
                                  value: '\u20B9${(item.price * item.qty * item.days).toStringAsFixed(0)}',
                                )),
                          _Row(label: 'Tax (10%)', value: '\u20B9${cart.tax.toStringAsFixed(0)}'),
                          const Divider(color: Color(0x1AFFFFFF)),
                          _Row(label: 'Total', value: '\u20B9${cart.total.toStringAsFixed(0)}', bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Proceed button
                    AppButton(
                      text: 'Proceed Request',
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your cart is empty.')),
                          );
                          return;
                        }

                        // Show loader dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                        );

                        try {
                          final orderItems = cartItems
                              .map((item) => OrderItem(
                                    name: item.name,
                                    quantity: item.qty,
                                    price: item.price,
                                    days: item.days,
                                  ))
                              .toList();

                          final firstVendorId = cartItems.isNotEmpty ? cartItems.first.vendorId : '';

                          final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                          final order = OrderModel(
                            id: '',
                            customerId: currentUid,
                            customerName: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            address: _addressController.text.trim(),
                            city: _cityController.text.trim(),
                            zip: _zipController.text.trim(),
                            eventName: _eventNameController.text.trim(),
                            specialInstructions: _instructionsController.text.trim(),
                            items: orderItems,
                            total: cart.total,
                            status: 'Processing',
                            createdAt: DateTime.now(),
                            vendorId: firstVendorId,
                          );

                          final service = FirebaseService();
                          final orderId = await service.placeOrder(order);

                          final savedOrder = OrderModel(
                            id: orderId,
                            customerId: currentUid,
                            customerName: order.customerName,
                            phone: order.phone,
                            address: order.address,
                            city: order.city,
                            zip: order.zip,
                            eventName: order.eventName,
                            specialInstructions: order.specialInstructions,
                            items: order.items,
                            total: order.total,
                            status: order.status,
                            createdAt: order.createdAt,
                            vendorId: order.vendorId,
                          );

                          // Clear local shopping cart
                          CartService().clear();

                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading
                            context.go('/order-confirmation', extra: savedOrder);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Dismiss loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error placing request: $e')),
                            );
                          }
                        }
                      },
                      fullWidth: true,
                      size: ButtonSize.lg,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        fontSize: bold ? 15 : 14,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: bold ? AppColors.textPrimary : AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: s, maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: s),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
class PaymentScreen extends StatefulWidget {
  final OrderModel? order;
  const PaymentScreen({super.key, this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'card';

  @override
  Widget build(BuildContext context) {
    final displayTotal = widget.order?.total.toStringAsFixed(0) ?? "0";

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Payment',
            subtitle: 'Total: \u20B9$displayTotal',
            leading: IconButton(
              onPressed: () => context.go('/checkout'),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // Method selector
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Method',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 16),
                        ...[
                          {
                            'value': 'card',
                            'icon': Icons.credit_card_rounded,
                            'label': 'Credit / Debit Card'
                          },
                          {
                            'value': 'paypal',
                            'icon': Icons.account_balance_wallet_rounded,
                            'label': 'PayPal'
                          },
                          {
                            'value': 'bank',
                            'icon': Icons.account_balance_rounded,
                            'label': 'Bank Transfer'
                          },
                        ].map((m) {
                          final sel = _method == m['value'];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _method = m['value'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.accent.withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: sel
                                          ? AppColors.accent
                                          : Colors.white.withValues(alpha: 0.08),
                                      width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(m['icon'] as IconData,
                                        color: sel
                                            ? AppColors.accent
                                            : AppColors.textSecondary,
                                        size: 22),
                                    const SizedBox(width: 14),
                                    Text(m['label'] as String,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: sel
                                                ? AppColors.accent
                                                : AppColors.textPrimary)),
                                    const Spacer(),
                                    if (sel)
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.accent, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_method == 'card')
                    const GlassCard(
                      child: Column(
                        children: [
                          AppInput(
                              label: 'Card Number',
                              hint: '1234 5678 9012 3456',
                              prefix: Icon(Icons.credit_card_rounded, size: 20),
                              keyboardType: TextInputType.number),
                          SizedBox(height: 16),
                          AppInput(
                              label: 'Card Holder',
                              prefix: Icon(Icons.person_outline_rounded, size: 20),
                              hint: 'JOHN DOE'),
                          SizedBox(height: 16),
                          Row(children: [
                            Expanded(
                                child:
                                    AppInput(label: 'Expiry', hint: 'MM/YY')),
                            SizedBox(width: 16),
                            Expanded(
                                child: AppInput(
                                    label: 'CVV',
                                    hint: '***',
                                    obscureText: true)),
                          ]),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Pay \u20B9$displayTotal',
                    variant: ButtonVariant.accent,
                    onPressed: () async {
                      if (widget.order != null) {
                        final service = FirebaseService();
                        final orderId = await service.placeOrder(widget.order!);
                        final savedOrder = OrderModel(
                          id: orderId,
                          customerName: widget.order!.customerName,
                          phone: widget.order!.phone,
                          address: widget.order!.address,
                          city: widget.order!.city,
                          zip: widget.order!.zip,
                          eventName: widget.order!.eventName,
                          specialInstructions: widget.order!.specialInstructions,
                          items: widget.order!.items,
                          total: widget.order!.total,
                          status: widget.order!.status,
                          createdAt: widget.order!.createdAt,
                          vendorId: widget.order!.vendorId,
                        );
                        // Clear local shopping cart
                        CartService().clear();
                        if (context.mounted) {
                          context.go('/order-confirmation', extra: savedOrder);
                        }
                      } else {
                        context.go('/order-confirmation');
                      }
                    },
                    fullWidth: true,
                    size: ButtonSize.lg,
                    icon: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel? order;
  const OrderConfirmationScreen({super.key, this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 32),
                const Text('Request Sent to Vendor!',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                const Text('Your request has been successfully sent to the vendor. You will be notified once they accept it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: 40),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _ConfRow(
                        label: 'Request ID', 
                        value: order != null && order!.id.isNotEmpty
                            ? (order!.id.length > 8 ? order!.id.substring(0, 8).toUpperCase() : order!.id.toUpperCase())
                            : 'ES-B042A',
                      ),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                      _ConfRow(label: 'Total Amount', value: '\u20B9${order?.total.toStringAsFixed(0) ?? "1,815"}'),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                      const _ConfRow(label: 'Delivery Status', value: 'Processing', valueColor: AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                AppButton(
                  text: 'Track Order',
                  variant: ButtonVariant.accent,
                  onPressed: () => context.go('/order-tracking', extra: order?.id),
                  fullWidth: true,
                  size: ButtonSize.lg,
                  icon: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Back to Home',
                  variant: ButtonVariant.ghost,
                  onPressed: () => context.go('/home'),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ConfRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: valueColor ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// â”€â”€â”€ Shared order-code helper (top-level, accessible from all classes) â”€â”€â”€â”€â”€â”€â”€â”€
String _orderCodeFromId(String docId) {
  final rng = math.Random(docId.hashCode.abs());
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final alpha = List.generate(4, (_) => letters[rng.nextInt(26)]).join();
  final nums = List.generate(4, (_) => rng.nextInt(10)).join();
  return 'AL$alpha$nums';
}

// â”€â”€â”€ Order Tracking Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;
  const OrderTrackingScreen({super.key, this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}


class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final service = FirebaseService();

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return StreamBuilder<OrderModel?>(
        stream: service.getOrderByIdStream(widget.orderId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF5F0E8),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF5C1A1A))),
            );
          }
          final order = snapshot.data;
          if (order == null) return _buildEmptyState(context);
          return _buildTrackingContent(context, order);
        },
      );
    }

    // Default (no orderId specified): show all customer orders in BookingHistoryScreen
    return const BookingHistoryScreen();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _trackingHeader(context, null),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 64, color: Color(0xFF8B7355)),
                    SizedBox(height: 16),
                    Text('No orders to track',
                        style: TextStyle(color: Color(0xFF8B7355), fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingHeader(BuildContext context, OrderModel? order) {
    final code = order != null ? _orderCodeFromId(order.id) : '';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C1A1A), Color(0xFF8B3A3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) context.pop();
              else context.go('/home');
            },
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Tracking',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
                if (code.isNotEmpty)
                  Text('Order Code: $code',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent(BuildContext context, OrderModel order) {
    final step = order.trackingStep;
    final isRejected = order.status == 'Rejected';
    final isDelivered = order.status == 'Delivered';
    final isReturnRequested = order.status == 'Return Requested';
    final isReturned = order.status == 'Returned';
    final isCompleted = order.status == 'Completed';

    // Compute how many steps are completed (for horizontal stepper)
    final completedSteps = () {
      if (isCompleted || isReturned) return 6;
      if (isReturnRequested || isDelivered) return 5;
      return step.clamp(0, 4);
    }();

    final stepItems = [
      {
        'label': 'Request Sent',
        'done': step >= 0 && !isRejected,
        'time': 'Sent',
        'subtitle': 'Waiting for vendor approval',
      },
      {
        'label': 'Request Confirmed',
        'done': step >= 1 && !isRejected,
        'time': step >= 1 ? 'Approved' : 'Pending',
        'subtitle': isRejected ? 'Request was rejected' : 'Vendor accepted booking request',
      },
      {
        'label': 'Equipment Prepared',
        'done': step >= 2 && !isRejected,
        'time': step >= 2 ? 'Completed' : 'Pending',
        'subtitle': 'Equipment package ready for event',
      },
      {
        'label': 'Out for Delivery',
        'done': step >= 3 && !isRejected,
        'time': step >= 3 ? 'Shipped' : 'Pending',
        'subtitle': 'Transit to event venue',
      },
      {
        'label': 'Delivered',
        'done': step >= 4 && !isRejected,
        'time': step >= 4 ? 'Arrived' : 'Pending',
        'subtitle': 'Handed over and set up',
      },
    ];

    final locationStr = [order.address, order.city]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          children: [
            _trackingHeader(context, order),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Status banner Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isRejected
                          ? const Color(0xFFFEF2F2)
                          : isCompleted
                              ? const Color(0xFFF0FDF4)
                              : isDelivered
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRejected
                            ? const Color(0xFFEF4444)
                            : isCompleted
                                ? const Color(0xFF10B981)
                                : isDelivered
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isRejected
                                ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                : isCompleted
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : isDelivered
                                        ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRejected
                                ? Icons.cancel_rounded
                                : isCompleted
                                    ? Icons.check_circle_rounded
                                    : isDelivered
                                        ? Icons.inventory_2_rounded
                                        : Icons.local_shipping_rounded,
                            color: isRejected
                                ? const Color(0xFFEF4444)
                                : isCompleted
                                    ? const Color(0xFF10B981)
                                    : isDelivered
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFF59E0B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRejected
                                    ? 'Request Rejected'
                                    : 'Current Status: ${order.status}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF5C1A1A)),
                              ),
                              if (order.trackingNote.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(order.trackingNote,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B7355),
                                        fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Horizontal step tracker Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _HorizontalStepper(
                      completedSteps: completedSteps,
                      labels: const [
                        'PLACED', 'CONFIRMED', 'PREPARED',
                        'OUT FOR\nDELIVERY', 'DELIVERED', 'COMPLETED'
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Event details Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EVENT DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B7355),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Event', value: order.eventName.isEmpty ? 'N/A' : order.eventName),
                        _DetailRow(label: 'Deliver to', value: order.customerName),
                        _DetailRow(label: 'Venue Address', value: locationStr.isEmpty ? 'N/A' : locationStr),
                        _DetailRow(label: 'ZIP', value: order.zip.isEmpty ? 'N/A' : order.zip),
                        const Divider(color: Color(0xFFE8E0D4)),
                        _DetailRow(label: 'Total Amount', value: '\u20B9${order.total.toStringAsFixed(0)}', bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Receipt details Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E0D4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECEIPT DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B7355),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.name} \u00D7${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Color(0xFF5C4033)),
                                ),
                              ),
                              Text(
                                '\u20B9${(item.price * item.quantity * item.days).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5C1A1A)),
                              ),
                            ],
                          ),
                        )),
                        const Divider(color: Color(0xFFE8E0D4)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF5C4033))),
                            Text('\u20B9${order.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF5C1A1A))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Vertical detailed tracking steps Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRACKING TIMELINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8B7355),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(stepItems.length, (i) {
                          final s = stepItems[i];
                          final done = s['done'] as bool;
                          final label = s['label'] as String;
                          final subtitle = s['subtitle'] as String;
                          final time = s['time'] as String;
                          final isLast = i == stepItems.length - 1;
                          final stepColor = isRejected && i == 1
                              ? const Color(0xFFEF4444)
                              : done
                                  ? const Color(0xFF5C1A1A)
                                  : const Color(0xFFE8E0D4);
                          final iconData = isRejected && i == 1
                              ? Icons.close_rounded
                              : done
                                  ? Icons.check_rounded
                                  : null;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: stepColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: iconData != null
                                        ? Icon(iconData,
                                            color: Colors.white, size: 14)
                                        : Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B7355)),
                                            ),
                                          ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 48,
                                      color: done &&
                                              i + 1 < stepItems.length &&
                                              (stepItems[i + 1]['done'] as bool)
                                          ? const Color(0xFF5C1A1A)
                                          : const Color(0xFFE8E0D4),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(bottom: isLast ? 0 : 18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: done
                                                  ? const Color(0xFF5C1A1A)
                                                  : const Color(0xFF8B7355),
                                            ),
                                          ),
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: done
                                                  ? const Color(0xFF5C1A1A)
                                                  : const Color(0xFF8B7355),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: done
                                              ? const Color(0xFF8B7355)
                                              : const Color(0xFF8B7355)
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Rating card (if completed) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  if (isCompleted && order.rating > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFF59E0B), size: 18),
                              const SizedBox(width: 6),
                              const Text(
                                'Your Rental Rating',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ...List.generate(5, (i) {
                                return Icon(
                                  i < order.rating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 22,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${order.rating.toStringAsFixed(0)} STARS',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF92400E)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ã¢â€â‚¬Ã¢â€â‚¬ Delivered action Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
                  if (isDelivered) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (context.canPop()) context.pop();
                          else context.go('/booking-history');
                        },
                        icon: const Icon(Icons.assignment_return_rounded),
                        label: const Text('Go to Bookings to Return Items'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],

                  if (isReturnRequested) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFEC4899)
                                .withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 16, color: Color(0xFFEC4899)),
                          SizedBox(width: 8),
                          Text(
                            'Return request sent Ã¢â‚¬Â¢ Awaiting vendor pickup',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEC4899),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _DetailRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF8B7355), fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: const Color(0xFF5C1A1A),
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  DateTime? _selectedDate;

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
              primary: Color(0xFF5C1A1A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF5C1A1A),
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
    final service = FirebaseService();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// -----------------------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: Color(0xFF5C1A1A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'YOUR ACCOUNT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B7355),
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Order History & Tracking',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5C1A1A),
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Calendar Date Filter Row ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedDate != null ? const Color(0xFF5C1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B7355).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: _selectedDate != null ? Colors.white : const Color(0xFF5C1A1A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                : 'Filter by Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedDate != null ? Colors.white : const Color(0xFF5C1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Clear Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
// -----------------------------------------------------------------------------
            Expanded(
              child: StreamBuilder<List<OrderModel>>(
                stream: service.getCustomerOrders(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF5C1A1A)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  var orders = snapshot.data ?? [];

                  if (_selectedDate != null) {
                    orders = orders.where((o) =>
                        o.createdAt.year == _selectedDate!.year &&
                        o.createdAt.month == _selectedDate!.month &&
                        o.createdAt.day == _selectedDate!.day).toList();
                  }

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 72,
                              color: const Color(0xFF8B7355)
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            _selectedDate != null
                                ? 'No orders on ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                                : 'No orders yet',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5C1A1A)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDate != null
                                ? 'Try selecting a different date or clearing the filter'
                                : 'Your order history will appear here',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8B7355)),
                          ),
                          if (_selectedDate != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _selectedDate = null),
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                              label: const Text('Show All Orders'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C1A1A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: orders.length,
                    itemBuilder: (_, i) => _OrderHistoryCard(order: orders[i]),
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

// -----------------------------------------------------------------------------
class _OrderHistoryCard extends StatefulWidget {
  final OrderModel order;
  const _OrderHistoryCard({required this.order});

  @override
  State<_OrderHistoryCard> createState() => _OrderHistoryCardState();
}

class _OrderHistoryCardState extends State<_OrderHistoryCard> {
  bool _loading = false;

  // Steps: 0=Placed,1=Confirmed,2=Prepared,3=OutForDelivery,4=Delivered,5=Completed
  static const _stepLabels = [
    'PLACED', 'CONFIRMED', 'PREPARED', 'OUT FOR\nDELIVERY', 'DELIVERED', 'COMPLETED'
  ];

  int get _completedSteps {
    final s = widget.order.status;
    final t = widget.order.trackingStep;
    if (s == 'Completed') return 6;
    if (s == 'Returned') return 6;
    if (s == 'Return Requested') return 5;
    if (s == 'Delivered') return 5;
    return t.clamp(0, 4);
  }

  Future<void> _requestReturn(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Return?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5C1A1A))),
        content: const Text(
            'Are you ready to return the rented equipment to the vendor?',
            style: TextStyle(color: Color(0xFF8B7355))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet',
                style: TextStyle(color: Color(0xFF8B7355))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Yes, Return',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      try {
        await FirebaseService().requestReturn(widget.order.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('\u2713 Return request sent to vendor!'),
              backgroundColor: Color(0xFF6366F1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _showRatingDialog(BuildContext context) async {
    double selectedRating = 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Column(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              const Text('Rate Your Experience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF5C1A1A))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final v = i + 1.0;
                  return GestureDetector(
                    onTap: () => setDlg(() => selectedRating = v),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        selectedRating >= v
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: selectedRating >= v ? 46 : 38,
                        color: selectedRating >= v
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          setState(() => _loading = true);
                          try {
                            await FirebaseService()
                                .rateOrder(widget.order.id, selectedRating);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Thanks! Rated ${selectedRating.toStringAsFixed(0)} \u2605'),
                                  backgroundColor: const Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')));
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Submit Rating',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final code = _orderCodeFromId(order.id);
    final alpha = code.substring(0, 6); // ALXXXX
    final nums = code.substring(6); // NNNN

    final dt = order.createdAt;
    final dateStr =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    final isPaid = order.status == 'Delivered' ||
        order.status == 'Completed' ||
        order.status == 'Returned' ||
        order.status == 'Return Requested';

    final isDelivered = order.status == 'Delivered';
    final isReturnRequested = order.status == 'Return Requested';
    final isReturned = order.status == 'Returned';
    final isCompleted = order.status == 'Completed';

    final completed = _completedSteps;

    return GestureDetector(
      onTap: () => context.push('/order-tracking', extra: order.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// -----------------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: date, payment method, status badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ordered: $dateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B7355),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'CASH ON DELIVERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPaid ? 'PAID' : 'PENDING',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: order code + status chip
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ORDER CODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8B7355),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: alpha,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C4033),
                              letterSpacing: 2,
                            ),
                          ),
                          TextSpan(
                            text: nums,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5C1A1A),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFFF0FDF4)
                            : isDelivered
                                ? const Color(0xFFEFF6FF)
                                : isReturnRequested
                                    ? const Color(0xFFFDF4FF)
                                    : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : isDelivered
                                  ? const Color(0xFF3B82F6)
                                  : isReturnRequested
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : isDelivered
                                  ? const Color(0xFF3B82F6)
                                  : isReturnRequested
                                      ? const Color(0xFFEC4899)
                                      : const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFECE8E1)),

// -----------------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: _HorizontalStepper(
              completedSteps: completed,
              labels: _stepLabels,
            ),
          ),

          const Divider(height: 1, color: Color(0xFFECE8E1)),

// -----------------------------------------------------------------------------
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE8E0D4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECEIPT DETAILS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8B7355),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} \u00D7 ${item.quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5C4033),
                            ),
                          ),
                        ),
                        Text(
                          '\u20B9${(item.price * item.quantity * item.days).toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE8E0D4)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF5C4033),
                      ),
                    ),
                    Text(
                      '\u20B9${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF5C1A1A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

// -----------------------------------------------------------------------------
          if (isCompleted && order.rating > 0) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Your Rental Rating',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'This order is reviewed and locked.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFFDE68A)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.eventName.isEmpty ? 'Rental' : order.eventName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5C4033),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              i < order.rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '${order.rating.toStringAsFixed(0)} STARS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

// -----------------------------------------------------------------------------
          if (isDelivered || isReturned || isReturnRequested) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (isDelivered) ...[
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)))
                          : ElevatedButton.icon(
                              onPressed: () => _requestReturn(context),
                              icon: const Icon(
                                  Icons.assignment_return_rounded,
                                  size: 16),
                              label: const Text('Return Items'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                              ),
                            ),
                    ),
                  ],
                  if (isReturnRequested) ...[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFEC4899)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: Color(0xFFEC4899)),
                            SizedBox(width: 6),
                            Text(
                              'Awaiting Vendor Pickup',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEC4899)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (isReturned) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(context),
                        icon: const Icon(Icons.star_rounded, size: 16),
                        label: const Text('Rate Experience'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}

// -----------------------------------------------------------------------------
class _HorizontalStepper extends StatelessWidget {
  final int completedSteps;
  final List<String> labels;

  const _HorizontalStepper({
    required this.completedSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(n * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line between steps
            final stepIdx = (i + 1) ~/ 2;
            final done = stepIdx < completedSteps;
            return Container(
              width: 12,
              height: 2,
              color: done
                  ? const Color(0xFF5C1A1A)
                  : const Color(0xFFD6C9B8),
            );
          } else {
            final stepIdx = i ~/ 2;
            final done = stepIdx < completedSteps;
            final isLast = stepIdx == n - 1;
            final isCurrent = stepIdx == completedSteps - 1;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? const Color(0xFF5C1A1A)
                        : const Color(0xFFE8E0D4),
                    border: Border.all(
                      color: done
                          ? const Color(0xFF5C1A1A)
                          : isCurrent
                              ? const Color(0xFF5C1A1A)
                              : const Color(0xFFD6C9B8),
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : Center(
                          child: Text(
                            '${stepIdx + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? const Color(0xFF5C1A1A)
                                  : const Color(0xFF8B7355),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: isLast ? 54 : 48,
                  child: Text(
                    labels[stepIdx],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                      color: done
                          ? const Color(0xFF5C1A1A)
                          : const Color(0xFF8B7355),
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }
}



// -----------------------------------------------------------------------------
class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends State<AvailabilityCalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Select Dates',
            subtitle: 'Choose your rental period',
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
          Expanded(
            child: Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  GlassCard(
                    child: CalendarDatePicker(
                      initialDate: _selected,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      onDateChanged: (d) => setState(() => _selected = d),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selected Date',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          '${_selected.day}/${_selected.month}/${_selected.year}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Add to Cart',
                    onPressed: () => context.go('/cart'),
                    fullWidth: true,
                    size: ButtonSize.lg,
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

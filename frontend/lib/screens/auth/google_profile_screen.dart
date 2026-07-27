import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/firebase_service.dart';
import '../../services/push_notification_service.dart';
import '../../models/user_model.dart';

// ─── Google Sign-In Profile Completion Screen ──────────────────────────────────
class GoogleProfileScreen extends StatefulWidget {
  final User googleUser;
  const GoogleProfileScreen({super.key, required this.googleUser});

  @override
  State<GoogleProfileScreen> createState() => _GoogleProfileScreenState();
}

class _GoogleProfileScreenState extends State<GoogleProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _shopNameCtrl = TextEditingController();
  final _shopDescCtrl = TextEditingController();

  String _role = 'Customer';
  bool _loading = false;
  bool _roleSelected = false; // Step 1: pick role; Step 2: fill form

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _shopNameCtrl.dispose();
    _shopDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = widget.googleUser;
      final location = '${_cityCtrl.text.trim()}, ${_addressCtrl.text.trim()}';
      final userModel = UserModel(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        phone: _phoneCtrl.text.trim(),
        location: location,
        role: _role,
        createdAt: DateTime.now(),
        shopName: _role == 'Vendor' ? _shopNameCtrl.text.trim() : null,
        pincode: _pincodeCtrl.text.trim(),
        shopDescription: _role == 'Vendor' && _shopDescCtrl.text.trim().isNotEmpty
            ? _shopDescCtrl.text.trim()
            : null,
      );
      await FirebaseService().updateUserProfile(userModel);
      try {
        await PushNotificationService().onUserLogin();
      } catch (_) {}
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (widget.googleUser.displayName?.isNotEmpty == true)
                              ? widget.googleUser.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${widget.googleUser.displayName?.split(' ').first ?? 'there'}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'Complete your profile to continue',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (!_roleSelected) ...[
                  // ── Step 1: Role selection ────────────────────────────────
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I am a...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose your account type to personalise your experience.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        _RoleCard(
                          role: 'Customer',
                          icon: Icons.person_outlined,
                          subtitle: 'Browse and rent event equipment',
                          selected: _role == 'Customer',
                          onTap: () => setState(() => _role = 'Customer'),
                        ),
                        const SizedBox(height: 12),
                        _RoleCard(
                          role: 'Vendor',
                          icon: Icons.store_outlined,
                          subtitle: 'List your equipment for rent',
                          selected: _role == 'Vendor',
                          onTap: () => setState(() => _role = 'Vendor'),
                        ),
                        const SizedBox(height: 28),
                        AppButton(
                          text: 'Continue as $_role',
                          fullWidth: true,
                          size: ButtonSize.lg,
                          onPressed: () => setState(() => _roleSelected = true),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ── Step 2: Fill profile details ──────────────────────────
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _role == 'Vendor'
                                      ? AppColors.accent.withValues(alpha: 0.12)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _role == 'Vendor' ? Icons.store_outlined : Icons.person_outlined,
                                      size: 14,
                                      color: _role == 'Vendor' ? AppColors.accent : Colors.blue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _role,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _role == 'Vendor' ? AppColors.accent : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _roleSelected = false),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Phone
                          AppInput(
                            label: 'Phone Number',
                            hint: '+91 9876543210',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            prefix: const Icon(Icons.phone_outlined, color: AppColors.primary),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your phone number' : null,
                          ),
                          const SizedBox(height: 16),

                          // Address
                          AppInput(
                            label: 'Address',
                            hint: 'Street / Area',
                            controller: _addressCtrl,
                            prefix: const Icon(Icons.home_outlined, color: AppColors.primary),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your address' : null,
                          ),
                          const SizedBox(height: 16),

                          // City
                          AppInput(
                            label: 'City',
                            hint: 'e.g. Mumbai',
                            controller: _cityCtrl,
                            prefix: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your city' : null,
                          ),
                          const SizedBox(height: 16),

                          // Pincode
                          AppInput(
                            label: 'Pincode',
                            hint: 'e.g. 400001',
                            controller: _pincodeCtrl,
                            keyboardType: TextInputType.number,
                            prefix: const Icon(Icons.pin_drop_outlined, color: AppColors.primary),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your pincode';
                              if (!RegExp(r'^\d{4,8}$').hasMatch(v)) return 'Enter a valid pincode (4–8 digits)';
                              return null;
                            },
                          ),

                          if (_role == 'Vendor') ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 12),
                            const Text(
                              'Shop Details',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Shop Name',
                              hint: 'e.g. SoundPro Rentals',
                              controller: _shopNameCtrl,
                              prefix: const Icon(Icons.store_outlined, color: AppColors.primary),
                              validator: (v) => _role == 'Vendor' && (v == null || v.isEmpty) ? 'Enter your shop name' : null,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Shop Description (optional)',
                              hint: 'Tell customers about your shop...',
                              controller: _shopDescCtrl,
                              prefix: const Icon(Icons.description_outlined, color: AppColors.primary),
                            ),
                          ],
                          const SizedBox(height: 28),

                          AppButton(
                            text: 'Complete Sign Up',
                            variant: ButtonVariant.accent,
                            fullWidth: true,
                            size: ButtonSize.lg,
                            loading: _loading,
                            onPressed: _loading ? null : _saveProfile,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Role selection card ───────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: selected ? AppColors.bubbleShadow : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}

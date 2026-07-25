import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const _pages = [
  _OnboardingData(
    icon: Icons.inventory_2_rounded,
    title: 'Welcome to EventSphere',
    description:
        'Your all-in-one platform for renting event equipment, managing logistics, and creating unforgettable experiences.',
  ),
  _OnboardingData(
    icon: Icons.search_rounded,
    title: 'Browse & Discover',
    description:
        'Explore thousands of professional event equipment — sound systems, lighting rigs, staging, AV gear, and more.',
  ),
  _OnboardingData(
    icon: Icons.local_shipping_rounded,
    title: 'Seamless Delivery',
    description:
        'Book, track, and manage deliveries effortlessly. Our logistics team ensures your equipment arrives on time.',
  ),
];

class OnboardingScreen extends StatelessWidget {
  final int page;
  const OnboardingScreen({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final data = _pages[page - 1];
    final isLast = page == 3;
    final nextRoute = isLast ? '/login' : '/onboarding-${page + 1}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334F46E5),
                              blurRadius: 28,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(data.icon, color: Colors.white, size: 80),
                      ),
                      const SizedBox(height: 40),
                      Text(data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Text(data.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == page - 1;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                AppButton(
                  text: isLast ? 'Get Started' : 'Next',
                  onPressed: () => context.go(nextRoute),
                  fullWidth: true,
                  size: ButtonSize.lg,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../services/push_notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      try {
        await PushNotificationService().onUserLogin();
      } catch (e) {
        debugPrint('Warning: Could not complete push notification setup on login: $e');
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        final message = e is FirebaseAuthException
            ? (e.message ?? 'An error occurred during sign in')
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
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
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F0F172A),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Welcome Back',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Sign in to continue to EventSphere',
                    style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 36),
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppInput(
                          label: 'Email Address',
                          hint: 'you@example.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefix: const Icon(Icons.mail_outline,
                              color: AppColors.primary),
                          validator: (v) =>
                              v!.isEmpty ? 'Enter your email' : null,
                        ),
                        const SizedBox(height: 16),
                        AppInput(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          prefix: const Icon(Icons.lock_outline,
                              color: AppColors.primary),
                          suffix: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _remember,
                                  onChanged: (v) =>
                                      setState(() => _remember = v!),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                const Text('Remember me',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.go('/forgot-password'),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Sign In',
                          onPressed: _loading ? null : _handleSignIn,
                          loading: _loading,
                          fullWidth: true,
                          size: ButtonSize.lg,
                        ),
                        const SizedBox(height: 24),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? ",
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500)),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: const Text('Sign Up',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OtpType;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/core/network/supabase_service.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  String? _resolveEmail() {
    return widget.email ??
        ref.read(authNotifierProvider)?.email ??
        SupabaseService.authOrNull?.currentUser?.email;
  }

  Future<void> _verify() async {
    final token = _otpCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    final email = _resolveEmail();
    if (email == null || email.isEmpty) {
      setState(() => _errorMessage =
          'Email address not found. Please register or sign in again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authRepositoryProvider).verifyOtp(
          email: email,
          token: token,
          type: OtpType.signup,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(data: final user):
        ref.read(authNotifierProvider.notifier).setUser(user);
        if (!user.isOnboardingCompleted) {
          context.go('/onboarding/setup');
        } else {
          context.go('/dashboard');
        }
      case Failure(message: final msg):
        setState(() => _errorMessage = msg);
    }
  }

  Future<void> _resendCode() async {
    final email = _resolveEmail();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address not found.')),
      );
      return;
    }

    setState(() => _isResending = true);
    final result =
        await ref.read(authRepositoryProvider).resendVerificationEmail(email);

    if (!mounted) return;
    setState(() => _isResending = false);

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A fresh verification code has been sent!'),
            duration: Duration(seconds: 3),
          ),
        );
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final email = _resolveEmail();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/login'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Verify your email',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              email != null && email.isNotEmpty
                  ? 'We\'ve sent a verification code to $email. Enter it below to continue.'
                  : 'We\'ve sent a 6-digit code to your email address. Enter it below to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            AppTextField(
              label: 'Verification Code',
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: colorScheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    text: 'Verify',
                    onPressed: _verify,
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Didn\'t receive the code? ',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                GestureDetector(
                  onTap: _isResending ? null : _resendCode,
                  child: Text(
                    _isResending ? 'Sending...' : 'Resend',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authRepositoryProvider).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(data: final user):
        ref.read(authNotifierProvider.notifier).setUser(user);
      case Failure(message: final msg):
        setState(() => _errorMessage = msg);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(authRepositoryProvider).signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    switch (result) {
      case Success():
        // Browser was launched for OAuth. On return via deep-link callback,
        // Supabase Flutter processes session and notifies AuthNotifier -> GoRouter automatically redirects.
        break;
      case Failure(message: final msg):
        setState(() => _errorMessage = msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 52),

                // ── Logo ───────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/Icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Zindagi+',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Your personal health companion',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),

                const SizedBox(height: 44),

                // ── Heading ────────────────────────────────────────────────
                Text(
                  'Welcome back 👋',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue your health journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Email ──────────────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') || !v.contains('.')
                          ? 'Enter a valid email'
                          : null,
                ),

                const SizedBox(height: 16),

                // ── Password ───────────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Min. 6 characters' : null,
                ),

                const SizedBox(height: 8),

                // ── Forgot Password Link ────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: colorScheme.primary,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // ── Error banner ───────────────────────────────────────────
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

                // ── Login button ───────────────────────────────────────────
                PrimaryButton(
                  text: 'Sign In',
                  onPressed: (_isLoading || _isGoogleLoading) ? null : _login,
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward_rounded,
                ),

                const SizedBox(height: 20),

                // ── Divider ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Continue with Google button ────────────────────────────
                OutlinedButton(
                  onPressed:
                      (_isLoading || _isGoogleLoading) ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.25),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: theme.cardColor,
                  ),
                  child: _isGoogleLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _GoogleLogoIcon(size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 24),

                // ── Register link ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?  ",
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6), 
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw standard Google 4-color 'G'
    // Blue: #4285F4, Green: #34A853, Yellow: #FBBC05, Red: #EA4335
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red (top arc)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14159 / 2 - 0.6, 1.6, true, paint);

    // Yellow (left arc)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14159 / 2 + 0.5, 1.4, true, paint);

    // Green (bottom arc)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.2, 1.7, true, paint);

    // Blue (right arc)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.6, 1.0, true, paint);

    // Inner cutout to form 'G' shape
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Blue crossbar
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTRB(
      center.dx,
      center.dy - (radius * 0.22),
      center.dx + radius,
      center.dy + (radius * 0.22),
    );
    canvas.drawRect(barRect, barPaint);

    // Cutout right-upper quadrant inside crossbar
    final topCutout = Rect.fromLTRB(
      center.dx,
      center.dy - radius,
      center.dx + radius,
      center.dy - (radius * 0.22),
    );
    canvas.drawRect(topCutout, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

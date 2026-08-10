import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notifications = true;
  bool _dailyReminders = true;
  bool _biometrics = false;
  bool _dataSharing = false;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: const Text('Settings'),
        ),
        body: AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (_, child) {
            final t = CurvedAnimation(
              parent: _entranceCtrl,
              curve: Curves.easeOutCubic,
            ).value;
            return Opacity(opacity: t, child: child);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            children: [
              // ── Profile card ─────────────────────────────────────────────
              GlassPanel(
                padding: const EdgeInsets.all(20),
                radius: 24,
                gradient: LinearGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: .12),
                    AppColors.cyan.withValues(alpha: .04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.emerald, Color(0xFF238F87)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '✨  Premium Member',
                              style: TextStyle(
                                color: AppColors.mint,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TapScale(
                      onTap: () => context.push('/profile/edit'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Account section ───────────────────────────────────────────
              _SectionHeader('Account'),
              _NavTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => context.push('/profile/edit'),
              ),
              _NavTile(
                icon: Icons.calendar_today_outlined,
                label: 'Health Timeline',
                onTap: () => context.push('/timeline'),
              ),
              _NavTile(
                icon: Icons.medication_outlined,
                label: 'Medications',
                onTap: () => context.push('/medications'),
              ),

              const SizedBox(height: 20),

              // ── Preferences section ───────────────────────────────────────
              _SectionHeader('Preferences'),
              _ToggleTile(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                subtitle: 'Reminders and health alerts',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
              _ToggleTile(
                icon: Icons.alarm_outlined,
                label: 'Daily Reminders',
                subtitle: 'Medication and meal reminders',
                value: _dailyReminders,
                onChanged: (v) => setState(() => _dailyReminders = v),
              ),
              _ToggleTile(
                icon: Icons.fingerprint_rounded,
                label: 'Biometric Login',
                subtitle: 'Face ID or fingerprint',
                value: _biometrics,
                onChanged: (v) => setState(() => _biometrics = v),
              ),

              const SizedBox(height: 20),

              // ── Data & Privacy section ────────────────────────────────────
              _SectionHeader('Data & Privacy'),
              _ToggleTile(
                icon: Icons.share_outlined,
                label: 'Anonymous Data Sharing',
                subtitle: 'Help improve AI recommendations',
                value: _dataSharing,
                onChanged: (v) => setState(() => _dataSharing = v),
              ),
              _NavTile(
                icon: Icons.download_outlined,
                label: 'Export My Data',
                onTap: () {},
              ),
              _NavTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () {},
              ),
              _NavTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete Account',
                labelColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () => _showDeleteConfirm(context),
              ),

              const SizedBox(height: 20),

              // ── Support section ───────────────────────────────────────────
              _SectionHeader('Support'),
              _NavTile(
                icon: Icons.help_outline_rounded,
                label: 'Help Centre',
                onTap: () {},
              ),
              _NavTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Contact Us',
                onTap: () {},
              ),
              _NavTile(
                icon: Icons.star_outline_rounded,
                label: 'Rate the App',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // Version info
              const Center(
                child: Text(
                  'Zindagi+  v1.0.0  ·  Made with ❤️ in Pakistan',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign out
              _SignOutButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.warning_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Delete Account?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will permanently delete all your health data, reports, and recommendations. This cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: .15),
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textTertiary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? labelColor, iconColor;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.98 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.iconColor ?? AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.labelColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Apple §1: switch responds instantly on toggle
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.emerald,
            activeTrackColor: AppColors.emerald.withValues(alpha: .3),
            inactiveTrackColor: AppColors.divider,
            inactiveThumbColor: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends StatefulWidget {
  const _SignOutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends State<_SignOutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.97 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: .3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tap scale helper ───────────────────────────────────────────────────────────

class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.92 : 1.0,
        child: widget.child,
      ),
    );
  }
}

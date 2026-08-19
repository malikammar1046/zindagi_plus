import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Design system constants ────────────────────────────────────────────────────
const _kEmerald = Color(0xFF00674F);
const _kBurgundy = Color(0xFF670018);
const _kBg = Color(0xFFF4F6F8);
const _kText = Color(0xFF181C22);
const _kSubtext = Color(0xFF6B7280);
const _kMuted = Color(0xFF9CA3AF);
const _kDivider = Color(0xFFF3F4F6);
const _kGray = Color(0xFF6B7280);

// ── Screen ─────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _dailyReminders = true;
  bool _biometrics = false;
  bool _dataSharing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(fallbackLocation: '/profile'),
        title: const Text(
          'Settings',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Mini profile card ─────────────────────────────────────────────
          _MiniProfileCard(user: user, onEditTap: () => context.push('/profile/edit')),

          const SizedBox(height: 28),

          // ── Account section ───────────────────────────────────────────────
          const _SectionLabel(label: 'Account'),
          _ListGroup(
            children: [
              _NavRow(
                icon: Icons.person_outline_rounded,
                iconColor: _kEmerald,
                title: 'Edit Profile',
                subtitle: 'Update your personal details',
                onTap: () => context.push('/profile/edit'),
              ),
              _NavRow(
                icon: Icons.manage_accounts_outlined,
                iconColor: _kEmerald,
                title: 'Account Management',
                subtitle: 'Security, email, account info',
                onTap: () => context.push('/settings/account'),
              ),
              _NavRow(
                icon: Icons.lock_outline_rounded,
                iconColor: _kGray,
                title: 'Change Password',
                onTap: () => context.push('/settings/account'),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Preferences section ───────────────────────────────────────────
          const _SectionLabel(label: 'Preferences'),
          _ListGroup(
            children: [
              _NavRow(
                icon: Icons.notifications_outlined,
                iconColor: _kEmerald,
                title: 'Notification Preferences',
                subtitle: 'Reminders, alerts, quiet hours',
                onTap: () => context.push('/settings/notifications'),
              ),
              _ToggleRow(
                icon: Icons.alarm_outlined,
                iconColor: _kGray,
                title: 'Daily Reminders',
                subtitle: 'Medication and meal reminders',
                value: _dailyReminders,
                onChanged: (v) => setState(() => _dailyReminders = v),
              ),
              _ToggleRow(
                icon: Icons.fingerprint_rounded,
                iconColor: _kGray,
                title: 'Biometric Login',
                subtitle: 'Face ID or fingerprint unlock',
                value: _biometrics,
                onChanged: (v) => setState(() => _biometrics = v),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Health & Privacy section ──────────────────────────────────────
          const _SectionLabel(label: 'Health & Privacy'),
          _ListGroup(
            children: [
              _ToggleRow(
                icon: Icons.share_outlined,
                iconColor: _kGray,
                title: 'Anonymous Data Sharing',
                subtitle: 'Help improve AI recommendations',
                value: _dataSharing,
                onChanged: (v) => setState(() => _dataSharing = v),
              ),
              _NavRow(
                icon: Icons.download_outlined,
                iconColor: _kGray,
                title: 'Export My Data',
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: _kGray,
                title: 'Privacy Policy',
                onTap: () => context.push('/settings/privacy'),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── About section ─────────────────────────────────────────────────
          const _SectionLabel(label: 'About'),
          _ListGroup(
            children: [
              _NavRow(
                icon: Icons.info_outline_rounded,
                iconColor: _kGray,
                title: 'About Zindagi+',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.help_outline_rounded,
                iconColor: _kGray,
                title: 'Help & Support',
                onTap: () {},
              ),
              _NavRow(
                icon: Icons.star_outline_rounded,
                iconColor: _kGray,
                title: 'Rate the App',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Danger zone ───────────────────────────────────────────────────
          const _SectionLabel(label: 'Danger Zone'),
          _ListGroup(
            children: [
              _NavRow(
                icon: Icons.delete_outline_rounded,
                iconColor: _kBurgundy,
                title: 'Delete Account',
                titleColor: _kBurgundy,
                onTap: () => context.push('/settings/account/delete'),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Sign Out ──────────────────────────────────────────────────────
          _ListGroup(
            children: [
              _NavRow(
                icon: Icons.logout_rounded,
                iconColor: _kBurgundy,
                title: 'Sign Out',
                titleColor: _kBurgundy,
                showChevron: false,
                onTap: () => ref.read(authNotifierProvider.notifier).logout(),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Footer ────────────────────────────────────────────────────────
          const Center(
            child: Text(
              'Zindagi+  v1.0.0  ·  Made with ❤️ in Pakistan',
              style: TextStyle(
                fontSize: 11,
                color: _kMuted,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Mini profile card (top of settings) ───────────────────────────────────────

class _MiniProfileCard extends StatelessWidget {
  const _MiniProfileCard({required this.user, required this.onEditTap});
  final dynamic user;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final initials = (user?.name?.isNotEmpty == true)
        ? (user!.name as String)[0].toUpperCase()
        : 'U';
    final name = user?.name ?? 'User';
    final email = user?.email ?? '';

    Widget buildAvatar() {
      final photoUrl = user?.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        final isNetwork =
            photoUrl.startsWith('http://') || photoUrl.startsWith('https://');
        if (isNetwork) {
          return Image.network(
            photoUrl,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        } else {
          return Image.file(
            File(photoUrl),
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }
      }

      return Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF00674F), Color(0xFF008969)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: buildAvatar(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kSubtext,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kEmerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '✨  Premium Member',
                    style: TextStyle(
                      color: _kEmerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditTap,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 17,
                color: _kSubtext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── List group container ───────────────────────────────────────────────────────

class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

// ── Nav row (tappable, chevron) ────────────────────────────────────────────────

class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.showChevron = true,
    this.isLast = false,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool showChevron;
  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconBg = widget.iconColor.withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            color: _pressed ? const Color(0xFFF0F4F3) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: widget.iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.titleColor ?? _kText,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFFD1D5DB),
                  ),
              ],
            ),
          ),
        ),
        if (!widget.isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            endIndent: 0,
            color: _kDivider,
          ),
      ],
    );
  }
}

// ── Toggle row ─────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final iconBg = iconColor.withValues(alpha: 0.12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: _kEmerald,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            endIndent: 0,
            color: _kDivider,
          ),
      ],
    );
  }
}

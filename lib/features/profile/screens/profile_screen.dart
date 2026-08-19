import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/user.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

// ── Color constants (from design system) ──────────────────────────────────────
const _kEmerald = Color(0xFF00674F);
const _kBurgundy = Color(0xFF670018);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF4F6F8),
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit_outlined, size: 16, color: _kEmerald),
            label: const Text(
              'Edit',
              style: TextStyle(
                color: _kEmerald,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // ── Profile Header ────────────────────────────────────────────────
          _ProfileHeader(user: user),

          if (user?.primaryGoal != null || user?.dietType != null) ...[
            const SizedBox(height: 16),
            _GoalAndDietCard(user: user!),
          ],

          const SizedBox(height: 24),

          // ── Health section ────────────────────────────────────────────────
          const _SectionLabel(label: 'Health'),
          _ListGroup(
            children: [
              _ListRow(
                icon: Icons.person_outline_rounded,
                iconColor: _kEmerald,
                title: 'Health Information',
                subtitle: 'Age, weight, blood type, conditions',
                onTap: () => context.push('/profile/edit'),
              ),
              _ListRow(
                icon: Icons.history_rounded,
                iconColor: _kEmerald,
                title: 'Health Timeline',
                subtitle: 'Your health journey',
                onTap: () => context.push('/timeline'),
              ),
              _ListRow(
                icon: Icons.medication_outlined,
                iconColor: _kEmerald,
                title: 'Medications',
                subtitle: 'Active prescriptions & reminders',
                onTap: () => context.push('/medications'),
              ),
              _ListRow(
                icon: Icons.monitor_heart_outlined,
                iconColor: _kEmerald,
                title: 'Health Score',
                subtitle: 'View score breakdown',
                onTap: () => context.push('/score-breakdown'),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Activity & Nutrition section ──────────────────────────────────
          const _SectionLabel(label: 'Activity & Nutrition'),
          _ListGroup(
            children: [
              _ListRow(
                icon: Icons.directions_run_rounded,
                iconColor: _kEmerald,
                title: 'Activity',
                subtitle: 'Exercise plans & tracking',
                onTap: () => context.push('/activities'),
              ),
              _ListRow(
                icon: Icons.restaurant_outlined,
                iconColor: _kEmerald,
                title: 'Meals',
                subtitle: 'AI-curated meal recommendations',
                onTap: () => context.go('/meals'),
              ),
              _ListRow(
                icon: Icons.auto_awesome_outlined,
                iconColor: _kEmerald,
                title: 'AI Recommendations',
                subtitle: 'Personalised health insights',
                onTap: () => context.push('/recommendation/1'),
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Account section ───────────────────────────────────────────────
          const _SectionLabel(label: 'Account'),
          _ListGroup(
            children: [
              _ListRow(
                icon: Icons.settings_outlined,
                iconColor: const Color(0xFF6B7280),
                title: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              _ListRow(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF6B7280),
                title: 'Help & Support',
                onTap: () {},
                isLast: true,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Sign Out ──────────────────────────────────────────────────────
          _ListGroup(
            children: [
              _ListRow(
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

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final User? user;

  Widget _buildAvatar(String initials) {
    final photoUrl = user?.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      final isNetwork =
          photoUrl.startsWith('http://') || photoUrl.startsWith('https://');
      if (isNetwork) {
        return Image.network(
          photoUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 38,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 38,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        );
      } else {
        return Image.file(
          File(photoUrl),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 38,
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
          fontSize: 38,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = (user?.name.isNotEmpty == true)
        ? user!.name[0].toUpperCase()
        : 'U';
    final name = user?.name ?? 'User';
    final email = user?.email ?? '';

    final weightStr = user?.weightKg != null
        ? '${user!.weightKg!.toStringAsFixed(0)} kg'
        : '72 kg';
    final heightStr = user?.heightCm != null
        ? '${user!.heightCm!.toStringAsFixed(0)} cm'
        : '175 cm';
    final bloodStr = user?.bloodType ?? 'B+';
    final ageStr = user?.age != null ? '${user!.age}' : '24';
    final cityStr = user?.city ?? 'Lahore';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          // Avatar with emerald ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00674F), Color(0xFF008969)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kEmerald.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildAvatar(initials),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF181C22),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$email · 📍 $cityStr',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),

          // Premium badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: _kEmerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _kEmerald.withValues(alpha: 0.2),
              ),
            ),
            child: const Text(
              '✨  Active Health Member',
              style: TextStyle(
                color: _kEmerald,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Dynamic health stats bar
          Row(
            children: [
              _StatCell(value: weightStr, label: 'Weight'),
              _StatDivider(),
              _StatCell(value: heightStr, label: 'Height'),
              _StatDivider(),
              _StatCell(value: bloodStr, label: 'Blood Type'),
              _StatDivider(),
              _StatCell(value: ageStr, label: 'Age'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalAndDietCard extends StatelessWidget {
  const _GoalAndDietCard({required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.primaryGoal != null) ...[
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.primaryGoal!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (user.dietType != null)
                  _TagChip(label: '🥗 ${user.dietType!}'),
                if (user.activityLevel != null)
                  _TagChip(label: '🏃 ${user.activityLevel!}'),
                if (user.fitnessExperience != null)
                  _TagChip(label: '💪 ${user.fitnessExperience!}'),
                ...user.conditions.map((c) => _TagChip(label: '🩺 $c')),
                ...user.allergies.map((a) => _TagChip(label: '⚠️ $a')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF181C22),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: const Color(0xFFE5E7EB),
    );
  }
}

// ── Reusable List Section Widgets ─────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

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
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.showChevron = true,
    this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: titleColor ?? const Color(0xFF181C22),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFFD1D5DB),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 66,
            endIndent: 16,
            color: Color(0xFFF3F4F6),
          ),
      ],
    );
  }
}

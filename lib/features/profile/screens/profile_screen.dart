import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            icon: Icon(Icons.edit_outlined, size: 16, color: _kEmerald),
            label: Text(
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

          const SizedBox(height: 28),

          // ── Health section ────────────────────────────────────────────────
          _SectionLabel(label: 'Health'),
          _ListGroup(
            children: [
              _ListRow(
                icon: Icons.person_outline_rounded,
                iconColor: _kEmerald,
                title: 'Health Information',
                subtitle: 'Age, weight, blood type',
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
          _SectionLabel(label: 'Activity & Nutrition'),
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
          _SectionLabel(label: 'Account'),
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
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final initials = (user?.name?.isNotEmpty == true)
        ? (user!.name as String)[0].toUpperCase()
        : 'U';
    final name = user?.name ?? 'User';
    final email = user?.email ?? '';

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
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 38,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            email,
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
              '✨  Premium Member',
              style: TextStyle(
                color: _kEmerald,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Compact health stats bar
          Row(
            children: [
              _StatCell(value: '72 kg', label: 'Weight'),
              _StatDivider(),
              _StatCell(value: '175 cm', label: 'Height'),
              _StatDivider(),
              _StatCell(value: 'B+', label: 'Blood Type'),
              _StatDivider(),
              _StatCell(value: '24', label: 'Age'),
            ],
          ),
        ],
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
      height: 28,
      color: const Color(0xFFE5E7EB),
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
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── List group (white card container with internal dividers) ───────────────────

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

// ── List row ───────────────────────────────────────────────────────────────────

class _ListRow extends StatefulWidget {
  const _ListRow({
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
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
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
            color: _pressed
                ? const Color(0xFFF0F4F3)
                : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Icon container
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
                // Title + optional subtitle
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
                          color: widget.titleColor ?? const Color(0xFF181C22),
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
                            color: Color(0xFF9CA3AF),
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
            color: Color(0xFFF3F4F6),
          ),
      ],
    );
  }
}

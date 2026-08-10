import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const SectionHeader(title: 'Account Info'),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(label: 'Email', value: 'user@example.com'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _InfoRow(label: 'Member Since', value: 'August 2026'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _InfoRow(label: 'Last Login', value: 'Today, 08:30 AM'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Status',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const StatusBadge(text: 'Active', status: BadgeStatus.normal),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Security'),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      context.push('/forgot-password');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.security_rounded, color: colorScheme.primary),
                    title: const Text('Two-Factor Auth'),
                    subtitle: const Text('Coming soon'),
                    trailing: const StatusBadge(text: 'Pro', status: BadgeStatus.info),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Data Management'),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Export My Data',
              icon: Icons.download_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data export started...')),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/settings/account/delete');
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _passwordCtrl = TextEditingController();
  bool _isConfirmed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_isConfirmed || _passwordCtrl.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate API call
    if (!mounted) return;
    
    // Actually log out
    ref.read(authNotifierProvider.notifier).logout();
    
    // Let the router redirect to splash/login automatically
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            AppCard(
              color: colorScheme.error.withValues(alpha: 0.1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deleting your account is permanent. You will lose access to all your health data, reports, and insights.',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'What will be deleted:'),
            const SizedBox(height: 12),
            _BulletPoint(text: 'All uploaded lab reports and analyses'),
            _BulletPoint(text: 'Personal health timeline and tracking data'),
            _BulletPoint(text: 'Medication schedules and reminders'),
            _BulletPoint(text: 'Account settings and preferences'),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Verify Password',
              controller: _passwordCtrl,
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _isConfirmed,
                  onChanged: (v) {
                    setState(() => _isConfirmed = v ?? false);
                  },
                  activeColor: colorScheme.error,
                ),
                const Expanded(
                  child: Text(
                    'I understand this cannot be undone',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isConfirmed && _passwordCtrl.text.isNotEmpty && !_isLoading) 
                    ? _deleteAccount 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  disabledBackgroundColor: colorScheme.error.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 24, height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Delete My Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                label: 'Cancel',
                onPressed: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

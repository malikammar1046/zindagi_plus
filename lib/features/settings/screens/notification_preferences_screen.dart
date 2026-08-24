import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/supabase_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends ConsumerState<NotificationPreferencesScreen> {
  bool _medReminders = true;
  bool _weeklyReviews = true;
  bool _reportAnalysis = true;
  bool _healthInsights = false;
  bool _promotions = false;
  bool _isSaving = false;
  
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final res = await client
          .from('user_notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _medReminders = (res['med_reminders'] as bool?) ?? true;
          _weeklyReviews = (res['weekly_reviews'] as bool?) ?? true;
          _reportAnalysis = (res['report_analysis'] as bool?) ?? true;
          _healthInsights = (res['health_insights'] as bool?) ?? false;
          _promotions = (res['promotions'] as bool?) ?? false;

          final qs = res['quiet_start'] as String?;
          if (qs != null && qs.contains(':')) {
            final parts = qs.split(':');
            _quietStart = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 22,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }

          final qe = res['quiet_end'] as String?;
          if (qe != null && qe.contains(':')) {
            final parts = qe.split(':');
            _quietEnd = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 7,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[NotificationPreferencesScreen] Could not load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;

      if (userId != null) {
        final qs = '${_quietStart.hour.toString().padLeft(2, '0')}:${_quietStart.minute.toString().padLeft(2, '0')}:00';
        final qe = '${_quietEnd.hour.toString().padLeft(2, '0')}:${_quietEnd.minute.toString().padLeft(2, '0')}:00';

        await client.from('user_notification_settings').upsert({
          'user_id': userId,
          'med_reminders': _medReminders,
          'weekly_reviews': _weeklyReviews,
          'report_analysis': _reportAnalysis,
          'health_insights': _healthInsights,
          'promotions': _promotions,
          'quiet_start': qs,
          'quiet_end': qe,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _quietStart = picked;
        } else {
          _quietEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        leading: const AppBackButton(fallbackLocation: '/settings'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Local Reminders: Medicine notifications are scheduled on this device. Quiet hours are saved to your profile for background sync.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Push Notifications',
                    subtitle: 'Choose what you want to be notified about.',
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSwitch(
                          'Medication Reminders',
                          _medReminders,
                          (v) => setState(() => _medReminders = v),
                        ),
                        const Divider(height: 1),
                        _buildSwitch(
                          'Weekly Reviews',
                          _weeklyReviews,
                          (v) => setState(() => _weeklyReviews = v),
                        ),
                        const Divider(height: 1),
                        _buildSwitch(
                          'Report Analysis Updates',
                          _reportAnalysis,
                          (v) => setState(() => _reportAnalysis = v),
                        ),
                        const Divider(height: 1),
                        _buildSwitch(
                          'Health Insights',
                          _healthInsights,
                          (v) => setState(() => _healthInsights = v),
                        ),
                        const Divider(height: 1),
                        _buildSwitch(
                          'Promotions & Offers',
                          _promotions,
                          (v) => setState(() => _promotions = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'Quiet Hours',
                    subtitle: 'Notifications will be muted during this time.',
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Start Time'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _quietStart.format(context),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _pickTime(true),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('End Time'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _quietEnd.format(context),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _pickTime(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sticky Save Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: PrimaryButton(
                text: _isSaving ? 'Saving...' : 'Save Preferences',
                onPressed: _isSaving ? null : _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _medReminders = true;
  bool _weeklyReviews = true;
  bool _reportAnalysis = true;
  bool _healthInsights = false;
  bool _promotions = false;
  
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

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
                text: 'Save Preferences',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences saved')),
                  );
                  context.pop();
                },
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

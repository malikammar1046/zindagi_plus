import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class MedicationHistoryScreen extends ConsumerWidget {
  const MedicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose History'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: FutureBuilder<Result<List<DoseLog>>>(
        future: ref.read(medicationRepositoryProvider).getDoseHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const ErrorStateWidget(message: 'Could not load history.');
          }

          final result = snapshot.data!;
          return switch (result) {
            Failure(message: final m) =>
              ErrorStateWidget(message: m),
            Success(data: final logs) => logs.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.history_rounded,
                    title: 'No History Yet',
                    subtitle:
                        'Your dose logs will appear here once you start tracking.',
                  )
                : _LogList(logs: logs),
          };
        },
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.logs});
  final List<DoseLog> logs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    String? lastDate;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: logs.length,
      itemBuilder: (context, i) {
        final log = logs[i];
        final dateLabel = _dateLabel(log.loggedAt);
        final showHeader = dateLabel != lastDate;
        lastDate = dateLabel;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            _LogTile(log: log),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${_month(dt.month)} ${dt.day}, ${dt.year}';
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final DoseLog log;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (log.status) {
      MedStatus.taken => colorScheme.primary,
      MedStatus.missed => colorScheme.error,
      MedStatus.pending => Colors.orange,
    };
    final icon = switch (log.status) {
      MedStatus.taken => Icons.check_circle_rounded,
      MedStatus.missed => Icons.cancel_rounded,
      MedStatus.pending => Icons.schedule_rounded,
    };
    final label = switch (log.status) {
      MedStatus.taken => 'Taken',
      MedStatus.missed => 'Missed',
      MedStatus.pending => 'Pending',
    };

    final h = log.loggedAt.hour > 12
        ? log.loggedAt.hour - 12
        : log.loggedAt.hour;
    final m = log.loggedAt.minute.toString().padLeft(2, '0');
    final period = log.loggedAt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:$m $period';

    final displaySubtitle = log.scheduledTime != null && log.scheduledTime!.isNotEmpty
        ? '${log.dose} • Sched: ${log.scheduledTime!.split('—').first.trim()}'
        : log.dose;

    final statusSubtitle = switch (log.status) {
      MedStatus.taken => 'Taken $timeStr',
      MedStatus.missed => 'Missed $timeStr',
      MedStatus.pending => 'Scheduled $timeStr',
    };

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicationName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displaySubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusSubtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


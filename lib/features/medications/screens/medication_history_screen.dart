import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class MedicationHistoryScreen extends ConsumerWidget {
  const MedicationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Medication History'),
          leading: const AppBackButton(fallbackLocation: '/medications'),
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.history_rounded, size: 18),
                text: 'Dose History',
              ),
              Tab(
                icon: Icon(Icons.archive_outlined, size: 18),
                text: 'Past Prescriptions',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DoseHistoryTab(ref: ref),
            _PastMedicationsTab(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _DoseHistoryTab extends StatelessWidget {
  const _DoseHistoryTab({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<DoseLog>>>(
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
                  title: 'No Dose History Yet',
                  subtitle:
                      'Your dose logs will appear here once you start tracking.',
                )
              : _LogList(logs: logs),
        };
      },
    );
  }
}

class _PastMedicationsTab extends StatelessWidget {
  const _PastMedicationsTab({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final medState = ref.watch(medicationProvider);

    return medState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (allMeds) {
        final pastMeds = allMeds.where((m) => !m.isActive).toList();

        if (pastMeds.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'No Discontinued Medications',
            subtitle:
                'Discontinued medications will appear here with all historical records preserved.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: pastMeds.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final med = pastMeds[i];
            return AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                med.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              med.dose,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          med.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        if (med.note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            med.note,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Discontinued',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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


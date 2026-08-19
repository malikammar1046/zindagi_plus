import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/providers/report_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportHistoryScreen extends ConsumerWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        leading: const AppBackButton(fallbackLocation: '/upload'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportHistoryProvider),
        ),
        data: (reports) => reports.isEmpty
            ? EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'No Reports Yet',
                subtitle:
                    'Upload your first lab report to see it appear here.',
                actionLabel: 'Upload Report',
                onAction: () => context.go('/upload'),
              )
            : _ReportList(reports: reports),
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({required this.reports});
  final List<LabReport> reports;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ReportCard(report: reports[i]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final LabReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = _formatDate(report.uploadedAt);

    final (statusLabel, statusColor) = switch (report.status) {
      ReportStatus.completed => ('Completed', colorScheme.primary),
      ReportStatus.processing => ('Processing', Colors.orange),
      ReportStatus.failed => ('Failed', colorScheme.error),
      ReportStatus.uploaded => ('Uploaded', Colors.blue),
    };

    final subtitleText = report.isFailed
        ? 'OCR text extraction failed · Tap to retry'
        : report.hasExtractedText
            ? '${report.extractedText.length} chars extracted · ${report.biomarkerCount > 0 ? "${report.biomarkerCount} biomarkers" : "Raw OCR ready"}'
            : 'Processing document...';

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(
        '/upload/result',
        extra: {'reportId': report.id, 'fileName': report.fileName},
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              report.isFailed
                  ? Icons.error_outline_rounded
                  : Icons.document_scanner_outlined,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: report.isFailed
                        ? colorScheme.error
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status + chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/providers/report_providers.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    this.reportId,
    this.fileName,
  });

  final String? reportId;
  final String? fileName;

  static const _biomarkers = <Map<String, dynamic>>[
    {
      'name': 'HbA1c',
      'value': '6.8%',
      'range': 'Normal: < 5.7%',
      'status': 'Borderline',
      'statusColor': Colors.orange,
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'LDL Cholesterol',
      'value': '130 mg/dL',
      'range': 'Optimal: < 100 mg/dL',
      'status': 'High',
      'statusColor': Colors.red,
      'icon': Icons.monitor_heart_outlined,
    },
    {
      'name': 'HDL Cholesterol',
      'value': '55 mg/dL',
      'range': 'Healthy: > 40 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.favorite_outline_rounded,
    },
    {
      'name': 'Triglycerides',
      'value': '148 mg/dL',
      'range': 'Normal: < 150 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.science_outlined,
    },
    {
      'name': 'Fasting Glucose',
      'value': '108 mg/dL',
      'range': 'Normal: 70–99 mg/dL',
      'status': 'Borderline',
      'statusColor': Colors.orange,
      'icon': Icons.opacity_rounded,
    },
    {
      'name': 'Vitamin D',
      'value': '18 ng/mL',
      'range': 'Normal: 20–50 ng/mL',
      'status': 'Low',
      'statusColor': Colors.red,
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'name': 'Haemoglobin',
      'value': '14.2 g/dL',
      'range': 'Normal: 13.5–17.5 g/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.bloodtype_outlined,
    },
    {
      'name': 'Creatinine',
      'value': '0.9 mg/dL',
      'range': 'Normal: 0.7–1.2 mg/dL',
      'status': 'Normal',
      'statusColor': Color(0xFF00674F),
      'icon': Icons.filter_alt_outlined,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId = reportId ?? 'report_001';
    final reportAsync = ref.watch(reportDetailProvider(effectiveId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Report Detail'),
        leading: const AppBackButton(fallbackLocation: '/upload'),
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildFallbackView(context, effectiveId),
        data: (report) => _buildDetailContent(context, report),
      ),
    );
  }

  Widget _buildFallbackView(BuildContext context, String effectiveId) {
    final fallbackReport = LabReport(
      id: effectiveId,
      fileName: fileName ?? 'Blood_Report_July_2025.jpg',
      uploadedAt: DateTime.now(),
      status: ReportStatus.completed,
      extractedText: MockOcrService.defaultSampleMedicalReportText,
      biomarkerCount: 8,
      attentionCount: 3,
      aiSummary: 'HbA1c borderline, LDL elevated, Vitamin D low.',
    );
    return _buildDetailContent(context, fallbackReport);
  }

  Widget _buildDetailContent(BuildContext context, LabReport report) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _SummaryCard(
          report: report,
          onExplain: () => context.push(
            '/upload/explanation',
            extra: {'reportId': report.id},
          ),
        ),
        const SizedBox(height: 16),

        // ── Extracted OCR Raw Text Section ───────────────────────────────────
        _ExtractedTextCard(report: report),
        const SizedBox(height: 20),

        // ── Biomarker Overview Section ───────────────────────────────────────
        _StatusCountsRow(biomarkers: _biomarkers),
        const SizedBox(height: 20),
        Text(
          'Biomarker Results (Preview)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        ..._biomarkers.map((b) => _BiomarkerCard(biomarker: b)),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Extracted OCR Text Card ──────────────────────────────────────────────────

class _ExtractedTextCard extends StatefulWidget {
  const _ExtractedTextCard({required this.report});
  final LabReport report;

  @override
  State<_ExtractedTextCard> createState() => _ExtractedTextCardState();
}

class _ExtractedTextCardState extends State<_ExtractedTextCard> {
  bool _copied = false;
  bool _expanded = true;

  void _copyToClipboard() {
    final text = widget.report.extractedText;
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Raw OCR text copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasText = widget.report.hasExtractedText;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extracted OCR Text',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Raw text recognized directly from the document',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasText)
                IconButton(
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: _copied ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  tooltip: 'Copy Raw Text',
                  onPressed: _copyToClipboard,
                ),
              IconButton(
                icon: Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                tooltip: _expanded ? 'Collapse' : 'Expand',
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),

          if (_expanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Medical Disclaimer: This is uninterpreted raw OCR text. No diagnostic claims have been applied.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable raw text container
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: SingleChildScrollView(
                child: hasText
                    ? SelectableText(
                        widget.report.extractedText,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      )
                    : Text(
                        widget.report.isFailed
                            ? 'OCR text extraction failed for this document. ${widget.report.errorMessage ?? ""}'
                            : 'No text extracted yet or report is still processing.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary Card Widget ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.report,
    required this.onExplain,
  });

  final LabReport report;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      color: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                report.isCompleted
                    ? Icons.assignment_turned_in_rounded
                    : report.isFailed
                        ? Icons.error_outline_rounded
                        : Icons.sync_rounded,
                color: colorScheme.onPrimary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                report.isCompleted
                    ? 'Report Processed'
                    : report.isFailed
                        ? 'Processing Failed'
                        : 'Processing...',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status.displayLabel,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            report.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${report.id}  ·  ${report.hasExtractedText ? "${report.extractedText.length} chars extracted" : "No text"}',
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onExplain,
            icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            label: const Text(
              'Explain in Simple Language',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Counts Row ────────────────────────────────────────────────────────

class _StatusCountsRow extends StatelessWidget {
  const _StatusCountsRow({required this.biomarkers});
  final List<Map<String, dynamic>> biomarkers;

  @override
  Widget build(BuildContext context) {
    int normal = 0, borderline = 0, abnormal = 0;
    for (final b in biomarkers) {
      final s = b['status'] as String;
      if (s == 'Normal') {
        normal++;
      } else if (s == 'Borderline') {
        borderline++;
      } else {
        abnormal++;
      }
    }

    return Row(
      children: [
        _CountChip(count: normal, label: 'Normal', color: const Color(0xFF00674F)),
        const SizedBox(width: 10),
        _CountChip(count: borderline, label: 'Borderline', color: Colors.orange),
        const SizedBox(width: 10),
        _CountChip(count: abnormal, label: 'Abnormal', color: Colors.red),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Biomarker Card ──────────────────────────────────────────────────────────

class _BiomarkerCard extends StatelessWidget {
  const _BiomarkerCard({required this.biomarker});
  final Map<String, dynamic> biomarker;

  @override
  Widget build(BuildContext context) {
    final statusColor = biomarker['statusColor'] as Color;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              biomarker['icon'] as IconData,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biomarker['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  biomarker['range'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                biomarker['value'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  biomarker['status'] as String,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

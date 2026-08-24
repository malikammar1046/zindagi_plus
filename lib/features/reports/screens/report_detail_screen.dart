import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/providers/report_providers.dart';
import 'package:zindagi_plus/services/lab_report_parser.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({
    super.key,
    this.reportId,
    this.fileName,
  });

  final String? reportId;
  final String? fileName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reportId == null || reportId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lab Report Detail'),
          leading: const AppBackButton(fallbackLocation: '/upload'),
        ),
        body: Center(
          child: ErrorStateWidget(
            message: 'No report ID was provided.',
            onRetry: () => context.go('/upload'),
          ),
        ),
      );
    }

    final effectiveId = reportId!;
    final reportAsync = ref.watch(reportDetailProvider(effectiveId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Report Detail'),
        leading: const AppBackButton(fallbackLocation: '/upload'),
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorStateWidget(
              message: 'Unable to load report.\n$e',
              onRetry: () => ref.invalidate(reportDetailProvider(effectiveId)),
            ),
          ),
        ),
        data: (report) => _buildDetailContent(context, ref, report),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, WidgetRef ref, LabReport report) {
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

        // ── Important Health Parameters Section (ABOVE Raw OCR Text) ─────────
        _ImportantHealthParametersCard(report: report),
        const SizedBox(height: 16),

        // ── Extracted OCR Raw Text Section (Below) ───────────────────────────
        _ExtractedTextCard(report: report),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Important Health Parameters Card ─────────────────────────────────────────

class _ImportantHealthParametersCard extends ConsumerWidget {
  const _ImportantHealthParametersCard({required this.report});
  final LabReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Load from database if persisted; fallback to parsing extractedText directly.
    final biomarkersAsync = ref.watch(reportBiomarkersProvider(report.id));

    return biomarkersAsync.when(
      loading: () => _buildCard(
        context,
        colorScheme,
        _resolveBiomarkers(null),
        isLoading: true,
      ),
      error: (e, _) => _buildCard(
        context,
        colorScheme,
        _resolveBiomarkers(null),
      ),
      data: (dbBiomarkers) => _buildCard(
        context,
        colorScheme,
        _resolveBiomarkers(dbBiomarkers),
      ),
    );
  }

  List<ParsedBiomarker> _resolveBiomarkers(List<ParsedBiomarker>? dbList) {
    if (dbList != null && dbList.isNotEmpty) {
      return dbList;
    }
    if (report.hasExtractedText) {
      return LabReportParser.parse(report.extractedText);
    }
    return [];
  }

  Widget _buildCard(
    BuildContext context,
    ColorScheme colorScheme,
    List<ParsedBiomarker> biomarkers, {
    bool isLoading = false,
  }) {
    final hasParameters = biomarkers.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.biotech_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Health Parameters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasParameters
                          ? '${biomarkers.length} parameter${biomarkers.length == 1 ? "" : "s"} extracted'
                          : (report.isFailed
                              ? 'OCR extraction failed'
                              : 'No parameters found'),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          if (hasParameters) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: biomarkers.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, thickness: 0.5),
              ),
              itemBuilder: (ctx, index) {
                final bm = biomarkers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bm.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bm.value % 1 == 0
                                ? bm.value.toInt().toString()
                                : bm.value.toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          if (bm.unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              bm.unit,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No recognizable laboratory parameters were found. Please upload a clearer report image.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = widget.report.hasExtractedText;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Extracted OCR Text',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasText
                                ? const Color(0xFF00674F).withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            hasText ? 'ML Kit OCR' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: hasText ? const Color(0xFF00674F) : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasText
                          ? '${widget.report.extractedText.length} characters extracted from scan'
                          : 'No text extracted',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasText)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy text',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.report.extractedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Raw OCR text copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: Icon(
                  _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20,
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
              Expanded(
                child: Text(
                  report.isCompleted
                      ? 'Report Processed'
                      : report.isFailed
                          ? 'Processing Failed'
                          : 'Processing...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
          OutlinedButton(
            onPressed: onExplain,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
              foregroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Explain Report',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a processed lab report entry.
///
/// This is a temporary mock model. Field names do NOT represent the final
/// PostgreSQL/Supabase schema.
class LabReport {
  const LabReport({
    required this.reportId,
    required this.fileName,
    required this.uploadedAt,
    required this.status,
    required this.biomarkerCount,
    required this.attentionCount,
    required this.summary,
  });

  final String reportId;
  final String fileName;
  final DateTime uploadedAt;
  final ReportStatus status;
  final int biomarkerCount;
  final int attentionCount;
  final String summary;
}

enum ReportStatus { processed, processing, failed }

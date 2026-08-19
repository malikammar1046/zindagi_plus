import 'package:flutter/foundation.dart';

/// Status of a medical lab report throughout its upload & OCR lifecycle.
enum ReportStatus {
  uploaded,
  processing,
  completed,
  failed;

  /// Parses a raw string from PostgreSQL / Supabase into a [ReportStatus].
  static ReportStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'uploaded' => ReportStatus.uploaded,
      'processing' => ReportStatus.processing,
      'completed' || 'processed' => ReportStatus.completed,
      'failed' => ReportStatus.failed,
      _ => ReportStatus.uploaded,
    };
  }

  /// Maps enum value to standard PostgreSQL column value.
  String toDbString() {
    return switch (this) {
      ReportStatus.uploaded => 'uploaded',
      ReportStatus.processing => 'processing',
      ReportStatus.completed => 'completed',
      ReportStatus.failed => 'failed',
    };
  }

  /// User-friendly status label.
  String get displayLabel {
    return switch (this) {
      ReportStatus.uploaded => 'Uploaded',
      ReportStatus.processing => 'Processing',
      ReportStatus.completed => 'Completed',
      ReportStatus.failed => 'Failed',
    };
  }
}

/// Represents a medical lab report document and its OCR text extraction result.
@immutable
class LabReport {
  const LabReport({
    required this.id,
    required this.fileName,
    required this.uploadedAt,
    this.userId,
    this.storagePath = '',
    this.fileSizeBytes,
    this.mimeType,
    this.status = ReportStatus.uploaded,
    this.extractedText = '',
    this.aiSummary = '',
    this.errorMessage,
    this.processedAt,
    this.biomarkerCount = 0,
    this.attentionCount = 0,
  });

  /// Primary key UUID of the report record.
  final String id;

  /// User ID owning this report.
  final String? userId;

  /// Original file name as uploaded by the user.
  final String fileName;

  /// Path in the private Supabase Storage 'reports' bucket.
  final String storagePath;

  /// Size of the original uploaded file in bytes.
  final int? fileSizeBytes;

  /// MIME type of the uploaded file (e.g. image/jpeg, image/png, application/pdf).
  final String? mimeType;

  /// Current processing status.
  final ReportStatus status;

  /// Raw, uninterpreted OCR text extracted directly from the document.
  final String extractedText;

  /// Optional AI summary generated in downstream analysis.
  final String aiSummary;

  /// Safe diagnostic error message if processing failed.
  final String? errorMessage;

  /// Timestamp when the original document was uploaded.
  final DateTime uploadedAt;

  /// Timestamp when OCR / processing completed or failed.
  final DateTime? processedAt;

  /// Number of parsed biomarker measurements (for future analysis integration).
  final int biomarkerCount;

  /// Number of biomarkers outside standard reference ranges.
  final int attentionCount;

  // ── Backward-compatible accessors ──────────────────────────────────────────

  /// Alias for [id] to preserve existing screen references.
  String get reportId => id;

  /// Alias for [aiSummary] to preserve existing screen references.
  String get summary => aiSummary;

  /// Returns true if OCR has successfully extracted text.
  bool get hasExtractedText => extractedText.trim().isNotEmpty;

  /// Returns true if processing completed.
  bool get isCompleted => status == ReportStatus.completed;

  /// Returns true if processing is currently in flight.
  bool get isProcessing => status == ReportStatus.processing;

  /// Returns true if processing failed.
  bool get isFailed => status == ReportStatus.failed;

  // ── Serialization ──────────────────────────────────────────────────────────

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      id: json['id'] as String? ?? json['reportId'] as String? ?? '',
      userId: json['user_id'] as String?,
      fileName: json['file_name'] as String? ?? json['fileName'] as String? ?? 'Unnamed Report',
      storagePath: json['storage_path'] as String? ?? json['storagePath'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] ?? json['fileSizeBytes']) as int?,
      mimeType: json['mime_type'] as String? ?? json['mimeType'] as String?,
      status: ReportStatus.fromString(json['status'] as String?),
      extractedText: json['extracted_text'] as String? ?? json['extractedText'] as String? ?? '',
      aiSummary: json['ai_summary'] as String? ?? json['summary'] as String? ?? '',
      errorMessage: json['error_message'] as String? ?? json['processing_error'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String)?.toLocal() ?? DateTime.now()
          : (json['uploadedAt'] is DateTime ? json['uploadedAt'] as DateTime : DateTime.now()),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'] as String)?.toLocal()
          : (json['processedAt'] is DateTime ? json['processedAt'] as DateTime : null),
      biomarkerCount: (json['biomarker_count'] ?? json['biomarkerCount'] ?? 0) as int,
      attentionCount: (json['attention_count'] ?? json['attentionCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'file_name': fileName,
      'storage_path': storagePath,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      'status': status.toDbString(),
      'extracted_text': extractedText,
      'ai_summary': aiSummary,
      if (errorMessage != null) 'error_message': errorMessage,
      'uploaded_at': uploadedAt.toUtc().toIso8601String(),
      if (processedAt != null) 'processed_at': processedAt!.toUtc().toIso8601String(),
      'biomarker_count': biomarkerCount,
      'attention_count': attentionCount,
    };
  }

  LabReport copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? storagePath,
    int? fileSizeBytes,
    String? mimeType,
    ReportStatus? status,
    String? extractedText,
    String? aiSummary,
    String? errorMessage,
    DateTime? uploadedAt,
    DateTime? processedAt,
    int? biomarkerCount,
    int? attentionCount,
  }) {
    return LabReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      extractedText: extractedText ?? this.extractedText,
      aiSummary: aiSummary ?? this.aiSummary,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      processedAt: processedAt ?? this.processedAt,
      biomarkerCount: biomarkerCount ?? this.biomarkerCount,
      attentionCount: attentionCount ?? this.attentionCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabReport &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          fileName == other.fileName &&
          storagePath == other.storagePath &&
          fileSizeBytes == other.fileSizeBytes &&
          mimeType == other.mimeType &&
          status == other.status &&
          extractedText == other.extractedText &&
          aiSummary == other.aiSummary &&
          errorMessage == other.errorMessage &&
          uploadedAt == other.uploadedAt &&
          processedAt == other.processedAt &&
          biomarkerCount == other.biomarkerCount &&
          attentionCount == other.attentionCount;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        fileName,
        storagePath,
        fileSizeBytes,
        mimeType,
        status,
        extractedText,
        aiSummary,
        errorMessage,
        uploadedAt,
        processedAt,
        biomarkerCount,
        attentionCount,
      );

  @override
  String toString() {
    return 'LabReport(id: $id, fileName: $fileName, status: ${status.name}, extractedTextLength: ${extractedText.length})';
  }
}

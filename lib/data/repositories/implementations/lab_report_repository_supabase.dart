import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/repositories/interfaces/lab_report_repository.dart';
import 'package:zindagi_plus/services/lab_report_parser.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Real Supabase implementation of [LabReportRepository].
///
/// Security & Architecture:
/// - Strictly scoped to `auth.uid()` via Row Level Security (RLS) policies and explicit `.eq('user_id', userId)` queries.
/// - Original medical document files are stored in the private 'reports' bucket under `{user_id}/{timestamp}_{file_name}`.
/// - OCR text extraction runs via the injected [OcrService] without medical interpretation.
/// - On OCR failure, the original document is permanently preserved in storage, status is set to [ReportStatus.failed], and safe retry is supported.
class LabReportRepositorySupabase implements LabReportRepository {
  LabReportRepositorySupabase(this._client, this._ocrService);

  final supa.SupabaseClient _client;
  final OcrService _ocrService;

  // ── Authentication Validation ──────────────────────────────────────────────

  Result<String> _validateAuth(String operation) {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    if (session == null || user == null || user.id.isEmpty) {
      debugPrint('[LabReportRepositorySupabase.$operation] BLOCKED: No active session.');
      return const Failure('You must be logged in to access medical reports.');
    }

    if (session.isExpired) {
      debugPrint('[LabReportRepositorySupabase.$operation] BLOCKED: Session is expired.');
      return const Failure('Your session has expired. Please log in again.');
    }

    return Success(user.id);
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  // ── Upload Original Report ──────────────────────────────────────────────────

  @override
  Future<Result<LabReport>> uploadReport({
    required String filePath,
    required String fileName,
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    final authCheck = _validateAuth('uploadReport');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Failure('Report file does not exist at path: $filePath');
      }

      final actualSize = fileSizeBytes ?? file.lengthSync();
      final sanitizedName = _sanitizeFileName(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/${timestamp}_$sanitizedName';

      // 1. Upload original document to private Supabase Storage bucket
      try {
        await _client.storage.from('reports').upload(
              storagePath,
              file,
              fileOptions: supa.FileOptions(
                contentType: mimeType ?? _guessMimeType(fileName),
                upsert: false,
              ),
            );
      } catch (storageError, storageStack) {
        _logDbError('uploadReport.storage', storageError, storageStack);
        return Failure('Failed to upload report to secure storage: ${_mapDbError(storageError)}');
      }

      // 2. Insert metadata record in PostgreSQL lab_reports table with status 'uploaded'
      final insertPayload = {
        'user_id': userId,
        'file_name': fileName,
        'storage_path': storagePath,
        'file_size_bytes': actualSize,
        'mime_type': mimeType ?? _guessMimeType(fileName),
        'status': ReportStatus.uploaded.toDbString(),
        'extracted_text': '',
        'ai_summary': '',
        'uploaded_at': DateTime.now().toUtc().toIso8601String(),
      };

      try {
        final response = await _client
            .from('lab_reports')
            .insert(insertPayload)
            .select()
            .single();

        final createdReport = LabReport.fromJson(response);
        return Success(createdReport);
      } catch (dbError, dbStack) {
        _logDbError('uploadReport.insert', dbError, dbStack);
        // Clean up orphaned storage object to avoid leaving unreferenced medical files
        try {
          await _client.storage.from('reports').remove([storagePath]);
        } catch (_) {}
        return Failure('Failed to create report record: ${_mapDbError(dbError)}');
      }
    } catch (e, stack) {
      _logDbError('uploadReport.unexpected', e, stack);
      return Failure('Failed to upload report: ${_mapDbError(e)}');
    }
  }

  // ── Process Report with OCR ─────────────────────────────────────────────────

  @override
  Future<Result<LabReport>> processReport(String reportId, String filePath) async {
    final authCheck = _validateAuth('processReport');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    File? tempDownloadedFile;
    try {
      String effectivePath = filePath;

      // If local file is missing, download original file from Supabase Storage
      if (effectivePath.isEmpty || !File(effectivePath).existsSync()) {
        debugPrint('[OCR] Local file at "$filePath" not found. Downloading from Supabase Storage...');
        try {
          final reportRow = await _client
              .from('lab_reports')
              .select('storage_path, file_name')
              .eq('id', reportId)
              .eq('user_id', userId)
              .single();

          final storagePath = reportRow['storage_path'] as String;
          final fileName = reportRow['file_name'] as String? ?? 'report.jpg';
          final fileBytes = await _client.storage.from('reports').download(storagePath);

          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/ocr_${reportId}_$fileName');
          await tempFile.writeAsBytes(fileBytes);
          effectivePath = tempFile.path;
          tempDownloadedFile = tempFile;
          debugPrint('[OCR] Downloaded storage file to temp path: $effectivePath (${fileBytes.length} bytes)');
        } catch (downloadErr, downloadStack) {
          _logDbError('processReport.storageDownload', downloadErr, downloadStack);
          return Failure('Could not retrieve uploaded report file for OCR: ${_mapDbError(downloadErr)}');
        }
      }

      // 1. Update status to 'processing'
      try {
        await _client.from('lab_reports').update({
          'status': ReportStatus.processing.toDbString(),
        }).eq('id', reportId).eq('user_id', userId);
      } catch (dbUpdateError, dbUpdateStack) {
        _logDbError('processReport.setProcessing', dbUpdateError, dbUpdateStack);
        return Failure('Failed to update report status: ${_mapDbError(dbUpdateError)}');
      }

      // 2. Run OCR text extraction via dedicated OcrService (MlKitOcrService on Android)
      final ocrResult = await _ocrService.extractText(effectivePath);

      if (ocrResult is Success<String>) {
        final extractedRawText = ocrResult.data;

        debugPrint('[OCR] Text returned by ML Kit: ${extractedRawText.length} chars');
        debugPrint('[OCR] Text being saved to database: ${extractedRawText.length} chars');

        // 3a. Save exact raw OCR text & update status to 'completed'
        try {
          final updateResponse = await _client
              .from('lab_reports')
              .update({
                'status': ReportStatus.completed.toDbString(),
                'extracted_text': extractedRawText,
                'processed_at': DateTime.now().toUtc().toIso8601String(),
                'error_message': null,
                'biomarker_count': 0,
              })
              .eq('id', reportId)
              .eq('user_id', userId)
              .select()
              .single();

          debugPrint('[OCR] Processing completed successfully for report ID: $reportId (${extractedRawText.length} chars saved to database)');
          return Success(LabReport.fromJson(updateResponse));
        } catch (dbCompleteError, dbCompleteStack) {
          _logDbError('processReport.saveExtractedText', dbCompleteError, dbCompleteStack);
          return Failure('Failed to save extracted text: ${_mapDbError(dbCompleteError)}');
        }
      } else {
        final errorMessage = (ocrResult as Failure<String>).message;
        debugPrint('[OCR] ML Kit extraction failed for report ID $reportId: $errorMessage');

        // 3b. OCR Failure -> update status to 'failed', preserve original file, do NOT use mock fallback
        try {
          await _client
              .from('lab_reports')
              .update({
                'status': ReportStatus.failed.toDbString(),
                'error_message': errorMessage,
                'processed_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', reportId)
              .eq('user_id', userId);
        } catch (dbFailError, dbFailStack) {
          _logDbError('processReport.markFailed', dbFailError, dbFailStack);
        }

        return Failure(errorMessage);
      }
    } catch (e, stack) {
      _logDbError('processReport.unexpected', e, stack);
      debugPrint('[OCR] Unexpected processing error for report ID $reportId: ${_mapDbError(e)}');
      // Mark as failed in DB on uncaught exception
      try {
        await _client.from('lab_reports').update({
          'status': ReportStatus.failed.toDbString(),
          'error_message': 'System error during document processing.',
          'processed_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', reportId).eq('user_id', userId);
      } catch (_) {}

      return Failure('Report processing failed: ${_mapDbError(e)}');
    } finally {
      if (tempDownloadedFile != null && tempDownloadedFile.existsSync()) {
        try {
          await tempDownloadedFile.delete();
        } catch (_) {}
      }
    }
  }

  // ── Retry Processing ────────────────────────────────────────────────────────

  @override
  Future<Result<LabReport>> retryProcessing(String reportId, {String? filePath}) async {
    final authCheck = _validateAuth('retryProcessing');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    File? tempFileToClean;
    try {
      String localFilePath = filePath ?? '';

      // If no local file path was given or file doesn't exist, download from Supabase Storage
      if (localFilePath.isEmpty || !File(localFilePath).existsSync()) {
        final reportRow = await _client
            .from('lab_reports')
            .select('storage_path, file_name')
            .eq('id', reportId)
            .eq('user_id', userId)
            .single();

        final storagePath = reportRow['storage_path'] as String;
        final fileName = reportRow['file_name'] as String? ?? 'report.jpg';

        final fileBytes = await _client.storage.from('reports').download(storagePath);
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/retry_${reportId}_$fileName');
        await tempFile.writeAsBytes(fileBytes);
        localFilePath = tempFile.path;
        tempFileToClean = tempFile;
      }

      return await processReport(reportId, localFilePath);
    } catch (e, stack) {
      _logDbError('retryProcessing', e, stack);
      return Failure('Could not retry report processing: ${_mapDbError(e)}');
    } finally {
      if (tempFileToClean != null && tempFileToClean.existsSync()) {
        try {
          await tempFileToClean.delete();
        } catch (_) {}
      }
    }
  }

  // ── Read Single Report ──────────────────────────────────────────────────────

  @override
  Future<Result<LabReport>> getReportById(String reportId) async {
    final authCheck = _validateAuth('getReportById');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    try {
      final response = await _client
          .from('lab_reports')
          .select()
          .eq('id', reportId)
          .eq('user_id', userId)
          .single();

      return Success(LabReport.fromJson(response));
    } catch (e) {
      debugPrint('[LabReportRepositorySupabase.getReportById] Error: $e');
      return Failure('Report not found or unavailable.');
    }
  }

  // ── Read Report History ─────────────────────────────────────────────────────

  @override
  Future<Result<List<LabReport>>> getReportHistory() async {
    final authCheck = _validateAuth('getReportHistory');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    try {
      final rows = await _client
          .from('lab_reports')
          .select()
          .eq('user_id', userId)
          .order('uploaded_at', ascending: false);

      final reports = (rows as List<dynamic>)
          .map((row) => LabReport.fromJson(row as Map<String, dynamic>))
          .toList();

      return Success(reports);
    } catch (e, stack) {
      _logDbError('getReportHistory', e, stack);
      return Failure('Failed to load report history: ${_mapDbError(e)}');
    }
  }

  // ── Secure Storage Signed URL ───────────────────────────────────────────────

  @override
  Future<Result<String>> getReportFileSignedUrl(String storagePath) async {
    final authCheck = _validateAuth('getReportFileSignedUrl');
    if (authCheck is Failure<String>) return Failure(authCheck.message);

    try {
      // Create a 1-hour secure signed URL
      final signedUrl = await _client.storage.from('reports').createSignedUrl(
            storagePath,
            3600,
          );
      return Success(signedUrl);
    } catch (e) {
      debugPrint('[LabReportRepositorySupabase.getReportFileSignedUrl] Error: $e');
      return Failure('Could not generate secure document preview URL.');
    }
  }

  // ── Biomarkers ──────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> saveBiomarkers(
    String reportId,
    String userId,
    List<ParsedBiomarker> biomarkers,
  ) async {
    if (biomarkers.isEmpty) return const Success(null);
    try {
      final rows = biomarkers.map((b) => {
        'report_id': reportId,
        'user_id': userId,
        'biomarker_name': b.name,
        'measured_value': b.value.toString(),
        'numeric_value': b.value,
        'unit': b.unit,
        'reference_range': '',
        'status': 'normal',
      }).toList();

      await _client.from('report_biomarkers').insert(rows);
      debugPrint('[Biomarkers] Saved ${rows.length} biomarker(s) for report $reportId');
      return const Success(null);
    } catch (e, st) {
      _logDbError('saveBiomarkers', e, st);
      return Failure('Failed to save biomarkers: ${_mapDbError(e)}');
    }
  }

  @override
  Future<Result<List<ParsedBiomarker>>> getBiomarkers(String reportId) async {
    final authCheck = _validateAuth('getBiomarkers');
    if (authCheck is Failure<String>) return Failure(authCheck.message);
    final userId = (authCheck as Success<String>).data;

    try {
      final rows = await _client
          .from('report_biomarkers')
          .select('biomarker_name, numeric_value, unit')
          .eq('report_id', reportId)
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      final biomarkers = (rows as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        return ParsedBiomarker(
          name: m['biomarker_name'] as String? ?? '',
          value: (m['numeric_value'] as num?)?.toDouble() ?? 0.0,
          unit: m['unit'] as String? ?? '',
        );
      }).toList();

      return Success(biomarkers);
    } catch (e, st) {
      _logDbError('getBiomarkers', e, st);
      return Failure('Failed to load biomarkers: ${_mapDbError(e)}');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _guessMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  void _logDbError(String operation, Object error, StackTrace st) {
    if (error is supa.PostgrestException) {
      debugPrint('[LabReportRepositorySupabase.$operation] PostgrestException:');
      debugPrint('  - Code: ${error.code}');
      debugPrint('  - Message: ${error.message}');
      debugPrint('  - Details: ${error.details}');
      debugPrint('  - Hint: ${error.hint}');
    } else {
      debugPrint('[LabReportRepositorySupabase.$operation] Error: $error\n$st');
    }
  }

  String _mapDbError(Object error) {
    if (error is supa.PostgrestException) {
      return 'Database error [${error.code}]: ${error.message}';
    }
    final s = error.toString();
    if (s.contains('SocketException') || s.contains('NetworkException')) {
      return 'Network error. Please check your internet connection.';
    }
    if (s.contains('Row not found') || s.contains('0 rows')) {
      return 'Report record not found.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

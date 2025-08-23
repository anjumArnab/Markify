// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../model/academic_record.dart';
import '/theme.dart';

class DownloadService {
  static const String sheetId = "13xvatsDfRosUn3aThl4ZrEUNmoUclCoX4w-qTf40D4w";
  static const String sheetUrl =
      "https://docs.google.com/spreadsheets/d/$sheetId";

  /// Download records as CSV
  static Future<void> downloadAsCSV(
      BuildContext context, List<AcademicRecord> records) async {
    try {
      _showLoadingDialog(context, 'Generating CSV file...');

      // Request storage permission
      final permission = await _requestStoragePermission();
      if (!permission) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context,
            'Storage permission is required to save files. Please grant permission in app settings.');
        return;
      }

      // Generate CSV content
      String csvContent = _generateCSV(records);

      // Save file
      final file = await _saveFile(csvContent, 'csv');

      Navigator.pop(context); // Close loading dialog

      if (file != null) {
        await _showSuccessDialog(context, file.path, 'CSV');
      } else {
        _showErrorDialog(context, 'Failed to save CSV file');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'CSV export failed: ${e.toString()}');
    }
  }

  /// Download records as JSON
  static Future<void> downloadAsJSON(
      BuildContext context, List<AcademicRecord> records) async {
    try {
      _showLoadingDialog(context, 'Generating JSON file...');

      // Request storage permission
      final permission = await _requestStoragePermission();
      if (!permission) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context,
            'Storage permission is required to save files. Please grant permission in app settings.');
        return;
      }

      // Generate JSON content
      String jsonContent = _generateJSON(records);

      // Save file
      final file = await _saveFile(jsonContent, 'json');

      Navigator.pop(context); // Close loading dialog

      if (file != null) {
        await _showSuccessDialog(context, file.path, 'JSON');
      } else {
        _showErrorDialog(context, 'Failed to save JSON file');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog(context, 'JSON export failed: ${e.toString()}');
    }
  }

  /// Open Google Sheet in browser
  static Future<void> openGoogleSheet(BuildContext context) async {
    try {
      final Uri url = Uri.parse('$sheetUrl/edit');

      // Check if URL can be launched
      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Google Sheet in browser...'),
              backgroundColor: AppTheme.accentColor,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (!launched && context.mounted) {
          _showErrorDialog(context,
              'Failed to open Google Sheet. Please check if you have a browser installed.');
        }
      } else {
        if (context.mounted) {
          // Fallback: copy link to clipboard and show instructions
          await Clipboard.setData(ClipboardData(text: '$sheetUrl/edit'));
          _showErrorDialog(context,
              'Cannot open browser automatically.\n\nThe Google Sheet link has been copied to your clipboard:\n$sheetUrl/edit\n\nPlease paste it in your browser.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        // Fallback: copy link to clipboard
        try {
          await Clipboard.setData(ClipboardData(text: '$sheetUrl/edit'));
          _showErrorDialog(context,
              'Cannot open browser automatically.\n\nThe Google Sheet link has been copied to your clipboard. Please paste it in your browser.\n\nError: ${e.toString()}');
        } catch (clipboardError) {
          _showErrorDialog(context,
              'Failed to open Google Sheet.\n\nPlease manually navigate to:\n$sheetUrl/edit\n\nError: ${e.toString()}');
        }
      }
    }
  }

  /// Copy Google Sheet link to clipboard
  static Future<void> copySheetLink(BuildContext context) async {
    try {
      const link = '$sheetUrl/edit';
      await Clipboard.setData(const ClipboardData(text: link));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sheet link copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to copy link: ${e.toString()}');
      }
    }
  }

  /// Export Google Sheet directly as CSV/Excel
  static Future<void> exportFromGoogleSheet(
      BuildContext context, String format) async {
    try {
      String exportUrl;
      String formatName;

      switch (format.toLowerCase()) {
        case 'csv':
          exportUrl = '$sheetUrl/export?format=csv';
          formatName = 'CSV';
          break;
        case 'xlsx':
          exportUrl = '$sheetUrl/export?format=xlsx';
          formatName = 'Excel';
          break;
        case 'pdf':
          exportUrl = '$sheetUrl/export?format=pdf';
          formatName = 'PDF';
          break;
        default:
          throw Exception('Unsupported format: $format');
      }

      final Uri url = Uri.parse(exportUrl);

      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Downloading $formatName file from Google Sheets...'),
              backgroundColor: AppTheme.accentColor,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (!launched && context.mounted) {
          _showFallbackExportDialog(context, exportUrl, formatName);
        }
      } else {
        if (context.mounted) {
          _showFallbackExportDialog(context, exportUrl, formatName);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Export failed: ${e.toString()}');
      }
    }
  }

  /// Show fallback dialog for export
  static void _showFallbackExportDialog(
      BuildContext context, String exportUrl, String formatName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $formatName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Cannot open download automatically. Please use one of these options:'),
            const SizedBox(height: 16),
            const Text('1. Copy the link and paste it in your browser:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(exportUrl,
                  style:
                      const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            Text(
                '2. Or open the Google Sheet directly and use File > Download > $formatName',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: exportUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download link copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  /// Request storage permission for public storage access
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+) - Request specific media permissions
        var photoStatus = await Permission.photos.status;
        var videoStatus = await Permission.videos.status;
        var audioStatus = await Permission.audio.status;

        if (!photoStatus.isGranted ||
            !videoStatus.isGranted ||
            !audioStatus.isGranted) {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();

          // Check if at least one permission is granted (we mainly need photos for documents)
          return statuses[Permission.photos]?.isGranted ?? false;
        }
        return true;
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12 (API 30-32) - Try MANAGE_EXTERNAL_STORAGE first
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }

        if (manageStatus.isGranted) {
          return true;
        }

        // Fallback to regular storage permission
        var storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        // Android 10 and below - Use regular storage permission
        var status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permission for documents
  }

  /// Save file to public Downloads directory
  static Future<File?> _saveFile(String content, String extension) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to save to public Downloads directory
        try {
          // First attempt: Direct access to Downloads folder
          directory = Directory('/storage/emulated/0/Download');

          if (!await directory.exists()) {
            // Fallback 1: Try Documents folder
            directory = Directory('/storage/emulated/0/Documents');

            if (!await directory.exists()) {
              // Fallback 2: Use getExternalStorageDirectory
              directory = await getExternalStorageDirectory();
              directory ??= await getApplicationDocumentsDirectory();
            }
          }
        } catch (e) {
          // If direct access fails, use app-specific directory
          directory = await getExternalStorageDirectory();
          directory ??= await getApplicationDocumentsDirectory();
        }
      } else {
        // iOS - Use app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'markify_academic_records_$timestamp.$extension';
      final file = File('${directory.path}/$fileName');

      // Write content to file
      await file.writeAsString(content, encoding: utf8);

      return file;
    } catch (e) {
      print('Error saving file: $e');

      // Final fallback: Try app-specific directory
      try {
        final fallbackDir = Platform.isAndroid
            ? await getExternalStorageDirectory() ??
                await getApplicationDocumentsDirectory()
            : await getApplicationDocumentsDirectory();

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'markify_academic_records_$timestamp.$extension';
        final fallbackFile = File('${fallbackDir.path}/$fileName');

        await fallbackFile.writeAsString(content, encoding: utf8);
        return fallbackFile;
      } catch (fallbackError) {
        print('Fallback save also failed: $fallbackError');
        return null;
      }
    }
  }

  /// Generate CSV from records
  static String _generateCSV(List<AcademicRecord> records) {
    StringBuffer csv = StringBuffer();

    // Add header with BOM for proper Excel encoding
    csv.write('\uFEFF'); // UTF-8 BOM
    csv.writeln(
        'Semester,Course Name,Grade (Letter),Grade (Point),Credit Hours,Semester GPA,CGPA');

    // Group records by semester for better organization
    Map<String, List<AcademicRecord>> recordsBySemester = {};
    for (var record in records) {
      if (!recordsBySemester.containsKey(record.semester)) {
        recordsBySemester[record.semester] = [];
      }
      recordsBySemester[record.semester]!.add(record);
    }

    // Sort semesters
    List<String> sortedSemesters = recordsBySemester.keys.toList()..sort();

    // Add data rows grouped by semester
    for (String semester in sortedSemesters) {
      for (var record in recordsBySemester[semester]!) {
        csv.writeln([
          record.semester,
          '"${record.course.replaceAll('"', '""')}"', // Escape quotes in course names
          _getGradeLetter(record.grade),
          record.grade.toStringAsFixed(1),
          record.creditHours.toStringAsFixed(1),
          record.obtainedGrade?.toStringAsFixed(2) ?? '',
          record.cgpa?.toStringAsFixed(2) ?? '',
        ].join(','));
      }
    }

    return csv.toString();
  }

  /// Generate JSON from records
  static String _generateJSON(List<AcademicRecord> records) {
    final currentCGPA = records.isNotEmpty ? records.first.cgpa : null;
    final totalCredits =
        records.fold<double>(0, (sum, r) => sum + r.creditHours);

    // Calculate semester-wise summary
    Map<String, Map<String, dynamic>> semesterSummary = {};
    for (var record in records) {
      if (!semesterSummary.containsKey(record.semester)) {
        semesterSummary[record.semester] = {
          'courses': <Map<String, dynamic>>[],
          'gpa': record.obtainedGrade,
          'totalCredits': 0.0,
        };
      }
      semesterSummary[record.semester]!['courses'].add({
        'course': record.course,
        'grade': record.grade,
        'gradeLetter': _getGradeLetter(record.grade),
        'creditHours': record.creditHours,
      });
      semesterSummary[record.semester]!['totalCredits'] += record.creditHours;
    }

    final Map<String, dynamic> exportData = {
      'exportInfo': {
        'appName': 'Markify - Academic Records',
        'exportDate': DateTime.now().toIso8601String(),
        'exportVersion': '1.0',
      },
      'summary': {
        'totalRecords': records.length,
        'totalSemesters': semesterSummary.length,
        'totalCredits': totalCredits,
        'currentCGPA': currentCGPA,
      },
      'semesterData': semesterSummary,
      'allRecords': records.map((r) => r.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Get letter grade from grade point
  static String _getGradeLetter(double gradePoint) {
    if (gradePoint >= 4.0) return 'A+';
    if (gradePoint >= 3.75) return 'A';
    if (gradePoint >= 3.50) return 'A-';
    if (gradePoint >= 3.25) return 'B+';
    if (gradePoint >= 3.00) return 'B';
    if (gradePoint >= 2.75) return 'B-';
    if (gradePoint >= 2.50) return 'C+';
    if (gradePoint >= 2.25) return 'C';
    if (gradePoint >= 2.00) return 'D';
    return 'F';
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Show success dialog with share option
  static Future<void> _showSuccessDialog(
      BuildContext context, String filePath, String format) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('$format Export Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your academic records have been exported as $format:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      const Text(
                        'File Location:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filePath,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Share.shareXFiles(
                  [XFile(filePath)],
                  text: 'My Academic Records ($format format)',
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not share file: ${e.toString()}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Share',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

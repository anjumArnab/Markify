// ignore_for_file: deprecated_member_use

import '/theme.dart';
import 'package:flutter/material.dart';
import '../model/academic_record.dart';
import '../service/academic_record_api.dart';
import '../service/download_service.dart'; // Import the DownloadService

class GoogleSheetsSyncScreen extends StatefulWidget {
  const GoogleSheetsSyncScreen({super.key});

  @override
  State<GoogleSheetsSyncScreen> createState() => _GoogleSheetsSyncScreenState();
}

class _GoogleSheetsSyncScreenState extends State<GoogleSheetsSyncScreen> {
  final AcademicRecordsApi _api = AcademicRecordsApi();
  List<AcademicRecord> _records = [];
  bool _isLoading = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final records = await _api.getAllRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load records: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreFromGoogleSheet() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      // Refresh records from the server (Google Sheets backend)
      await _loadRecords();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully restored data from Google Sheets!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRestoring = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup & Restore',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRecords,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Summary Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: AppTheme.primaryColor,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Data Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Courses',
                                _records.length.toString(),
                                Icons.school,
                              ),
                              _buildStatItem(
                                'Semesters',
                                _getUniqueSemesters().length.toString(),
                                Icons.calendar_today,
                              ),
                              _buildStatItem(
                                'Credits',
                                _getTotalCredits().toStringAsFixed(1),
                                Icons.credit_score,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Backup Section
                  const Text(
                    'Backup Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Download as CSV
                  _buildOptionCard(
                    title: 'Download as CSV',
                    subtitle:
                        'Excel-compatible format for spreadsheet applications',
                    icon: Icons.table_view,
                    iconColor: Colors.green,
                    onTap: () =>
                        DownloadService.downloadAsCSV(context, _records),
                    enabled: _records.isNotEmpty,
                  ),

                  const SizedBox(height: 12),

                  // Download as JSON
                  _buildOptionCard(
                    title: 'Download as JSON',
                    subtitle: 'Complete data backup with all details',
                    icon: Icons.code,
                    iconColor: Colors.blue,
                    onTap: () =>
                        DownloadService.downloadAsJSON(context, _records),
                    enabled: _records.isNotEmpty,
                  ),

                  const SizedBox(height: 24),

                  // Google Sheets Section
                  const Text(
                    'Google Sheets Integration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Open Google Sheet
                  _buildOptionCard(
                    title: 'Open Google Sheet',
                    subtitle:
                        'View and edit your data directly in Google Sheets',
                    icon: Icons.open_in_browser,
                    iconColor: Colors.orange,
                    onTap: () => DownloadService.openGoogleSheet(context),
                  ),

                  const SizedBox(height: 12),

                  // Copy Sheet Link
                  _buildOptionCard(
                    title: 'Copy Sheet Link',
                    subtitle: 'Copy Google Sheets link to clipboard',
                    icon: Icons.link,
                    iconColor: Colors.purple,
                    onTap: () => DownloadService.copySheetLink(context),
                  ),

                  const SizedBox(height: 12),

                  // Export from Google Sheets
                  _buildOptionCard(
                    title: 'Export from Google Sheets',
                    subtitle:
                        'Download directly from Google Sheets (CSV, Excel, PDF)',
                    icon: Icons.download,
                    iconColor: Colors.teal,
                    onTap: () => _showExportOptionsDialog(),
                  ),

                  const SizedBox(height: 24),

                  // Restore Section
                  const Text(
                    'Restore Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Restore from Google Sheet Section
                  _buildOptionCard(
                    title: 'Restore from Google Sheet',
                    subtitle: 'Refresh your local data from the cloud',
                    icon: Icons.cloud_download,
                    iconColor: AppTheme.accentColor,
                    onTap: _restoreFromGoogleSheet,
                    enabled: !_isRestoring,
                    isLoading: _isRestoring,
                  ),

                  const SizedBox(height: 24),

                  // Cloud Status Container
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryLightColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_done,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cloud Storage Active',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your data is automatically synchronized with Google Sheets',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'SYNCED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppTheme.surfaceColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: enabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? iconColor.withOpacity(0.1)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Icon(
                        icon,
                        color: enabled ? iconColor : Colors.grey,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: enabled ? AppTheme.textPrimary : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled ? AppTheme.textSecondary : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled && !isLoading)
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export from Google Sheets'),
        content: const Text(
            'Choose the format to download directly from Google Sheets:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadService.exportFromGoogleSheet(context, 'csv');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadService.exportFromGoogleSheet(context, 'xlsx');
            },
            child: const Text('Excel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DownloadService.exportFromGoogleSheet(context, 'pdf');
            },
            child: const Text('PDF'),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueSemesters() {
    return _records.map((r) => r.semester).toSet().toList();
  }

  double _getTotalCredits() {
    return _records.fold(0.0, (sum, record) => sum + record.creditHours);
  }
}

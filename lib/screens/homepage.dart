import 'package:flutter/material.dart';
import '../model/academic_record.dart';
import '../service/academic_record_api.dart';
import '../widgets/semester_section.dart';
import '../screens/add_course_screen.dart'; // Make sure this import exists
import '/theme.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final AcademicRecordsApi _api = AcademicRecordsApi();

  List<AcademicRecord> academicRecords = [];
  bool isLoading = true;
  String? errorMessage;
  double? currentCGPA;
  Map<String, double> semesterGPAs = {};

  // Define proper semester order and names
  final List<String> semesterOrder = [
    '1-1',
    '1-2',
    '2-1',
    '2-2',
    '3-1',
    '3-2',
    '4-1',
    '4-2',
  ];

  // Track which semesters are expanded
  Map<String, bool> expandedSemesters = {};

  // Group records by semester
  Map<String, List<AcademicRecord>> recordsBySemester = {};

  @override
  void initState() {
    super.initState();
    // Initialize expanded semesters
    for (String semester in semesterOrder) {
      expandedSemesters[semester] =
          semester == '1-1'; // Only first one expanded
    }
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Fetch all records from the API (which now includes calculated values)
      final records = await _api.getAllRecords();

      // Debug: Print fetched records
      print('Fetched ${records.length} records:');
      for (var record in records) {
        print(
            '${record.semester} - ${record.course} - ${record.grade} - ${record.creditHours} - OG: ${record.obtainedGrade} - CGPA: ${record.cgpa}');
      }

      // Get current CGPA from the first record (all records should have same CGPA)
      double? cgpa;
      if (records.isNotEmpty) {
        cgpa = records.first.cgpa;
      }

      // Group records by semester and extract semester GPAs
      _groupRecordsBySemester(records);

      setState(() {
        academicRecords = records;
        currentCGPA = cgpa;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching records: $e');
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Initialize empty state even on error
        _initializeEmptyState();
      });
    }
  }

  void _groupRecordsBySemester(List<AcademicRecord> records) {
    // Initialize all semesters with empty lists
    recordsBySemester = {};
    semesterGPAs = {};

    for (String semester in semesterOrder) {
      recordsBySemester[semester] = [];
      semesterGPAs[semester] = 0.0;
    }

    // Group records by semester
    for (var record in records) {
      final semester = record.semester;

      // Add to predefined semesters
      if (semesterOrder.contains(semester)) {
        recordsBySemester[semester]!.add(record);
        // Set the semester GPA (obtained grade) from the record
        if (record.obtainedGrade != null && record.obtainedGrade! > 0) {
          semesterGPAs[semester] = record.obtainedGrade!;
        }
      } else {
        // Handle semesters not in the predefined list
        if (!recordsBySemester.containsKey(semester)) {
          recordsBySemester[semester] = [];
          semesterGPAs[semester] = 0.0;
          expandedSemesters[semester] = false;
        }
        recordsBySemester[semester]!.add(record);
        if (record.obtainedGrade != null && record.obtainedGrade! > 0) {
          semesterGPAs[semester] = record.obtainedGrade!;
        }
      }
    }

    // Debug: Print grouped records
    print('Grouped records by semester:');
    recordsBySemester.forEach((semester, records) {
      print(
          '$semester: ${records.length} courses, GPA: ${semesterGPAs[semester]}');
      for (var record in records) {
        print('  - ${record.course}');
      }
    });
  }

  void _initializeEmptyState() {
    recordsBySemester = {};
    semesterGPAs = {};
    for (String semester in semesterOrder) {
      recordsBySemester[semester] = [];
      semesterGPAs[semester] = 0.0;
    }
    currentCGPA = 0.0;
  }

  int _getTotalCredits() {
    return academicRecords
        .map((record) => record.creditHours.toInt())
        .fold(0, (sum, credits) => sum + credits);
  }

  // Helper method to get all semesters in proper order
  List<String> getAllSemestersInOrder() {
    Set<String> allSemesters = recordsBySemester.keys.toSet();
    List<String> result = [];

    // Add predefined semesters first
    for (String semester in semesterOrder) {
      if (allSemesters.contains(semester)) {
        result.add(semester);
      }
    }

    // Add any additional semesters not in predefined list
    for (String semester in allSemesters) {
      if (!semesterOrder.contains(semester)) {
        result.add(semester);
      }
    }

    return result;
  }

  /// Navigate to AddCourseScreen in edit mode
  void _editRecord(AcademicRecord record) async {
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading course details...'),
          duration: Duration(milliseconds: 500),
        ),
      );

      // Navigate to AddCourseScreen with the record to edit
      final result = await Navigator.push<AcademicRecord>(
        context,
        MaterialPageRoute(
          builder: (context) => AddCourseScreen(
            editingRecord: record, // Pass the record to edit
            onCourseUpdated: () {
              // Callback when course is updated
              fetchRecords(); // Refresh the data
            },
          ),
        ),
      );

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // If result is returned (course was updated), refresh the data
      if (result != null) {
        await fetchRecords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading snackbar and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading course: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Delete a record with confirmation
  void _deleteRecord(AcademicRecord record) async {
    // Validate record ID
    if (record.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Invalid record ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting course...'),
            ],
          ),
          duration: Duration(
              seconds: 30), // Long duration, will be dismissed manually
        ),
      );

      // Call API to delete the record
      await _api.deleteRecord(record.id!);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Refresh the records after successful deletion
      await fetchRecords();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${record.course} deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Implement undo functionality if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo feature coming soon!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Failed to delete ${record.course}'),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _deleteRecord(record), // Retry deletion
            ),
          ),
        );
      }

      // Log error for debugging
      print('Delete error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Markify',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchRecords,
            tooltip: 'Refresh all data',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchRecords,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchRecords,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current CGPA Section
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: AppTheme.dividerColor, width: 1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current CGPA',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      (currentCGPA ?? 0.0).toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'GPA: ${(currentCGPA ?? 0.0).toStringAsFixed(2)} >',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Total Credits: ${_getTotalCredits()}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Semester Sections using SemesterSection widget
                          ...getAllSemestersInOrder().map(
                            (semester) => SemesterSection(
                              semesterCode: semester,
                              gpa: (semesterGPAs[semester] ?? 0.0)
                                  .toStringAsFixed(2),
                              courses: recordsBySemester[semester] ?? [],
                              isExpanded: expandedSemesters[semester] ?? false,
                              onToggleExpanded: (semesterCode) {
                                setState(() {
                                  expandedSemesters[semesterCode] =
                                      !(expandedSemesters[semesterCode] ??
                                          false);
                                });
                              },
                              onEditRecord: _editRecord,
                              onDeleteRecord: _deleteRecord,
                            ),
                          ),

                          // Show message if no records
                          if (academicRecords.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.school_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No academic records found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Add some courses to get started!',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

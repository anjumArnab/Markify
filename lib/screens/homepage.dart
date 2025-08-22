import 'package:flutter/material.dart';
import '../model/academic_record.dart';
import '../service/academic_record_api.dart';
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

      // Get current CGPA from API utility method
      final cgpa = await _api.getCurrentCGPA();

      // Get semester GPAs from API utility method
      final semesterGpaMap = await _api.getSemesterGPAs();

      // Group records by semester
      _groupRecordsBySemester(records);

      setState(() {
        academicRecords = records;
        currentCGPA = cgpa;
        semesterGPAs = semesterGpaMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Initialize empty state even on error
        _initializeEmptyState();
      });
    }
  }

  void _groupRecordsBySemester(List<AcademicRecord> records) {
    // Initialize all semesters
    recordsBySemester = {};
    for (String semester in semesterOrder) {
      recordsBySemester[semester] = [];
    }

    // Group records by semester
    for (var record in records) {
      final semester = record.semester;
      if (semesterOrder.contains(semester)) {
        recordsBySemester[semester]!.add(record);
      }
    }
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

  Future<void> _refreshSemester(String semester) async {
    try {
      // Refresh records for specific semester
      final semesterRecords = await _api.getRecordsBySemester(semester);

      setState(() {
        recordsBySemester[semester] = semesterRecords;

        // Update semester GPA if records exist
        if (semesterRecords.isNotEmpty) {
          // Use the calculated GPA from the first record (all records in same semester have same GPA)
          semesterGPAs[semester] = semesterRecords.first.obtainedGrade ?? 0.0;
        } else {
          semesterGPAs[semester] = 0.0;
        }
      });

      // Refresh overall CGPA
      final cgpa = await _api.getCurrentCGPA();
      setState(() {
        currentCGPA = cgpa;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error refreshing $semester: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getTotalCredits() {
    return academicRecords
        .map((record) => record.creditHours.toInt())
        .fold(0, (sum, credits) => sum + credits);
  }

  // Helper method to get letter grade from grade point
  String _getGradeLetter(double gradePoint) {
    if (gradePoint >= 4.0) return 'A';
    if (gradePoint >= 3.7) return 'A-';
    if (gradePoint >= 3.3) return 'B+';
    if (gradePoint >= 3.0) return 'B';
    if (gradePoint >= 2.7) return 'B-';
    if (gradePoint >= 2.3) return 'C+';
    if (gradePoint >= 2.0) return 'C';
    if (gradePoint >= 1.7) return 'C-';
    if (gradePoint >= 1.3) return 'D+';
    if (gradePoint >= 1.0) return 'D';
    return 'F';
  }

  // Helper method to get color based on grade point
  Color _getGradeColor(double gradePoint) {
    if (gradePoint >= 3.7) return Colors.green;
    if (gradePoint >= 3.0) return Colors.blue;
    if (gradePoint >= 2.0) return Colors.orange;
    if (gradePoint >= 1.0) return Colors.deepOrange;
    return Colors.red;
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

                          // Semester Sections - Display all semesters in order
                          ...semesterOrder.map(
                            (semester) => _buildSemesterSection(
                              semester,
                              (semesterGPAs[semester] ?? 0.0)
                                  .toStringAsFixed(2),
                              recordsBySemester[semester] ?? [],
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

  Widget _buildSemesterSection(
      String semesterCode, String gpa, List<AcademicRecord> courses) {
    bool isExpanded = expandedSemesters[semesterCode] ?? false;
    bool hasCourses = courses.isNotEmpty;
    String semesterName = 'Semester $semesterCode';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Semester Header with refresh button
          InkWell(
            onTap: () {
              setState(() {
                expandedSemesters[semesterCode] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    semesterName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasCourses
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      // Add refresh button for individual semester
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        onPressed: () => _refreshSemester(semesterCode),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Refresh $semesterName',
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GPA: $gpa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: hasCourses
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Course List (only shown if expanded)
          if (isExpanded)
            hasCourses
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course.course,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getGradeColor(course.grade)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_getGradeLetter(course.grade)} (${course.grade.toStringAsFixed(1)})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: _getGradeColor(course.grade),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    course.creditHours.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppTheme.accentColor, size: 20),
                                  onPressed: () => _editRecord(course),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Edit course',
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _deleteRecord(course),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Delete course',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No courses added yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _editRecord(AcademicRecord record) {
    // TODO: Implement edit functionality
    // You can create an EditCourseScreen similar to AddCourseScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _deleteRecord(AcademicRecord record) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this course?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.course,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semester ${record.semester} • Grade: ${_getGradeLetter(record.grade)} • Credits: ${record.creditHours}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will recalculate your semester GPA and overall CGPA.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmDelete == true && record.id != null) {
      try {
        // Show loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Deleting course...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        await _api.deleteRecord(record.id!);

        // Refresh the records after deletion
        await fetchRecords();

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting course: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

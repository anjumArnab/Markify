import 'package:cgpa_tracker/model/academic_record.dart';
import 'package:cgpa_tracker/service/academic_record_api.dart';
import '/theme.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final AcademicRecordsApi api = AcademicRecordsApi();

  List<AcademicRecord> academicRecords = [];
  bool isLoading = true;
  String? errorMessage;
  double currentCGPA = 0.0;
  int totalCredits = 0;

  // Define proper semester order and names
  final List<String> semesterOrder = [
    'Semester 1-1',
    'Semester 1-2',
    'Semester 2-1',
    'Semester 2-2',
    'Semester 3-1',
    'Semester 3-2',
    'Semester 4-1',
    'Semester 4-2',
  ];

  // Track which semesters are expanded
  Map<String, bool> expandedSemesters = {};

  // Group records by semester
  Map<String, List<AcademicRecord>> recordsBySemester = {};
  // Store GPA for each semester
  Map<String, double> semesterGPAs = {};

  @override
  void initState() {
    super.initState();
    // Initialize expanded semesters
    for (String semester in semesterOrder) {
      expandedSemesters[semester] =
          semester == 'Semester 1-1'; // Only first one expanded
    }
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use the semester-based fetching method
      await _fetchRecordsBySemester();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Initialize empty state even on error
        _initializeEmptyState();
      });
    }
  }

  /// Method 1: Fetch all records at once (alternative approach)
  Future<void> _fetchAllRecords() async {
    final records = await api.getAllRecords();

    if (records.isEmpty) {
      setState(() {
        academicRecords = [];
        _initializeEmptyState();
        isLoading = false;
      });
      return;
    }

    _processRecords(records);
  }

  /// Method 2: Fetch records by semester individually (PRIMARY METHOD)
  Future<void> _fetchRecordsBySemester() async {
    final Map<String, List<AcademicRecord>> grouped = {};
    Map<String, double> semesterGpaMap = {};
    List<AcademicRecord> allRecords = [];

    // Initialize all semesters
    for (String semester in semesterOrder) {
      grouped[semester] = [];
      semesterGpaMap[semester] = 0.0;
    }

    // Fetch records for each semester
    for (String semester in semesterOrder) {
      try {
        final semesterRecords = await api.getRecordsBySemester(semester);
        grouped[semester] = semesterRecords;
        allRecords.addAll(semesterRecords);

        // Calculate GPA for this semester
        if (semesterRecords.isNotEmpty) {
          double semesterGradePoints = 0.0;
          double semesterCredits = 0.0;

          for (var record in semesterRecords) {
            double gradePoint = _getGradePoint(record.grade);
            semesterGradePoints += gradePoint * record.creditHours;
            semesterCredits += record.creditHours;
          }

          if (semesterCredits > 0) {
            semesterGpaMap[semester] = semesterGradePoints / semesterCredits;
          }
        }
      } catch (e) {
        // Handle individual semester fetch errors
        print('Error fetching records for $semester: $e');
        grouped[semester] = [];
        semesterGpaMap[semester] = 0.0;
      }
    }

    // Calculate overall CGPA
    double totalGradePoints = 0.0;
    int totalCreditHours = 0;

    for (var record in allRecords) {
      double gradePoint = _getGradePoint(record.grade);
      totalGradePoints += gradePoint * record.creditHours;
      totalCreditHours += record.creditHours.toInt();
    }

    double cgpa =
        totalCreditHours > 0 ? totalGradePoints / totalCreditHours : 0.0;

    setState(() {
      academicRecords = allRecords;
      recordsBySemester = grouped;
      semesterGPAs = semesterGpaMap;
      currentCGPA = cgpa;
      totalCredits = totalCreditHours;
      isLoading = false;
    });
  }

  /// Process fetched records and calculate GPAs (used by _fetchAllRecords)
  void _processRecords(List<AcademicRecord> records) {
    final Map<String, List<AcademicRecord>> grouped = {};
    Map<String, double> semesterGpaMap = {};

    // Initialize all semesters
    for (String semester in semesterOrder) {
      grouped[semester] = [];
      semesterGpaMap[semester] = 0.0;
    }

    double totalGradePoints = 0.0;
    int totalCreditHours = 0;

    // Process each record
    for (var record in records) {
      String semester = _normalizeSemesterName(record.semester);

      // Only add to known semesters
      if (semesterOrder.contains(semester)) {
        grouped[semester]!.add(record);

        // Calculate grade points for this course
        double gradePoint = _getGradePoint(record.grade);
        totalGradePoints += gradePoint * record.creditHours;
        totalCreditHours += record.creditHours.toInt();
      }
    }

    // Calculate semester GPAs
    for (String semester in semesterOrder) {
      if (grouped[semester]!.isNotEmpty) {
        double semesterGradePoints = 0.0;
        double semesterCredits = 0.0;

        for (var record in grouped[semester]!) {
          double gradePoint = _getGradePoint(record.grade);
          semesterGradePoints += gradePoint * record.creditHours;
          semesterCredits += record.creditHours;
        }

        if (semesterCredits > 0) {
          semesterGpaMap[semester] = semesterGradePoints / semesterCredits;
        }
      }
    }

    // Calculate overall CGPA
    double cgpa =
        totalCreditHours > 0 ? totalGradePoints / totalCreditHours : 0.0;

    setState(() {
      academicRecords = records;
      recordsBySemester = grouped;
      semesterGPAs = semesterGpaMap;
      currentCGPA = cgpa;
      totalCredits = totalCreditHours;
      isLoading = false;
    });
  }

  /// Initialize empty state for all semesters
  void _initializeEmptyState() {
    recordsBySemester = {};
    semesterGPAs = {};
    for (String semester in semesterOrder) {
      recordsBySemester[semester] = [];
      semesterGPAs[semester] = 0.0;
    }
    currentCGPA = 0.0;
    totalCredits = 0;
  }

  /// Fetch records for a specific semester (can be called individually)
  Future<void> fetchSemesterRecords(String semester) async {
    try {
      final semesterRecords = await api.getRecordsBySemester(semester);

      setState(() {
        recordsBySemester[semester] = semesterRecords;

        // Recalculate GPA for this semester
        if (semesterRecords.isNotEmpty) {
          double semesterGradePoints = 0.0;
          double semesterCredits = 0.0;

          for (var record in semesterRecords) {
            double gradePoint = _getGradePoint(record.grade);
            semesterGradePoints += gradePoint * record.creditHours;
            semesterCredits += record.creditHours;
          }

          if (semesterCredits > 0) {
            semesterGPAs[semester] = semesterGradePoints / semesterCredits;
          }
        } else {
          semesterGPAs[semester] = 0.0;
        }
      });

      // Recalculate overall CGPA
      _recalculateOverallCGPA();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching $semester records: ${e.toString()}')),
      );
    }
  }

  /// Recalculate overall CGPA from all semester records
  void _recalculateOverallCGPA() {
    double totalGradePoints = 0.0;
    int totalCreditHours = 0;

    for (var semesterRecords in recordsBySemester.values) {
      for (var record in semesterRecords) {
        double gradePoint = _getGradePoint(record.grade);
        totalGradePoints += gradePoint * record.creditHours;
        totalCreditHours += record.creditHours.toInt();
      }
    }

    setState(() {
      currentCGPA =
          totalCreditHours > 0 ? totalGradePoints / totalCreditHours : 0.0;
      totalCredits = totalCreditHours;
    });
  }

  // Helper method to normalize semester names
  String _normalizeSemesterName(String semesterInput) {
    if (semesterInput.isEmpty) return 'Semester 1-1';

    String normalized = semesterInput.trim();

    if (semesterOrder.contains(normalized)) {
      return normalized;
    }

    RegExp regExp = RegExp(r'(\d+)[-.](\d+)');
    Match? match = regExp.firstMatch(normalized);

    if (match != null) {
      String year = match.group(1)!;
      String term = match.group(2)!;
      return 'Semester $year-$term';
    }

    return 'Semester 1-1';
  }

  // Helper method to convert grade to grade point
  double _getGradePoint(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return 4.0;
      case 'A-':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D+':
        return 1.3;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
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
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchRecords,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
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
                                    currentCGPA.toStringAsFixed(2),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'GPA: ${currentCGPA.toStringAsFixed(2)} >',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Credits: $totalCredits',
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
                            semesterGPAs[semester]?.toStringAsFixed(2) ??
                                '0.00',
                            recordsBySemester[semester] ?? [],
                          ),
                        ),

                        // Show message if no records
                        if (academicRecords.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No academic records found. Add some courses to get started!',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSemesterSection(
      String semesterName, String gpa, List<AcademicRecord> courses) {
    bool isExpanded = expandedSemesters[semesterName] ?? false;
    bool hasCourses = courses.isNotEmpty;

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
                expandedSemesters[semesterName] = !isExpanded;
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
                        onPressed: () => fetchSemesterRecords(semesterName),
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
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text(
                                    course.grade,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _getGradeColor(course.grade),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  course.creditHours.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 35),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppTheme.accentColor, size: 20),
                                  onPressed: () => _editRecord(course),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppTheme.textSecondary, size: 20),
                                  onPressed: () => _deleteRecord(course),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _deleteRecord(AcademicRecord record) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete ${record.course}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await api.deleteRecord(record.id!);
        // Refresh the records after deletion
        fetchRecords();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting record: ${e.toString()}')),
        );
      }
    }
  }

  // Helper method to get color based on grade
  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
      case 'A-':
        return Colors.green;
      case 'B+':
      case 'B':
      case 'B-':
        return Colors.blue;
      case 'C+':
      case 'C':
      case 'C-':
        return Colors.orange;
      case 'D+':
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return AppTheme.textPrimary;
    }
  }
}

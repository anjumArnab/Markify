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
  final AcademicRecordsApi api = AcademicRecordsApi(
      baseUrl:
          'https://script.google.com/macros/s/AKfycbwUaq-Y1-vZbC-NmbZJ_G5BIMsmRS9qpAb0PzJYu9SRuX9hAVIRJpm6aq9qV_HeKm24/exec');

  List<AcademicRecord> academicRecords = [];
  bool isLoading = true;
  String? errorMessage;
  double currentCGPA = 0.0;
  int totalCredits = 0;

  // Track which semesters are expanded
  Map<String, bool> expandedSemesters = {
    'Semester 1-1': true,
    'Semester 1-2': false,
    'Semester 2-1': false,
    'Semester 2-2': false,
    'Semester 3-1': false,
    'Semester 3-2': false,
    'Semester 4-1': false,
    'Semester 4-2': false,
  };

  // Group records by semester
  Map<String, List<AcademicRecord>> recordsBySemester = {};
  // Store GPA for each semester
  Map<String, double> semesterGPAs = {};

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final records = await api.getAllRecords();

      // Group records by semester
      final Map<String, List<AcademicRecord>> grouped = {};

      // Extract any overall statistics from the records
      // Assuming the API returns records with these fields already calculated
      double cgpa = 0.0;
      int credits = 0;
      Map<String, double> semesterGpaMap = {};

      // Organization of data by semester
      for (var record in records) {
        // Use semester information from the record
        if (!grouped.containsKey(record.semester)) {
          grouped[record.semester] = [];

          // If the semester GPA is provided in the records, use it
          if (record.gpa != null) {
            semesterGpaMap[record.semester] = record.gpa!;
          }
        }
        grouped[record.semester]!.add(record);
      }

      // Get CGPA and total credits from the backend data
      // This assumes your API provides these values or at least the first record contains them
      if (records.isNotEmpty && records.first.cgpa != null) {
        cgpa = records.first.cgpa!;
        credits = records.first.creditHours as int;
      }

      setState(() {
        academicRecords = records;
        recordsBySemester = grouped;
        semesterGPAs = semesterGpaMap;
        currentCGPA = cgpa;
        totalCredits = credits;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
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
              ? Center(child: Text('Error: $errorMessage'))
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
                              Text(
                                currentCGPA.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
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

                        // Semester Sections
                        ...recordsBySemester.keys.map(
                          (semester) => _buildSemesterSection(
                            semester,
                            semesterGPAs[semester]?.toStringAsFixed(2) ??
                                '0.00',
                            recordsBySemester[semester] ?? [],
                          ),
                        ),

                        // Show message if no records
                        if (recordsBySemester.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No academic records found.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Semester Header
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'GPA: $gpa',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
            ListView.builder(
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
                      Text(
                        course.course,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(
                              course.grade as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getGradeColor(course.grade as String),
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
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _editRecord(AcademicRecord record) {
    // TODO: Implement edit functionality
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
    switch (grade) {
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

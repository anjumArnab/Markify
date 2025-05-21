import '../service/academic_record_api.dart';
import '/theme.dart';
import 'package:flutter/material.dart';
import '../model/academic_record.dart';

class AddCourseScreen extends StatefulWidget {
  final Function? onCourseAdded;

  const AddCourseScreen({
    super.key,
    this.onCourseAdded,
  });

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  String selectedGrade = 'A';
  String selectedCreditHours = '3.0';
  String selectedSemester = '1-1';
  final TextEditingController _courseNameController =
      TextEditingController(text: 'Introduction to Computing');

  bool _isLoading = false;
  final AcademicRecordsApi _api = AcademicRecordsApi();

  final List<String> grades = [
    'A',
    'A-',
    'B+',
    'B',
    'B-',
    'C+',
    'C',
    'C-',
    'D+',
    'D',
    'F'
  ];
  final List<String> creditHours = ['1.0', '1.5', '2.0', '3.0', '4.0', '5.0'];
  final List<String> semesters = [
    '1-1',
    '1-2',
    '2-1',
    '2-2',
    '3-1',
    '3-2',
    '4-1',
    '4-2'
  ];

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

  // Method to create a new academic record
  Future<void> _createRecord() async {
    // Validate course name
    if (_courseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a course name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new academic record object from form data
      final newRecord = AcademicRecord(
        id: null, // ID will be assigned by the backend
        semester: selectedSemester,
        course: _courseNameController.text.trim(),
        grade: selectedGrade,
        creditHours: double.parse(selectedCreditHours),
      );

      // Call the API to create the record
      await _api.createRecord(newRecord);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course added successfully!'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Notify parent widget that a course was added (for refreshing lists)
      if (widget.onCourseAdded != null) {
        widget.onCourseAdded!();
      }

      // Reset form or navigate back
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add course: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Course',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Name
              const Text(
                'Course Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLightColor),
                ),
                child: TextField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Enter course name',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 16),

              // Grade and Credit Hours in a Row
              Row(
                children: [
                  // Grade Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Grade',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppTheme.primaryLightColor),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedGrade,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppTheme.primaryColor),
                            dropdownColor: AppTheme.surfaceColor,
                            items: grades.map((String grade) {
                              return DropdownMenuItem<String>(
                                value: grade,
                                child: Text(
                                  grade,
                                  style: TextStyle(
                                    color: _getGradeColor(grade),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGrade = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Credit Hours Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Credit Hours',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppTheme.primaryLightColor),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedCreditHours,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppTheme.primaryColor),
                            dropdownColor: AppTheme.surfaceColor,
                            items: creditHours.map((String hours) {
                              return DropdownMenuItem<String>(
                                value: hours,
                                child: Text(hours),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCreditHours = newValue!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Semester
              const Text(
                'Semester',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLightColor),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedSemester,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor),
                  dropdownColor: AppTheme.surfaceColor,
                  items: semesters.map((String semester) {
                    return DropdownMenuItem<String>(
                      value: semester,
                      child: Text(
                        'Semester $semester',
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSemester = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Add Course Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Add Course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Preview Section
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                color: AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Course Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _courseNameController.text,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Semester $selectedSemester',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getGradeColor(selectedGrade)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  selectedGrade,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getGradeColor(selectedGrade),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$selectedCreditHours cr',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }
}

// ignore_for_file: deprecated_member_use

import '../service/academic_record_api.dart';
import '/theme.dart';
import 'package:flutter/material.dart';
import '../model/academic_record.dart';

class AddCourseScreen extends StatefulWidget {
  final Function? onCourseAdded;
  final Function? onCourseUpdated;
  final AcademicRecord? editingRecord;

  const AddCourseScreen({
    super.key,
    this.onCourseAdded,
    this.onCourseUpdated,
    this.editingRecord, // Pass record when editing
  });

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  String selectedGrade = '4.0';
  String selectedCreditHours = '3.0';
  String selectedSemester = '1-1';
  final TextEditingController _courseNameController = TextEditingController();

  bool _isLoading = false;
  final AcademicRecordsApi _api = AcademicRecordsApi();

  // Track if we're in edit mode
  bool get isEditMode => widget.editingRecord != null;

  // Updated to use numeric grade values
  final List<Map<String, dynamic>> grades = [
    {'letter': 'A', 'point': '4.0'},
    {'letter': 'A-', 'point': '3.7'},
    {'letter': 'B+', 'point': '3.3'},
    {'letter': 'B', 'point': '3.0'},
    {'letter': 'B-', 'point': '2.7'},
    {'letter': 'C+', 'point': '2.3'},
    {'letter': 'C', 'point': '2.0'},
    {'letter': 'C-', 'point': '1.7'},
    {'letter': 'D+', 'point': '1.3'},
    {'letter': 'D', 'point': '1.0'},
    {'letter': 'F', 'point': '0.0'},
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

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  /// Initialize form with existing data if editing
  void _initializeFormData() {
    if (isEditMode && widget.editingRecord != null) {
      final record = widget.editingRecord!;

      // Set form values from existing record
      _courseNameController.text = record.course;
      selectedGrade = record.grade.toStringAsFixed(1);
      selectedCreditHours = record.creditHours.toStringAsFixed(1);
      selectedSemester = record.semester;

      // Ensure the selected values exist in our lists
      if (!grades.any((g) => g['point'] == selectedGrade)) {
        selectedGrade = '4.0'; // Default if not found
      }
      if (!creditHours.contains(selectedCreditHours)) {
        selectedCreditHours = '3.0'; // Default if not found
      }
      if (!semesters.contains(selectedSemester)) {
        selectedSemester = '1-1'; // Default if not found
      }
    } else {
      // Default values for new course
      _courseNameController.text = 'Introduction to Computing';
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    super.dispose();
  }

  // Helper method to get color based on grade point
  Color _getGradeColor(String gradePoint) {
    double point = double.tryParse(gradePoint) ?? 0.0;
    if (point >= 3.7) return Colors.green;
    if (point >= 3.0) return Colors.blue;
    if (point >= 2.0) return Colors.orange;
    if (point >= 1.0) return Colors.deepOrange;
    return Colors.red;
  }

  // Get letter grade from grade point
  String _getGradeLetter(String gradePoint) {
    final grade = grades.firstWhere(
      (g) => g['point'] == gradePoint,
      orElse: () => {'letter': 'A', 'point': '4.0'},
    );
    return grade['letter'];
  }

  /// Method to create or update a record
  Future<void> _saveRecord() async {
    // Validate course name
    if (_courseNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a course name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        // Update existing record
        await _updateRecord();
      } else {
        // Create new record
        await _createRecord();
      }
    } catch (e) {
      // Error handling is done in individual methods
      print('Save record error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Create a new academic record
  Future<void> _createRecord() async {
    try {
      // Create a new academic record object from form data
      final newRecord = AcademicRecord(
        id: null, // ID will be assigned by the backend
        semester: selectedSemester,
        course: _courseNameController.text.trim(),
        grade: double.parse(selectedGrade),
        creditHours: double.parse(selectedCreditHours),
      );

      // Call the API to create the record
      final createdRecord = await _api.createRecord(newRecord);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Course added successfully! GPA: ${createdRecord.obtainedGrade?.toStringAsFixed(2) ?? "Calculating..."}'),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Notify parent widget that a course was added
      if (widget.onCourseAdded != null) {
        widget.onCourseAdded!();
      }

      // Navigate back with the created record
      if (mounted) {
        Navigator.pop(context, createdRecord);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add course: ${e.toString()}');
    }
  }

  /// Update existing academic record
  Future<void> _updateRecord() async {
    if (widget.editingRecord?.id == null) {
      _showErrorSnackBar('Cannot update: Invalid record ID');
      return;
    }

    try {
      // Create updated record object
      final updatedRecord = AcademicRecord(
        id: widget.editingRecord!.id,
        semester: selectedSemester,
        course: _courseNameController.text.trim(),
        grade: double.parse(selectedGrade),
        creditHours: double.parse(selectedCreditHours),
        // Keep existing calculated values (they'll be recalculated by backend)
        obtainedGrade: widget.editingRecord!.obtainedGrade,
        cgpa: widget.editingRecord!.cgpa,
      );

      // Call the API to update the record
      final result = await _api.updateRecord(updatedRecord);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Course updated successfully! New GPA: ${result.obtainedGrade?.toStringAsFixed(2) ?? "Calculating..."}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Notify parent widget that a course was updated
      if (widget.onCourseUpdated != null) {
        widget.onCourseUpdated!();
      }

      // Navigate back with the updated record
      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update course: ${e.toString()}');
    }
  }

  /// Helper method to show error messages
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Course' : 'Add Course',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                            items: grades.map((Map<String, dynamic> grade) {
                              return DropdownMenuItem<String>(
                                value: grade['point'],
                                child: Text(
                                  '${grade['letter']} (${grade['point']})',
                                  style: TextStyle(
                                    color: _getGradeColor(grade['point']),
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

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isEditMode ? Colors.orange : AppTheme.primaryColor,
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
                      : Text(
                          isEditMode ? 'Update Course' : 'Add Course',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Cancel button for edit mode
              if (isEditMode) const SizedBox(height: 12),
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
                      Row(
                        children: [
                          Text(
                            isEditMode
                                ? 'Updated Course Preview'
                                : 'Course Preview',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (isEditMode)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'EDITING',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _courseNameController.text.isNotEmpty
                                      ? _courseNameController.text
                                      : 'Course Name',
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
                                if (isEditMode && widget.editingRecord != null)
                                  Text(
                                    'ID: ${widget.editingRecord!.id}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
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
                                  '${_getGradeLetter(selectedGrade)} ($selectedGrade)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getGradeColor(selectedGrade),
                                    fontSize: 12,
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
}

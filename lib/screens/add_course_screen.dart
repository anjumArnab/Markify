// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/academic_record.dart';
import '../provider/academic_records_provider.dart';
import '/theme.dart';

class AddCourseScreen extends StatefulWidget {
  final AcademicRecord? editingRecord;

  const AddCourseScreen({
    super.key,
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

  // Track if we're in edit mode
  bool get isEditMode => widget.editingRecord != null;

  final List<Map<String, dynamic>> grades = [
    {'letter': 'A+', 'point': '4.0'},
    {'letter': 'A', 'point': '3.75'},
    {'letter': 'A-', 'point': '3.50'},
    {'letter': 'B+', 'point': '3.25'},
    {'letter': 'B', 'point': '3.00'},
    {'letter': 'B-', 'point': '2.75'},
    {'letter': 'C+', 'point': '2.50'},
    {'letter': 'C', 'point': '2.25'},
    {'letter': 'D', 'point': '2.00'},
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
      _showSnackBar('Please enter a course name', Colors.red);
      return;
    }

    final provider =
        Provider.of<AcademicRecordsProvider>(context, listen: false);

    try {
      bool success;
      String successMessage;

      if (isEditMode) {
        // Update existing record
        final updatedRecord = AcademicRecord(
          id: widget.editingRecord!.id,
          semester: selectedSemester,
          course: _courseNameController.text.trim(),
          grade: double.parse(selectedGrade),
          creditHours: double.parse(selectedCreditHours),
        );

        success = await provider.updateRecord(updatedRecord);
        successMessage = 'Course updated successfully!';
      } else {
        // Create new record
        final newRecord = AcademicRecord(
          id: null,
          semester: selectedSemester,
          course: _courseNameController.text.trim(),
          grade: double.parse(selectedGrade),
          creditHours: double.parse(selectedCreditHours),
        );

        success = await provider.addRecord(newRecord);
        successMessage = 'Course added successfully!';
      }

      if (success && mounted) {
        _showSnackBar(successMessage, Colors.green);
      } else if (mounted) {
        // Show error from provider
        final errorMessage = provider.errorMessage ?? 'Unknown error occurred';
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Operation failed: ${e.toString()}', Colors.red);
    }
  }

  /// Helper method to show error messages
  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
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
      body: Consumer<AcademicRecordsProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
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
                                border: Border.all(
                                    color: AppTheme.primaryLightColor),
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
                                border: Border.all(
                                    color: AppTheme.primaryLightColor),
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
                      onPressed: provider.isLoading ? null : _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEditMode ? Colors.orange : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: provider.isLoading
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
                                    if (isEditMode &&
                                        widget.editingRecord != null)
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

                          // Show provider status if there's any loading or error
                          if (provider.isLoading || provider.hasError) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            if (provider.isLoading)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            if (provider.hasError && !provider.isLoading)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/academic_record.dart';
import '../controllers/academic_records_controller.dart';
import '/theme.dart';

class AddCourseScreen extends StatelessWidget {
  final AcademicRecord? editingRecord;

  const AddCourseScreen({
    super.key,
    this.editingRecord,
  });

  @override
  Widget build(BuildContext context) {
    // Get controller instance
    final controller = Get.find<AcademicRecordsController>();

    // Reactive form state
    final selectedGrade = '4.0'.obs;
    final selectedCreditHours = '3.0'.obs;
    final selectedSemester = '1-1'.obs;
    final courseNameController = TextEditingController();

    // Track if we're in edit mode
    final isEditMode = editingRecord != null;

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

    // Initialize form with existing data if editing
    if (isEditMode && editingRecord != null) {
      final record = editingRecord!;
      courseNameController.text = record.course;
      selectedGrade.value = record.grade.toStringAsFixed(1);
      selectedCreditHours.value = record.creditHours.toStringAsFixed(1);
      selectedSemester.value = record.semester;

      // Ensure the selected values exist in our lists
      if (!grades.any((g) => g['point'] == selectedGrade.value)) {
        selectedGrade.value = '4.0';
      }
      if (!creditHours.contains(selectedCreditHours.value)) {
        selectedCreditHours.value = '3.0';
      }
      if (!semesters.contains(selectedSemester.value)) {
        selectedSemester.value = '1-1';
      }
    } else {
      courseNameController.text = 'Introduction to Computing';
    }

    // Helper method to get color based on grade point
    Color getGradeColor(String gradePoint) {
      double point = double.tryParse(gradePoint) ?? 0.0;
      if (point >= 3.7) return Colors.green;
      if (point >= 3.0) return Colors.blue;
      if (point >= 2.0) return Colors.orange;
      if (point >= 1.0) return Colors.deepOrange;
      return Colors.red;
    }

    // Get letter grade from grade point
    String getGradeLetter(String gradePoint) {
      final grade = grades.firstWhere(
        (g) => g['point'] == gradePoint,
        orElse: () => {'letter': 'A', 'point': '4.0'},
      );
      return grade['letter'];
    }

    // Method to create or update a record
    Future<void> saveRecord() async {
      // Validate course name
      if (courseNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please enter a course name',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      try {
        bool success;

        if (isEditMode) {
          // Update existing record
          final updatedRecord = AcademicRecord(
            id: editingRecord!.id,
            semester: selectedSemester.value,
            course: courseNameController.text.trim(),
            grade: double.parse(selectedGrade.value),
            creditHours: double.parse(selectedCreditHours.value),
          );

          success = await controller.updateRecord(updatedRecord);
        } else {
          // Create new record
          final newRecord = AcademicRecord(
            id: null,
            semester: selectedSemester.value,
            course: courseNameController.text.trim(),
            grade: double.parse(selectedGrade.value),
            creditHours: double.parse(selectedCreditHours.value),
          );

          success = await controller.addRecord(newRecord);
        }

        if (success) {
          // Navigate back with success result
          Get.back(result: true);
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Operation failed: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

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
      body: Obx(() {
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
                    controller: courseNameController,
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
                            child: Obx(() => DropdownButtonFormField<String>(
                                  value: selectedGrade.value,
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
                                          color: getGradeColor(grade['point']),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    selectedGrade.value = newValue!;
                                  },
                                )),
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
                            child: Obx(() => DropdownButtonFormField<String>(
                                  value: selectedCreditHours.value,
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
                                    selectedCreditHours.value = newValue!;
                                  },
                                )),
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
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: selectedSemester.value,
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
                              style:
                                  const TextStyle(color: AppTheme.textPrimary),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          selectedSemester.value = newValue!;
                        },
                      )),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading ? null : saveRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isEditMode ? Colors.orange : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isLoading
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
                    child: Obx(() => Column(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        courseNameController.text.isNotEmpty
                                            ? courseNameController.text
                                            : 'Course Name',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Semester ${selectedSemester.value}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (isEditMode && editingRecord != null)
                                        Text(
                                          'ID: ${editingRecord!.id}',
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
                                        color: getGradeColor(selectedGrade.value)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${getGradeLetter(selectedGrade.value)} (${selectedGrade.value})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              getGradeColor(selectedGrade.value),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${selectedCreditHours.value} cr',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Show controller status if there's any loading or error
                            if (controller.isLoading || controller.hasError) ...[
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              if (controller.isLoading)
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
                              if (controller.hasError && !controller.isLoading)
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
                                        controller.errorMessage ?? 'Unknown error',
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
                        )),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
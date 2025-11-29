import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/academic_record.dart';
import '../controllers/academic_records_controller.dart';
import '../widgets/semester_section.dart';
import '../screens/add_course_screen.dart';
import '/theme.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get controller instance
    final controller = Get.find<AcademicRecordsController>();

    // Track which semesters are expanded using RxMap
    final expandedSemesters = <String, bool>{}.obs;

    // Initialize expanded semesters - only first one expanded
    for (String semester in controller.semesterOrder) {
      expandedSemesters[semester] = semester == '1-1';
    }

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
          Obx(() => IconButton(
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
                onPressed: controller.isLoading
                    ? null
                    : () => controller.refreshData(),
              )),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && !controller.hasRecords) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError && !controller.hasRecords) {
          return Center(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    controller.errorMessage ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.fetchRecords(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshData(),
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
                        bottom:
                            BorderSide(color: AppTheme.dividerColor, width: 1),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (controller.currentCGPA ?? 0.0)
                                  .toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'GPA: ${(controller.semesterGPAs.values.last).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Credits: ${controller.totalCredits}',
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
                  ...controller.getAllSemestersInOrder().map(
                        (semester) => Obx(
                          () => SemesterSection(
                            semesterCode: semester,
                            gpa: controller
                                .getSemesterGPA(semester)
                                .toStringAsFixed(2),
                            courses: controller.getRecordsForSemester(semester),
                            isExpanded: expandedSemesters[semester] ?? false,
                            onToggleExpanded: (semesterCode) {
                              expandedSemesters[semesterCode] =
                                  !(expandedSemesters[semesterCode] ?? false);
                            },
                            onEditRecord: _editRecord,
                            onDeleteRecord: _deleteRecord,
                          ),
                        ),
                      ),

                  // Show message if no records
                  if (!controller.hasRecords)
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

                  // Show error banner if there's an error but we have cached data
                  if (controller.hasError && controller.hasRecords)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unable to sync with server: ${controller.errorMessage}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => controller.fetchRecords(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Navigate to AddCourseScreen in edit mode
  void _editRecord(AcademicRecord record) async {
    try {
      // Show loading snackbar
      Get.snackbar(
        'Loading',
        'Loading course details...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 500),
      );

      // Navigate to AddCourseScreen with the record to edit
      final result = await Get.to<bool>(
        () => AddCourseScreen(editingRecord: record),
      );

      // Show success message if course was updated
      if (result == true) {
        Get.snackbar(
          'Success',
          'Course updated successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error loading course: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Delete a record with confirmation
  void _deleteRecord(AcademicRecord record) async {
    // Validate record ID
    if (record.id == null) {
      Get.snackbar(
        'Error',
        'Cannot delete: Invalid record ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Course'),
        content: Text('Are you sure you want to delete "${record.course}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get controller
      final controller = Get.find<AcademicRecordsController>();

      // Show loading indicator
      Get.snackbar(
        'Deleting',
        'Deleting course...',
        snackPosition: SnackPosition.BOTTOM,
        showProgressIndicator: true,
        duration: const Duration(seconds: 30),
      );

      // Call controller to delete the record
      final success = await controller.deleteRecord(record.id!);

      // Close loading snackbar
      Get.closeAllSnackbars();

      if (!success) {
        // Show error from controller
        Get.snackbar(
          'Error',
          controller.errorMessage ?? 'Failed to delete course',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.closeAllSnackbars();
      Get.snackbar(
        'Error',
        'Delete failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }
}

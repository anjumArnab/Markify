import 'package:flutter/material.dart';
import '../model/academic_record.dart';
import '/theme.dart';

class SemesterSection extends StatefulWidget {
  final String semesterCode;
  final String gpa;
  final List<AcademicRecord> courses;
  final bool isExpanded;
  final Function(String) onToggleExpanded;
  final Function(AcademicRecord) onEditRecord;
  final Function(AcademicRecord) onDeleteRecord;

  const SemesterSection({
    super.key,
    required this.semesterCode,
    required this.gpa,
    required this.courses,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  @override
  State<SemesterSection> createState() => _SemesterSectionState();
}

class _SemesterSectionState extends State<SemesterSection> {
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
    bool hasCourses = widget.courses.isNotEmpty;
    String semesterName = 'Semester ${widget.semesterCode}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Semester Header (removed refresh button)
          InkWell(
            onTap: () => widget.onToggleExpanded(widget.semesterCode),
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
                      Text(
                        'GPA: ${widget.gpa} (${widget.courses.length} courses)',
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
                        widget.isExpanded
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

          // Course List with Dismissible
          if (widget.isExpanded)
            hasCourses
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.courses.length,
                    itemBuilder: (context, index) {
                      final course = widget.courses[index];
                      return Dismissible(
                        key: Key('course_${course.id}_${course.course}'),
                        background: Container(
                          color: AppTheme.accentColor,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Edit action - don't dismiss
                            widget.onEditRecord(course);
                            return false;
                          } else if (direction == DismissDirection.endToStart) {
                            // Delete action - show confirmation
                            final confirmed = await _showDeleteConfirmation(
                                context, course);
                            if (confirmed) {
                              // Call delete handler here, before dismissing
                              widget.onDeleteRecord(course);
                            }
                            return confirmed; // Only return true if user confirmed
                          }
                          return false;
                        },
                        // onDismissed callback removed - deletion handled in confirmDismiss
                        child: Padding(
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
                                ],
                              ),
                            ],
                          ),
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

  Future<bool> _showDeleteConfirmation(
      BuildContext context, AcademicRecord course) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this course?'),
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
                    course.course,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semester ${course.semester} • Grade: ${_getGradeLetter(course.grade)} • Credits: ${course.creditHours}',
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
    return result ?? false;
  }
}
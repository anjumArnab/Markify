import 'package:cgpa_tracker/theme.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Track which semesters are expanded
  Map<String, bool> expandedSemesters = {
    'Semester 1-1': true,
    'Semester 1-2': false,
    'Semester 2-1': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CGPA Tracker',
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
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current CGPA',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3.75',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Total Credits: 90',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Semester Sections
              _buildSemesterSection(
                'Semester 1-1',
                '3.8',
                [
                  {'course': 'Math 101', 'grade': 'A', 'points': '3.0'},
                  {'course': 'Physics 101', 'grade': 'B+', 'points': '3.0'},
                ],
              ),
              _buildSemesterSection('Semester 1-2', '3.6', []),
              _buildSemesterSection('Semester 2-1', '3.9', []),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterSection(String semesterName, String gpa, List<Map<String, String>> courses) {
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
                        isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
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
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        courses[index]['course']!,
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
                              courses[index]['grade']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _getGradeColor(courses[index]['grade']!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            courses[index]['points']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 35),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.accentColor, size: 20),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.textSecondary, size: 20),
                            onPressed: () {},
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
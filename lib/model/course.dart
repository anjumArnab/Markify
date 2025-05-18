class Course {
  final String id;
  final String semester;
  final String courseName;
  final String grade;
  final int creditHours;
  final double gradePoints;
  final double GPA;
  final double CGPA;

  Course(
      {required this.id,
      required this.semester,
      required this.courseName,
      required this.grade,
      required this.creditHours,
      required this.gradePoints,
      required this.GPA,
      required this.CGPA});

  // Convert Course to JSON to send to Google App Script
  Map<String, dynamic> toJson() => {
        'id': id,
        'semester': semester,
        'courseName': courseName,
        'grade': grade,
        'creditHours': creditHours,
        'gradePoints': gradePoints,
        'GPA': GPA,
        'CGPA': CGPA,
      };

  // Create Course object from JSON response
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      semester: json['semester'] ?? '',
      courseName: json['courseName'] ?? '',
      grade: json['grade'] ?? '',
      creditHours: int.tryParse(json['creditHours'].toString()) ?? 0,
      gradePoints: double.tryParse(json['gradePoints'].toString()) ?? 0.0,
      GPA: double.tryParse(json['GPA'].toString()) ?? 0.0,
      CGPA: double.tryParse(json['CGPA'].toString()) ?? 0.0,
    );
  }
}

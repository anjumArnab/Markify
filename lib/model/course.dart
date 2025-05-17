class Course {
  final String id;
  final String semester;
  final String courseName;
  final String grade;
  final int creditHours;

  Course({
    required this.id,
    required this.semester,
    required this.courseName,
    required this.grade,
    required this.creditHours,
  });

  // Convert Course to JSON to send to Google App Script
  Map<String, dynamic> toJson() => {
        'id': id,
        'semester': semester,
        'courseName': courseName,
        'grade': grade,
        'creditHours': creditHours,
      };

  // Create Course object from JSON response
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      semester: json['semester'],
      courseName: json['courseName'],
      grade: json['grade'],
      creditHours: int.tryParse(json['creditHours'].toString()) ?? 0,
    );
  }
}

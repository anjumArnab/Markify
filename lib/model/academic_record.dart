class AcademicRecord {
  final int? id;
  final String semester;
  final String course;
  final double grade;
  final double creditHours;
  final double? gpa;
  final double? cgpa;

  AcademicRecord({
    this.id,
    required this.semester,
    required this.course,
    required this.grade,
    required this.creditHours,
    this.gpa,
    this.cgpa,
  });

  /// Convert JSON to AcademicRecord
  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    return AcademicRecord(
      id: json['id'],
      semester: json['semester'] ?? '',
      course: json['course'] ?? '',
      grade: (json['grade'] ?? 0.0).toDouble(),
      creditHours: (json['creditHours'] ?? 0.0).toDouble(),
      gpa: (json['gpa'] ?? 0.0).toDouble(),
      cgpa: (json['cgpa'] ?? 0.0).toDouble(),
    );
  }

  /// Convert AcademicRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'semester': semester,
      'course': course,
      'grade': grade,
      'creditHours': creditHours,
      if (gpa != null) 'gpa': gpa,
      if (cgpa != null) 'cgpa': cgpa,
    };
  }
}

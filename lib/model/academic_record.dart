class AcademicRecord {
  final int? id;
  final String semester;
  final String course;
  final String grade;
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

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert values to double
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        if (value.isEmpty) return null;
        return double.tryParse(value);
      }
      return null;
    }

    return AcademicRecord(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'] as int?,
      semester: json['semester']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      creditHours: safeToDouble(json['creditHours']) ?? 0.0,
      gpa: safeToDouble(json['gpa']),
      cgpa: safeToDouble(json['cgpa']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester': semester,
      'course': course,
      'grade': grade,
      'creditHours': creditHours,
      'gpa': gpa,
      'cgpa': cgpa,
    };
  }
}

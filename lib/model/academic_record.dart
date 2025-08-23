class AcademicRecord {
  final int? id;
  final String semester;
  final String course;
  final double grade;
  final double creditHours;
  final double? obtainedGrade;
  final double? cgpa;

  AcademicRecord({
    this.id,
    required this.semester,
    required this.course,
    required this.grade, // Now required
    required this.creditHours,
    this.obtainedGrade,
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

    // Helper function for required double values
    double safeToDoubleRequired(dynamic value) {
      final result = safeToDouble(value);
      return result ?? 0.0;
    }

    return AcademicRecord(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'] as int?,
      semester: json['semester']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      grade: safeToDoubleRequired(
          json['grade']), // Required, defaults to 0.0 if null
      creditHours: safeToDoubleRequired(
          json['creditHours']), // Required, defaults to 0.0 if null
      obtainedGrade:
          safeToDouble(json['obtainedGrade']), // Can be null (calculated)
      cgpa: safeToDouble(json['cgpa']), // Can be null (calculated)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester': semester,
      'course': course,
      'grade': grade,
      'creditHours': creditHours,
      'obtainedGrade': obtainedGrade,
      'cgpa': cgpa,
    };
  }

  // Validation methods
  bool isValidGrade() {
    return grade >= 0.0 && grade <= 4.0;
  }

  bool isValidCreditHours() {
    return creditHours > 0.0;
  }

  bool isValid() {
    return semester.isNotEmpty &&
        course.isNotEmpty &&
        isValidGrade() &&
        isValidCreditHours();
  }
}

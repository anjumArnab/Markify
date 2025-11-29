import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../model/academic_record.dart';
import '../service/academic_record_api.dart';

class AcademicRecordsController extends GetxController {
  final AcademicRecordsApi _api = AcademicRecordsApi();

  // Reactive state variables
  final _records = <AcademicRecord>[].obs;
  final _isLoading = false.obs;
  final _errorMessage = Rxn<String>();
  final _currentCGPA = Rxn<double>();
  final _semesterGPAs = <String, double>{}.obs;
  final _recordsBySemester = <String, List<AcademicRecord>>{}.obs;

  // Getters for accessing reactive state
  List<AcademicRecord> get records => _records;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  double? get currentCGPA => _currentCGPA.value;
  Map<String, double> get semesterGPAs => _semesterGPAs;
  Map<String, List<AcademicRecord>> get recordsBySemester => _recordsBySemester;

  // Computed properties
  int get totalCredits => _records
      .map((record) => record.creditHours.toInt())
      .fold(0, (sum, credits) => sum + credits);

  int get totalCourses => _records.length;

  int get totalSemesters => _semesterGPAs.keys.length;

  List<String> get uniqueSemesters {
    final semesters = _records.map((r) => r.semester).toSet().toList();
    semesters.sort();
    return semesters;
  }

  // Semester order for proper display
  final List<String> semesterOrder = [
    '1-1',
    '1-2',
    '2-1',
    '2-2',
    '3-1',
    '3-2',
    '4-1',
    '4-2',
  ];

  // Initialization
  @override
  void onInit() {
    super.onInit();
    fetchRecords();
  }

  /// Fetch all records from API
  Future<void> fetchRecords() async {
    _setLoading(true);
    _clearError();

    try {
      final records = await _api.getAllRecords();

      _records.value = records;
      _updateCalculatedValues();
      _groupRecordsBySemester();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load records: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Add a new record
  Future<bool> addRecord(AcademicRecord record) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.createRecord(record);

      // Refresh all records to get updated calculations
      await fetchRecords();

      // Show success message
      Get.snackbar(
        'Success',
        'Course added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      _setError('Failed to add record: ${e.toString()}');
      _setLoading(false);

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to add record: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return false;
    }
  }

  /// Update an existing record
  Future<bool> updateRecord(AcademicRecord record) async {
    if (record.id == null) {
      _setError('Cannot update: Invalid record ID');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _api.updateRecord(record);

      // Refresh all records to get updated calculations
      await fetchRecords();

      // Show success message
      Get.snackbar(
        'Success',
        'Course updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      _setError('Failed to update record: ${e.toString()}');
      _setLoading(false);

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to update record: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return false;
    }
  }

  /// Delete a record
  Future<bool> deleteRecord(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _api.deleteRecord(id);

      // Refresh all records to get updated calculations
      await fetchRecords();

      // Show success message
      Get.snackbar(
        'Success',
        'Course deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      _setError('Failed to delete record: ${e.toString()}');
      _setLoading(false);

      // Show error message
      Get.snackbar(
        'Error',
        'Failed to delete record: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      return false;
    }
  }

  /// Get records for a specific semester
  List<AcademicRecord> getRecordsForSemester(String semester) {
    return _recordsBySemester[semester] ?? [];
  }

  /// Get GPA for a specific semester
  double getSemesterGPA(String semester) {
    return _semesterGPAs[semester] ?? 0.0;
  }

  /// Get records filtered by semester from API
  Future<List<AcademicRecord>> getRecordsBySemesterFromAPI(
      String semester) async {
    try {
      return await _api.getRecordsBySemester(semester);
    } catch (e) {
      _setError('Failed to load semester records: ${e.toString()}');
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Refresh data (same as fetchRecords but with different semantics)
  Future<void> refreshData() async {
    await fetchRecords();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    _isLoading.value = false;
    if (kDebugMode) {
      print('AcademicRecordsController Error: $error');
    }
  }

  void _clearError() {
    _errorMessage.value = null;
  }

  void _updateCalculatedValues() {
    if (_records.isNotEmpty) {
      // Get CGPA from first record (all records should have same CGPA)
      _currentCGPA.value = _records.first.cgpa;

      // Extract semester GPAs from records
      _semesterGPAs.clear();
      for (var record in _records) {
        if (record.obtainedGrade != null && record.obtainedGrade! > 0) {
          _semesterGPAs[record.semester] = record.obtainedGrade!;
        }
      }
    } else {
      _currentCGPA.value = 0.0;
      _semesterGPAs.clear();
    }
  }

  void _groupRecordsBySemester() {
    _recordsBySemester.clear();

    // Initialize all predefined semesters with empty lists
    for (String semester in semesterOrder) {
      _recordsBySemester[semester] = [];
    }

    // Group records by semester
    for (var record in _records) {
      final semester = record.semester;

      if (semesterOrder.contains(semester)) {
        _recordsBySemester[semester]!.add(record);
      }
    }
  }

  /// Get all semesters in proper order for display
  List<String> getAllSemestersInOrder() {
    Set<String> allSemesters = _recordsBySemester.keys.toSet();
    List<String> result = [];

    // Add predefined semesters first
    for (String semester in semesterOrder) {
      if (allSemesters.contains(semester)) {
        result.add(semester);
      }
    }
    return result;
  }

  /// Check if there are any records
  bool get hasRecords => _records.isNotEmpty;

  /// Check if there's an error
  bool get hasError => _errorMessage.value != null;

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}

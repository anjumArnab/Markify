import 'package:flutter/foundation.dart';
import '../model/academic_record.dart';
import '../service/academic_record_api.dart';

class AcademicRecordsProvider extends ChangeNotifier {
  final AcademicRecordsApi _api = AcademicRecordsApi();

  // Private state variables
  List<AcademicRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  double? _currentCGPA;
  final Map<String, double> _semesterGPAs = {};
  final Map<String, List<AcademicRecord>> _recordsBySemester = {};

  // Getters for accessing state
  List<AcademicRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get currentCGPA => _currentCGPA;
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

  /// Fetch all records from API
  Future<void> fetchRecords() async {
    _setLoading(true);
    _clearError();

    try {
      final records = await _api.getAllRecords();

      _records = records;
      _updateCalculatedValues();
      _groupRecordsBySemester();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load records: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
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

      return true;
    } catch (e) {
      _setError('Failed to add record: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
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

      return true;
    } catch (e) {
      _setError('Failed to update record: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
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

      return true;
    } catch (e) {
      _setError('Failed to delete record: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
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
    notifyListeners();
  }

  /// Refresh data (same as fetchRecords but with different semantics)
  Future<void> refreshData() async {
    await fetchRecords();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    if (kDebugMode) {
      print('AcademicRecordsProvider Error: $error');
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _updateCalculatedValues() {
    if (_records.isNotEmpty) {
      // Get CGPA from first record (all records should have same CGPA)
      _currentCGPA = _records.first.cgpa;

      // Extract semester GPAs from records
      _semesterGPAs.clear();
      for (var record in _records) {
        if (record.obtainedGrade != null && record.obtainedGrade! > 0) {
          _semesterGPAs[record.semester] = record.obtainedGrade!;
        }
      }
    } else {
      _currentCGPA = 0.0;
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
      } else {
        // Handle semesters not in predefined list
        if (!_recordsBySemester.containsKey(semester)) {
          _recordsBySemester[semester] = [];
        }
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

    // Add any additional semesters not in predefined list
    for (String semester in allSemesters) {
      if (!semesterOrder.contains(semester)) {
        result.add(semester);
      }
    }

    return result;
  }

  /// Check if there are any records
  bool get hasRecords => _records.isNotEmpty;

  /// Check if there's an error
  bool get hasError => _errorMessage != null;

  /// Initialize with empty state (useful for testing or reset)
  void initializeEmptyState() {
    _records.clear();
    _recordsBySemester.clear();
    _semesterGPAs.clear();
    _currentCGPA = 0.0;
    _errorMessage = null;
    _isLoading = false;

    // Initialize empty semester structure
    for (String semester in semesterOrder) {
      _recordsBySemester[semester] = [];
      _semesterGPAs[semester] = 0.0;
    }

    notifyListeners();
  }
}

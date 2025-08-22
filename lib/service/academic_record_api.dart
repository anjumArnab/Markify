import 'dart:convert';
import '../service/app_script_url.dart';
import '../model/academic_record.dart';
import 'package:http/http.dart' as http;

class AcademicRecordsApi {
  static const baseUrl = APP_SCRIPT_URL;

  /// GET all academic records
  Future<List<AcademicRecord>> getAllRecords() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == "SUCCESS" &&
            jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((item) => AcademicRecord.fromJson(item))
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load records');
        }
      } else {
        throw Exception('Failed to load records: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// GET academic records filtered by semester
  Future<List<AcademicRecord>> getRecordsBySemester(String semester) async {
    try {
      final Uri uri =
          Uri.parse('$baseUrl?semester=${Uri.encodeComponent(semester)}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == "SUCCESS" &&
            jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((item) => AcademicRecord.fromJson(item))
              .toList();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load records');
        }
      } else {
        throw Exception('Failed to load records: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// POST create a new academic record
  Future<AcademicRecord> createRecord(AcademicRecord record) async {
    try {
      // Validate record before sending
      if (!record.isValid()) {
        throw Exception('Invalid record data. Please check all fields.');
      }

      final Uri uri = Uri.parse('$baseUrl?action=create'
          '&semester=${Uri.encodeComponent(record.semester)}'
          '&course=${Uri.encodeComponent(record.course)}'
          '&grade=${record.grade}'
          '&creditHours=${record.creditHours}');

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == "SUCCESS") {
          // After successful creation, fetch all records to get the updated calculations
          final allRecords = await getAllRecords();

          // Find the newly created record (it should be the last one with matching data)
          final newRecord = allRecords.lastWhere(
            (r) =>
                r.semester == record.semester &&
                r.course == record.course &&
                r.grade == record.grade &&
                r.creditHours == record.creditHours,
            orElse: () => record, // Fallback to original record if not found
          );

          return newRecord;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to create record');
        }
      } else {
        throw Exception('Failed to create record: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// POST update an existing academic record
  Future<AcademicRecord> updateRecord(AcademicRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Record ID is required for update');
      }

      // Validate record before sending
      if (!record.isValid()) {
        throw Exception('Invalid record data. Please check all fields.');
      }

      final Uri uri = Uri.parse('$baseUrl?action=update'
          '&id=${record.id}'
          '&semester=${Uri.encodeComponent(record.semester)}'
          '&course=${Uri.encodeComponent(record.course)}'
          '&grade=${record.grade}'
          '&creditHours=${record.creditHours}');

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == "SUCCESS") {
          // After successful update, fetch the updated record to get recalculated values
          return await getRecordById(record.id!);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to update record');
        }
      } else {
        throw Exception('Failed to update record: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// GET a specific record by ID
  Future<AcademicRecord> getRecordById(int id) async {
    try {
      final Uri uri = Uri.parse('$baseUrl?id=$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == "SUCCESS" &&
            jsonResponse['data'] != null) {
          return AcademicRecord.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load record');
        }
      } else {
        throw Exception('Failed to load record: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// POST delete an academic record
  Future<void> deleteRecord(int id) async {
    try {
      final Uri uri = Uri.parse('$baseUrl?action=delete&id=$id');
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] != "SUCCESS") {
          throw Exception(jsonResponse['message'] ?? 'Failed to delete record');
        }
      } else {
        throw Exception('Failed to delete record: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// GET semester-wise GPA summary
  Future<Map<String, double>> getSemesterGPAs() async {
    try {
      final records = await getAllRecords();
      final Map<String, double> semesterGPAs = {};

      for (final record in records) {
        if (record.obtainedGrade != null) {
          semesterGPAs[record.semester] = record.obtainedGrade!;
        }
      }

      return semesterGPAs;
    } catch (e) {
      throw Exception('Error getting semester GPAs: ${e.toString()}');
    }
  }

  /// GET current CGPA
  Future<double?> getCurrentCGPA() async {
    try {
      final records = await getAllRecords();

      if (records.isNotEmpty && records.first.cgpa != null) {
        return records.first.cgpa; // All records should have the same CGPA
      }

      return null;
    } catch (e) {
      throw Exception('Error getting CGPA: ${e.toString()}');
    }
  }

  /// Utility method to get unique semesters
  Future<List<String>> getUniqueSemesters() async {
    try {
      final records = await getAllRecords();
      final semesters = records.map((r) => r.semester).toSet().toList();
      semesters.sort(); // Sort semesters
      return semesters;
    } catch (e) {
      throw Exception('Error getting semesters: ${e.toString()}');
    }
  }
}

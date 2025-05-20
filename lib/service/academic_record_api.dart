import 'dart:convert';
import '../model/academic_record.dart';
import 'package:http/http.dart' as http;

class AcademicRecordsApi {
  final String baseUrl;

  /// Constructor that takes the Google Apps Script web app URL
  AcademicRecordsApi({required this.baseUrl});

  /// GET all academic records
  Future<List<AcademicRecord>> getAllRecords() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
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

  /// GET a specific record by ID
  Future<AcademicRecord> getRecordById(int id) async {
    try {
      final Uri uri = Uri.parse('$baseUrl?id=$id');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
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

  /// GET records filtered by semester
  Future<List<AcademicRecord>> getRecordsBySemester(String semester) async {
    try {
      final Uri uri = Uri.parse('$baseUrl?semester=$semester');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((item) => AcademicRecord.fromJson(item))
              .toList();
        } else {
          throw Exception(
              jsonResponse['message'] ?? 'Failed to load records for semester');
        }
      } else {
        throw Exception('Failed to load records: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }

  /// POST create a new academic record
  Future<void> createRecord(AcademicRecord record) async {
    try {
      final Uri uri = Uri.parse('$baseUrl?action=create'
          '&semester=${Uri.encodeComponent(record.semester)}'
          '&course=${Uri.encodeComponent(record.course)}'
          '&grade=${record.grade}'
          '&creditHours=${record.creditHours}');

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] != true) {
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
  Future<void> updateRecord(AcademicRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Record ID is required for update');
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

        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['message'] ?? 'Failed to update record');
        }
      } else {
        throw Exception('Failed to update record: HTTP ${response.statusCode}');
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

        if (jsonResponse['success'] != true) {
          throw Exception(jsonResponse['message'] ?? 'Failed to delete record');
        }
      } else {
        throw Exception('Failed to delete record: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: ${e.toString()}');
    }
  }
}

import 'package:dio/dio.dart';
import '../app_script_url.dart';
import '../model/academic_record.dart';

class AcademicRecordsApi {
  static const baseUrl = APP_SCRIPT_URL;

  late final Dio _dio;

  AcademicRecordsApi() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  /// GET all academic records
  Future<List<AcademicRecord>> getAllRecords() async {
    try {
      final response = await _dio.get('');

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// GET academic records by semester
  Future<List<AcademicRecord>> getRecordsBySemester(String semester) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'semester': semester},
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;

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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// POST create a new academic record
  Future<AcademicRecord> createRecord(AcademicRecord record) async {
    try {
      // Validate record before sending
      if (!record.isValid()) {
        throw Exception('Invalid record data. Please check all fields.');
      }

      final response = await _dio.post(
        '',
        queryParameters: {
          'action': 'create',
          'semester': record.semester,
          'course': record.course,
          'grade': record.grade,
          'creditHours': record.creditHours,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;

        if (jsonResponse['status'] == "SUCCESS") {
          // To get the updated calculations
          final allRecords = await getAllRecords();

          // Find the newly created record
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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// POST update an existing academic record
  Future<AcademicRecord> updateRecord(AcademicRecord record) async {
    try {
      if (record.id == null) {
        throw Exception('Record ID is required for update');
      }

      if (!record.isValid()) {
        throw Exception('Invalid record data. Please check all fields.');
      }

      final response = await _dio.post(
        '',
        queryParameters: {
          'action': 'update',
          'id': record.id,
          'semester': record.semester,
          'course': record.course,
          'grade': record.grade,
          'creditHours': record.creditHours,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;

        if (jsonResponse['status'] == "SUCCESS") {
          // After successful update, fetch the updated record to get recalculated values
          return await getRecordById(record.id!);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to update record');
        }
      } else {
        throw Exception('Failed to update record: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// GET a specific record by ID
  Future<AcademicRecord> getRecordById(int id) async {
    try {
      final response = await _dio.get(
        '',
        queryParameters: {'id': id},
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;

        if (jsonResponse['status'] == "SUCCESS" &&
            jsonResponse['data'] != null) {
          return AcademicRecord.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to load record');
        }
      } else {
        throw Exception('Failed to load record: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// POST delete an academic record
  Future<void> deleteRecord(int id) async {
    try {
      final response = await _dio.post(
        '',
        queryParameters: {
          'action': 'delete',
          'id': id,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = response.data;

        if (jsonResponse['status'] != "SUCCESS") {
          throw Exception(jsonResponse['message'] ?? 'Failed to delete record');
        }
      } else {
        throw Exception('Failed to delete record: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    }
  }

  /// Handle Dio errors with meaningful messages
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. The server is taking too long to respond.';
      case DioExceptionType.badResponse:
        return 'Bad response from server: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.unknown:
      default:
        return 'Network error: ${error.message}';
    }
  }
}

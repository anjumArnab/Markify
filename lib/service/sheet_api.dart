import 'dart:convert';
import '/model/course.dart';
import '/service/app_script_url.dart';
import 'package:http/http.dart' as http;

class SheetApi {
  static const String baseUrl = APP_SCRIPT_URL;

  /// Add a new course to the sheet
  static Future<bool> addCourse(Course course) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'add',
        ...course.toJson(),
      },
    );

    return response.statusCode == 200;
  }

  /// Fetch all courses from the sheet
  static Future<List<Course>> getCourses() async {
    final response = await http.get(Uri.parse('$baseUrl?action=read'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Course.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  /// Update a course by ID
  static Future<bool> updateCourse(Course course) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'update',
        ...course.toJson(),
      },
    );

    return response.statusCode == 200;
  }

  /// Delete a course by ID
  static Future<bool> deleteCourse(String id) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      body: {
        'action': 'delete',
        'id': id,
      },
    );

    return response.statusCode == 200;
  }

  /// Fetch current CGPA
  static Future<String> getCGPA() async {
    final response = await http.get(Uri.parse('$baseUrl?action=get_cgpa'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['cgpa'].toString();
    } else {
      throw Exception('Failed to fetch CGPA');
    }
  }
}

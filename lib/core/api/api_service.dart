import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({this.data, this.error, required this.statusCode});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  final String baseUrl = AppConfig.apiBaseUrl;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
  }

  void setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  void clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _ensureFreshToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<String?> _ensureFreshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final freshToken = await user.getIdToken(true);
        if (freshToken != _token) {
          _token = freshToken;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConfig.tokenKey, freshToken!);
        }
        return freshToken;
      } catch (e) {
        // Firebase refresh failed, fall back to stored token
      }
    }
    return _token;
  }

  Future<ApiResponse<Map<String, dynamic>>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(error: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(error: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(error: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(error: e.toString(), statusCode: 0);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> upload(String endpoint, List<int> bytes, String filename, {String? folder}) async {
    try {
      final token = await _ensureFreshToken();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll({'Authorization': token != null ? 'Bearer $token' : ''});

      String mediaSubtype = 'jpeg';
      final lower = filename.toLowerCase();
      if (lower.endsWith('.png')) mediaSubtype = 'png';
      else if (lower.endsWith('.webp')) mediaSubtype = 'webp';
      else if (lower.endsWith('.gif')) mediaSubtype = 'gif';

      request.files.add(http.MultipartFile.fromBytes(
        'file', bytes,
        filename: filename,
        contentType: http.MediaType('image', mediaSubtype),
      ));
      if (folder != null) request.fields['folder'] = folder;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } catch (e) {
      return ApiResponse(error: e.toString(), statusCode: 0);
    }
  }

  ApiResponse<Map<String, dynamic>> _parseResponse(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ApiResponse(data: decoded, statusCode: response.statusCode);
      }
      // API returned a JSON array like [{...}] instead of {"key": [...]}
      // Wrap it in a 'data' key so callers can still access it
      if (decoded is List) {
        return ApiResponse(
          data: <String, dynamic>{'data': decoded},
          statusCode: response.statusCode,
        );
      }
      return ApiResponse(error: 'Invalid response type: ${decoded.runtimeType}', statusCode: response.statusCode);
    } catch (e) {
      return ApiResponse(error: 'Parse error: $e', statusCode: response.statusCode);
    }
  }
}

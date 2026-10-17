import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // URL backend Laravel untuk Chrome dan Android Emulator.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  // Token autentikasi pengguna yang sedang login.
  static String? token;

  // Header request.
  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 200) {
      final receivedToken = result['token'];

      if (receivedToken is String && receivedToken.isNotEmpty) {
        token = receivedToken;
      } else {
        throw Exception('Login berhasil, tetapi token tidak ditemukan.');
      }

      return result;
    }

    throw Exception(
      result['message'] ?? 'Login gagal (${response.statusCode}).',
    );
  }

  // =========================
  // REGISTER
  // =========================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 201) {
      // Menyimpan token jika endpoint register mengembalikannya.
      final receivedToken = result['token'];

      if (receivedToken is String && receivedToken.isNotEmpty) {
        token = receivedToken;
      }

      return result;
    }

    throw Exception(
      result['message'] ?? 'Registrasi gagal (${response.statusCode}).',
    );
  }

  // =========================
  // MENGAMBIL DATA PENGGUNA
  // =========================
  static Future<Map<String, dynamic>> getUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: _headers,
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 200) {
      return result;
    }

    throw Exception(
      result['message'] ?? 'Gagal mengambil data pengguna.',
    );
  }

  // =========================
  // MENGAMBIL DAFTAR AKTIVITAS
  // =========================
  static Future<List<dynamic>> getActivities() async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: _headers,
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 200) {
      final data = result['data'];

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      result['message'] ??
          'Gagal mengambil aktivitas (${response.statusCode}).',
    );
  }

  // =========================
  // MENYIMPAN AKTIVITAS
  // =========================
  static Future<Map<String, dynamic>> createActivity({
    required String sportType,
    required double distanceKm,
    required int durationSeconds,
    String? title,
    int? calories,
    DateTime? startedAt,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activities'),
      headers: _headers,
      body: jsonEncode({
        'sport_type': sportType,
        'title': title,
        'distance_km': distanceKm,
        'duration_seconds': durationSeconds,
        'calories': calories,
        'started_at':
            (startedAt ?? DateTime.now()).toIso8601String(),
        'description': description,
      }),
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 201) {
      return result;
    }

    throw Exception(
      result['message'] ??
          'Gagal menyimpan aktivitas (${response.statusCode}).',
    );
  }


  // =========================
  // MENYIMPAN TITIK RUTE GPS
  // =========================
  static Future<void> saveActivityRoute({
    required int activityId,
    required List<Map<String, dynamic>> routePoints,
  }) async {
    if (routePoints.isEmpty) {
      return;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/activities/$activityId/route'),
      headers: _headers,
      body: jsonEncode({
        'route_points': routePoints,
      }),
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 201) {
      return;
    }

    throw Exception(
      result['message'] ??
          'Gagal menyimpan rute GPS (${response.statusCode}).',
    );
  }

  // =========================
  // MENGAMBIL TITIK RUTE GPS
  // =========================
  static Future<List<dynamic>> getActivityRoute(
    int activityId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activities/$activityId/route'),
      headers: _headers,
    );

    final Map<String, dynamic> result = _decodeResponse(response);

    if (response.statusCode == 200) {
      final points = result['route_points'];
      return points is List ? points : [];
    }

    throw Exception(
      result['message'] ??
          'Gagal mengambil rute GPS (${response.statusCode}).',
    );
  }

  // =========================
  // LOGOUT
  // =========================
  static Future<void> logout() async {
    if (token == null) {
      return;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      token = null;
      return;
    }

    throw Exception(
      'Logout gagal (${response.statusCode}).',
    );
  }

  // =========================
  // MEMBACA RESPONS API
  // =========================
  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'data': decoded};
    } on FormatException {
      throw Exception(
        'Respons server bukan JSON yang valid '
        '(HTTP ${response.statusCode}).',
      );
    }
  }
}

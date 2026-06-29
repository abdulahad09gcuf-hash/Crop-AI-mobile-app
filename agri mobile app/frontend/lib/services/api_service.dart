// lib/services/api_service.dart
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Update this IP to match your PC's current WiFi IP
  static const String _pcWifiIp = '192.168.10.7';

  static String baseUrl = _defaultUrl();

  static String _defaultUrl() {
    if (kIsWeb) return 'http://localhost:5000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$_pcWifiIp:5000';
      case TargetPlatform.iOS:
        return 'http://$_pcWifiIp:5000';
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://$_pcWifiIp:5000';
      default:
        return 'http://$_pcWifiIp:5000';
    }
  }

  static String _fallbackBaseUrl() {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://$_pcWifiIp:5000';
  }

  static String normalizeBaseUrl(String? value) {
    final cleaned = (value ?? '').trim();
    if (cleaned.isEmpty) return _fallbackBaseUrl();

    final withoutTrailingSlash = cleaned.replaceAll(RegExp(r'/+$'), '');
    if (!withoutTrailingSlash.startsWith('http://') &&
        !withoutTrailingSlash.startsWith('https://')) {
      return 'http://$withoutTrailingSlash';
    }
    return withoutTrailingSlash;
  }

  static Uri buildUri(String path) {
    final normalizedBase = normalizeBaseUrl(baseUrl);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  static final _client = http.Client();

  // ── JWT token ─────────────────────────────────────────────────────────────
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Call once at startup — restores JWT token.
  /// Always overrides saved URL with the current hardcoded IP so stale
  /// SharedPreferences never cause a connection timeout after IP change.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ KEY FIX: Always reset saved URL to current hardcoded IP.
    // This prevents stale IP stored in SharedPreferences from breaking login
    // after your PC's WiFi IP changes — no reinstall required.
    baseUrl = _defaultUrl();
    await prefs.setString('server_url', baseUrl);

    final savedToken = prefs.getString('jwt_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        try {
          _currentUser = json.decode(userJson);
        } catch (_) {}
      }
    }
  }

  /// Save server URL to SharedPreferences (called from Settings screen)
  static Future<void> saveServerUrl(String url) async {
    final normalizedUrl = normalizeBaseUrl(url);
    baseUrl = normalizedUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', normalizedUrl);
  }

  static Future<void> _saveToken(
      String token, Map<String, dynamic> user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('current_user', json.encode(user));
  }

  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('current_user');
  }

  // ── Auth headers ──────────────────────────────────────────────────────────
  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Error parser ──────────────────────────────────────────────────────────
  static String _parseError(dynamic e) {
    final s = e.toString();
    if (s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Failed to fetch') ||
        s.contains('XMLHttpRequest') ||
        s.contains('NetworkException') ||
        s.contains('uri=')) {
      return 'Cannot reach server.\n'
          '• Make sure python app.py is running\n'
          '• Phone and PC must be on the same WiFi\n'
          '• Current server: $baseUrl\n'
          '• Update IP in Settings tab if it changed';
    }
    if (s.contains('TimeoutException')) {
      return 'Connection timed out.\n'
          '• Is python app.py still running?\n'
          '• Current server: $baseUrl\n'
          '• Update IP in Settings tab if it changed';
    }
    return s.replaceFirst('Exception: ', '');
  }

  // ── Signup ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client
          .post(
            buildUri('/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: json
                .encode({'name': name, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final data = json.decode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        await _saveToken(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client
          .post(
            buildUri('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      final data = json.decode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        await _saveToken(data['token'], data['user']);
      }
      return data;
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── Health Check ──────────────────────────────────────────────────────────
  static Future<bool> healthCheck() async {
    try {
      final res = await _client
          .get(buildUri('/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Predict ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> predict(
    XFile xfile,
    Uint8List imageBytes,
  ) async {
    try {
      final uri = buildUri('/predict');
      final request = http.MultipartRequest('POST', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      final filename = xfile.name.isNotEmpty ? xfile.name : 'image.jpg';
      final mimeType = lookupMimeType(filename) ?? 'image/jpeg';
      final mimeParts = mimeType.split('/');
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
        contentType: MediaType(mimeParts[0], mimeParts[1]),
      ));
      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode == 200) return json.decode(res.body);
      if (res.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final body = json.decode(res.body);
      throw Exception(body['error'] ?? 'Prediction failed (${res.statusCode})');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── History ───────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getHistory({int limit = 50}) async {
    try {
      final res = await _client
          .get(buildUri('/history?limit=$limit'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return json.decode(res.body)['records'] as List<dynamic>;
      }
      if (res.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception('Failed to load history (${res.statusCode})');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  static Future<Map<String, dynamic>> getHistoryDetail(String id) async {
    try {
      final res = await _client
          .get(buildUri('/history/$id'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return json.decode(res.body)['record'];
      throw Exception('Record not found');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  static Future<bool> deleteRecord(String id) async {
    try {
      final res = await _client
          .delete(buildUri('/history/$id'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<int> clearHistory() async {
    try {
      final res = await _client
          .delete(buildUri('/history'), headers: _authHeaders)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final msg = json.decode(res.body)['message'].toString();
        final digits = msg.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isEmpty ? 0 : int.tryParse(digits) ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Classes ───────────────────────────────────────────────────────────────
  static Future<List<String>> getClasses() async {
    try {
      final res = await _client
          .get(buildUri('/classes'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return List<String>.from(json.decode(res.body)['classes']);
      }
      throw Exception('Failed to load classes');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── Model Info ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getModelInfo() async {
    try {
      final res = await _client
          .get(buildUri('/model-info'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return json.decode(res.body);
      throw Exception('Model info unavailable');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final res = await _client
          .get(buildUri('/stats'), headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return json.decode(res.body);
      throw Exception('Stats unavailable');
    } catch (e) {
      throw Exception(_parseError(e));
    }
  }
}

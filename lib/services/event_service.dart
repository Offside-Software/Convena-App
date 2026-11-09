import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import 'api_config.dart';

class EventService extends ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetch live events directly from the API endpoint.
  Future<List<Event>> fetchEvents({String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'semua') {
        queryParams['category'] = category.toLowerCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse(
        '$baseUrl/api/events',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          _events = decoded
              .map((item) => Event.fromJson(item as Map<String, dynamic>))
              .toList();

          if (category != null &&
              category.isNotEmpty &&
              category.toLowerCase() != 'semua') {
            _events = _events
                .where(
                  (e) => e.category.toLowerCase() == category.toLowerCase(),
                )
                .toList();
          }
          if (search != null && search.trim().isNotEmpty) {
            final query = search.trim().toLowerCase();
            _events = _events.where((e) {
              return e.title.toLowerCase().contains(query) ||
                  (e.shortDescription?.toLowerCase().contains(query) ??
                      false) ||
                  (e.city?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          _isLoading = false;
          notifyListeners();
          return _events;
        } else {
          throw Exception('Format respons event tidak sesuai');
        }
      } else {
        final errorMsg = 'Gagal memuat event (${response.statusCode})';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        throw Exception(errorMsg);
      }
    } on SocketException catch (_) {
      final errorMsg =
          'Tidak dapat terhubung ke server API di $baseUrl. Pastikan server aktif.';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } on http.ClientException catch (e) {
      final errorMsg = 'Gagal terhubung ke API: ${e.message}';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch single event detail by ID
  Future<Event?> fetchEventById(String id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/events/$id');
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Event.fromJson(decoded);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Register for an event ticket tier (Free Tier -> immediate confirmed; Paid Tier -> QRIS/Bank confirmed)
  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    required String tierId,
    String? paymentMethod,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeeInstitution,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/api/events/$eventId/register');
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'tierId': tierId,
            'paymentMethod': ?paymentMethod,
            'attendeeName': ?attendeeName,
            'attendeeEmail': ?attendeeEmail,
            'attendeeInstitution': ?attendeeInstitution,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return decoded is Map<String, dynamic>
          ? decoded
          : {'message': 'Berhasil'};
    } else {
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Pendaftaran gagal (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Scan & verify organizer's Event Attendance QR code (checks registration & paid status)
  Future<Map<String, dynamic>> attendEventByQr(String qrCode) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/api/events/attend');
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'qrCode': qrCode.trim()}),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic>
          ? decoded
          : {'message': 'Presensi berhasil!'};
    } else {
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Verifikasi QR gagal (${response.statusCode})';
      throw Exception(msg);
    }
  }
}

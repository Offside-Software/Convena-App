import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  /// Fetch live events directly from the API endpoint. No mock fallbacks.
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

          // Client-side search & category filtering as backup if API returns all
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
}

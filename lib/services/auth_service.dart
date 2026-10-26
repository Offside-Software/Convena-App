import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;

  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthService(this._prefs) {
    _loadFromPrefs();
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static String get baseUrl {
    // Android emulator cannot access 127.0.0.1 (it refers to the emulator itself)
    // 10.0.2.2 maps to host machine localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:6969';
    }
    return 'http://127.0.0.1:6969';
  }

  void _loadFromPrefs() {
    _token = _prefs.getString('auth_token');
    final userRaw = _prefs.getString('auth_user');
    if (userRaw != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      } catch (e) {
        _currentUser = null;
      }
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data as Map<String, dynamic>);
        _token = authResponse.token;
        _currentUser = authResponse.user;

        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
      } else {
        final msg = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Login gagal (${response.statusCode})';
        final code = data is Map && data['code'] != null ? data['code'].toString() : null;
        _errorMessage = msg;
        _isLoading = false;
        notifyListeners();
        throw AuthException(msg, code: code);
      }
    } on SocketException catch (_) {
      final msg = 'Tidak dapat terhubung ke server di $baseUrl';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      throw AuthException(msg);
    } on http.ClientException catch (e) {
      final msg = 'Gagal terhubung: ${e.message}';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      throw AuthException(msg);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is AuthException) rethrow;
      final msg = 'Terjadi kesalahan: $e';
      _errorMessage = msg;
      throw AuthException(msg);
    }
  }

  Future<void> register(
    String username,
    String email,
    String password, {
    String? name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$baseUrl/api/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'email': email.trim(),
              'password': password,
              if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data as Map<String, dynamic>);
        _token = authResponse.token;
        _currentUser = authResponse.user;

        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
        _isLoading = false;
        notifyListeners();
      } else {
        final msg = data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Registrasi gagal (${response.statusCode})';
        final code = data is Map && data['code'] != null ? data['code'].toString() : null;
        _errorMessage = msg;
        _isLoading = false;
        notifyListeners();
        throw AuthException(msg, code: code);
      }
    } on SocketException catch (_) {
      final msg = 'Tidak dapat terhubung ke server di $baseUrl';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      throw AuthException(msg);
    } on http.ClientException catch (e) {
      final msg = 'Gagal terhubung: ${e.message}';
      _errorMessage = msg;
      _isLoading = false;
      notifyListeners();
      throw AuthException(msg);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      if (e is AuthException) rethrow;
      final msg = 'Terjadi kesalahan: $e';
      _errorMessage = msg;
      throw AuthException(msg);
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _prefs.remove('auth_token');
    await _prefs.remove('auth_user');
    notifyListeners();
  }
}

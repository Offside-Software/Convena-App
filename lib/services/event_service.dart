import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event.dart';
import 'api_config.dart';

class EventService extends ChangeNotifier {
  static final StreamController<AttendanceRealtimeEvent> _attendanceBus =
      StreamController<AttendanceRealtimeEvent>.broadcast();
  static final Map<String, EventRegistration> _myRegistrationsCache = {};

  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<AttendanceRealtimeEvent> get attendanceStream => _attendanceBus.stream;

  EventRegistration? getCachedRegistration(String eventId) =>
      _myRegistrationsCache[eventId];

  static String get baseUrl => ApiConfig.baseUrl;

  void emitAttendanceEvent(AttendanceRealtimeEvent event) {
    _myRegistrationsCache[event.registration.eventId] = event.registration;
    if (!_attendanceBus.isClosed) {
      _attendanceBus.add(event);
    }
    notifyListeners();
  }

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

  /// Fetch current user's registration for a specific event
  Future<EventRegistration?> getMyRegistration(String eventId) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/api/events/$eventId/my-registration');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> &&
            decoded['registration'] is Map<String, dynamic>) {
          final reg = EventRegistration.fromJson(
            decoded['registration'] as Map<String, dynamic>,
          );
          _myRegistrationsCache[eventId] = reg;
          notifyListeners();
          return reg;
        }
      }
      return _myRegistrationsCache[eventId];
    } catch (_) {
      return _myRegistrationsCache[eventId];
    }
  }

  /// Fetch all registrations for the current authenticated user
  Future<List<EventRegistration>> getMyRegistrations() async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('$baseUrl/api/events/my-registrations');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final list = decoded
              .whereType<Map<String, dynamic>>()
              .map(EventRegistration.fromJson)
              .toList();
          for (final reg in list) {
            _myRegistrationsCache[reg.eventId] = reg;
          }
          notifyListeners();
          return list;
        }
      }
      return _myRegistrationsCache.values.toList();
    } catch (_) {
      return _myRegistrationsCache.values.toList();
    }
  }

  /// Register for an event ticket tier (Free Tier -> immediate confirmed; Paid Tier -> QRIS/Bank confirmed)
  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    required String tierId,
    String? paymentMethod,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
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
            'attendeePhone': ?attendeePhone,
            'attendeeInstitution': ?attendeeInstitution,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'message': 'Berhasil'};
      if (map['registration'] is Map<String, dynamic>) {
        final reg = EventRegistration.fromJson(
          map['registration'] as Map<String, dynamic>,
        );
        emitAttendanceEvent(
          AttendanceRealtimeEvent(
            eventType: 'registration.created',
            eventId: reg.eventId.isNotEmpty ? reg.eventId : eventId,
            eventTitle: map['eventTitle']?.toString() ?? 'Event Convena',
            alreadyCheckedIn: false,
            message:
                map['message']?.toString() ??
                'Pendaftaran tiket ${reg.tierName} berhasil!',
            registration: reg,
            timestamp: DateTime.now(),
          ),
        );
      }
      return map;
    } else {
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Pendaftaran gagal (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Scan & verify organizer's Event Attendance QR code (checks registration & paid status)
  Future<Map<String, dynamic>> attendEventByQr(
    String qrCode, {
    String? eventId,
  }) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$baseUrl/api/events/attend');
    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({'qrCode': qrCode.trim(), 'eventId': ?eventId}),
        )
        .timeout(const Duration(seconds: 10));

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final map = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'message': 'Presensi berhasil!'};
      if (map['registration'] is Map<String, dynamic>) {
        final reg = EventRegistration.fromJson(
          map['registration'] as Map<String, dynamic>,
        );
        emitAttendanceEvent(
          AttendanceRealtimeEvent(
            eventType: 'attendance.checked_in',
            eventId: reg.eventId.isNotEmpty ? reg.eventId : (eventId ?? ''),
            eventTitle: map['eventTitle']?.toString() ?? 'Event Convena',
            alreadyCheckedIn: map['alreadyCheckedIn'] == true,
            message:
                map['message']?.toString() ??
                'Presensi kehadiran ${reg.attendeeName} berhasil!',
            registration: reg,
            timestamp: DateTime.now(),
          ),
        );
      }
      return map;
    } else {
      final msg = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Verifikasi QR gagal (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Subscribe to real-time attendance & registration events for [eventId].
  /// Connects to the backend SSE stream `/api/events/{id}/attendance-stream`
  /// and includes a delta-sync timer so mobile immediately reacts when the organizer
  /// or another device updates attendance status.
  StreamSubscription<AttendanceRealtimeEvent> subscribeToEventAttendance({
    required String eventId,
    required void Function(AttendanceRealtimeEvent event) onEvent,
  }) {
    bool isCancelled = false;
    http.Client? sseClient;
    Timer? pollTimer;
    String? lastKnownStatus = _myRegistrationsCache[eventId]?.status;

    final busSub = attendanceStream.listen((evt) {
      if (!isCancelled && evt.eventId == eventId) {
        lastKnownStatus = evt.registration.status;
        onEvent(evt);
      }
    });

    // Connect to SSE stream from Convena-API
    Future<void> connectSse() async {
      if (isCancelled) return;
      try {
        sseClient = http.Client();
        final uri = Uri.parse('$baseUrl/api/events/$eventId/attendance-stream');
        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'text/event-stream';
        final response = await sseClient!.send(request);
        if (response.statusCode == 200) {
          response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                (line) {
                  if (isCancelled) return;
                  if (line.startsWith('data:')) {
                    final rawJson = line.substring(5).trim();
                    if (rawJson.isNotEmpty) {
                      try {
                        final decoded = jsonDecode(rawJson);
                        if (decoded is Map<String, dynamic>) {
                          final evt = AttendanceRealtimeEvent.fromJson(decoded);
                          emitAttendanceEvent(evt);
                        }
                      } catch (_) {
                        // ignore non-JSON keep-alive frames
                      }
                    }
                  }
                },
                onError: (_) {},
                cancelOnError: false,
              );
        }
      } catch (_) {
        // Fallback handled by delta polling below
      }
    }

    connectSse();

    // Delta-sync fallback every 3 seconds
    pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (isCancelled) return;
      final latest = await getMyRegistration(eventId);
      if (isCancelled || latest == null) return;
      if (lastKnownStatus != null &&
          lastKnownStatus != 'checked_in' &&
          latest.status == 'checked_in') {
        lastKnownStatus = latest.status;
        emitAttendanceEvent(
          AttendanceRealtimeEvent(
            eventType: 'attendance.checked_in',
            eventId: eventId,
            eventTitle: 'Event Convena',
            alreadyCheckedIn: false,
            message:
                '${latest.attendeeName} (${latest.ticketCode}) berhasil tercatat HADIR!',
            registration: latest,
            timestamp: latest.checkedInAt ?? DateTime.now(),
          ),
        );
      } else {
        lastKnownStatus = latest.status;
      }
    });

    return _ManagedAttendanceSubscription(
      inner: busSub,
      onCancel: () {
        isCancelled = true;
        pollTimer?.cancel();
        sseClient?.close();
      },
    );
  }
}

class _ManagedAttendanceSubscription
    implements StreamSubscription<AttendanceRealtimeEvent> {
  final StreamSubscription<AttendanceRealtimeEvent> inner;
  final VoidCallback onCancel;

  _ManagedAttendanceSubscription({required this.inner, required this.onCancel});

  @override
  Future<void> cancel() {
    onCancel();
    return inner.cancel();
  }

  @override
  void onData(void Function(AttendanceRealtimeEvent data)? handleData) =>
      inner.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => inner.onDone(handleDone);

  @override
  void onError(Function? handleError) => inner.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) => inner.pause(resumeSignal);

  @override
  void resume() => inner.resume();

  @override
  bool get isPaused => inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => inner.asFuture(futureValue);
}

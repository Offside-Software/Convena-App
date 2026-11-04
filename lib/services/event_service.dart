import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';

class EventService extends ChangeNotifier {
  List<Event> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:6969';
    }
    return 'http://127.0.0.1:6969';
  }

  static final List<Event> _fallbackEvents = [
    Event(
      id: 'evt-arkadivia-2026',
      createdBy: 'org-hmif',
      title: 'Arkadivia 2026',
      slug: 'arkadivia-2026',
      description:
          'Kompetisi IT dan Summit tingkat nasional tahunan terbesar yang diselenggarakan oleh HMIF ITB. Rangkaian acara meliputi Hackathon, Capture The Flag, UI/UX Design, serta Tech Seminar bersama praktisi industri.',
      shortDescription:
          'Kompetisi IT & Summit Nasional oleh HMIF ITB di Aula Barat ITB.',
      bannerUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
      category: 'competition',
      startDate: DateTime(2026, 11, 20, 9, 0),
      endDate: DateTime(2026, 11, 22, 17, 0),
      locationType: 'offline',
      venueName: 'Aula Barat ITB',
      address:
          'Institut Teknologi Bandung, Jl. Ganesa No. 10, Lb. Siliwangi, Coblong, Kota Bandung',
      city: 'Bandung',
      organizationName: 'HMIF ITB',
      company: 'ITB Bandung',
      createdAt: DateTime(2026, 10, 1),
      ticketTiers: const [
        TicketTier(
          id: 'tier-reg-1',
          name: 'Regular Summit Pass',
          price: 0,
          quota: 300,
          sold: 145,
          benefits: [
            'Akses penuh ke sesi utama Summit',
            'E-Sertifikat resmi terverifikasi Convena',
          ],
        ),
        TicketTier(
          id: 'tier-vip-1',
          name: 'VIP All-Access Pass',
          price: 75000,
          quota: 100,
          sold: 42,
          benefits: [
            'Kursi baris depan eksklusif',
            'Exclusive Merchandise Kit & Snack',
            'E-Sertifikat resmi terverifikasi Convena',
          ],
        ),
      ],
    ),
    Event(
      id: 'evt-devfest-2026',
      createdBy: 'org-gdsc',
      title: 'Convena Developer Fest 2026',
      slug: 'convena-devfest-2026',
      description:
          'Konferensi teknologi tahunan untuk mahasiswa se-Bandung Raya yang membahas perkembangan AI, Cloud Computing, dan Mobile Development menggunakan Flutter.',
      shortDescription:
          'Konferensi AI, Cloud, & Mobile Development untuk mahasiswa.',
      bannerUrl:
          'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&q=80',
      category: 'seminar',
      startDate: DateTime(2026, 12, 5, 9, 0),
      endDate: DateTime(2026, 12, 5, 16, 0),
      locationType: 'offline',
      venueName: 'Telkom University Convention Hall',
      address: 'Jl. Telekomunikasi No. 1, Terusan Buahbatu, Bandung',
      city: 'Bandung',
      organizationName: 'BEM & GDSC Tel-U',
      company: 'Telkom University',
      createdAt: DateTime(2026, 10, 10),
      ticketTiers: const [
        TicketTier(
          id: 'tier-reg-2',
          name: 'Student Pass',
          price: 50000,
          quota: 500,
          sold: 310,
          benefits: [
            'Akses seluruh sesi konferensi & workshop',
            'Makan siang & Coffee break',
            'E-Sertifikat resmi terverifikasi Convena',
          ],
        ),
        TicketTier(
          id: 'tier-free-2',
          name: 'Early Bird (Mahasiswa Internal)',
          price: 0,
          quota: 150,
          sold: 120,
          benefits: [
            'Akses sesi utama konferensi',
            'E-Sertifikat resmi terverifikasi Convena',
          ],
        ),
      ],
    ),
  ];
  Future<List<Event>> fetchEvents({String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'semua') {
        queryParams['category'] = category.toLowerCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$baseUrl/api/events').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

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
          if (category != null && category.isNotEmpty && category.toLowerCase() != 'semua') {
            _events = _events
                .where((e) => e.category.toLowerCase() == category.toLowerCase())
                .toList();
          }
          if (search != null && search.trim().isNotEmpty) {
            final query = search.trim().toLowerCase();
            _events = _events.where((e) {
              return e.title.toLowerCase().contains(query) ||
                  (e.shortDescription?.toLowerCase().contains(query) ?? false) ||
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
    } catch (e) {
      // Fallback ke data event bawaan jika backend API tidak aktif
      _events = List.from(_fallbackEvents);
      if (category != null &&
          category.isNotEmpty &&
          category.toLowerCase() != 'semua') {
        _events = _events
            .where((ev) => ev.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
      if (search != null && search.trim().isNotEmpty) {
        final query = search.trim().toLowerCase();
        _events = _events.where((ev) {
          return ev.title.toLowerCase().contains(query) ||
              (ev.shortDescription?.toLowerCase().contains(query) ?? false) ||
              (ev.city?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return _events;
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


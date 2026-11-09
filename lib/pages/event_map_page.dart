import 'package:convena/components/bottom_nav_bar.dart';
import 'package:convena/models/event.dart';
import 'package:convena/pages/event_detail_page.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/services/event_service.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';

import '../models/event_location.dart';

class EventMapPage extends StatefulWidget {
  final EventLocation? eventLocation;
  final List<EventLocation>? events;
  final bool showBottomNavBar;

  const EventMapPage({
    super.key,
    this.eventLocation,
    this.events,
    this.showBottomNavBar = true,
  });

  @override
  State<EventMapPage> createState() => _EventMapPageState();
}

class _EventMapPageState extends State<EventMapPage> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.94);

  late List<EventLocation> _allEvents;
  late List<EventLocation> _filteredEvents;
  late EventLocation _selectedEvent;

  int _currentNavIndex = 2;

  static const LatLng _bandungCenter = LatLng(-6.8915, 107.6107);
  static const double _defaultZoom = 16.0;

  static const String _osmOfficialUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Dummy Data
    _allEvents =
        widget.events ??
        [
          const EventLocation(
            eventTitle: 'Arkadivia 2026',
            venueName: 'Aula Barat ITB, Bandung',
            address: 'Institut Teknologi Bandung, Jl. Ganesa No. 10, Lb. Siliwangi, Coblong, Kota Bandung',
            latitude: -6.8915,
            longitude: 107.6107,
            distance: '850 m',
            category: 'competition',
            imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=500&q=80',
          ),
          const EventLocation(
            eventTitle: 'Convena Developer Fest 2026',
            venueName: 'Aula Timur ITB, Bandung',
            address: 'Institut Teknologi Bandung, Jl. Ganesa No. 10, Lb. Siliwangi, Coblong, Kota Bandung',
            latitude: -6.8906,
            longitude: 107.6119,
            distance: '920 m',
            category: 'seminar',
            imageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=500&q=80',
          ),
        ];

    // Jika ada event custom dari parameter, sisipkan di posisi teratas
    if (widget.eventLocation != null) {
      final exists = _allEvents.any(
        (e) =>
            e.latitude == widget.eventLocation!.latitude &&
            e.longitude == widget.eventLocation!.longitude,
      );
      if (!exists) {
        _allEvents.insert(0, widget.eventLocation!);
      }
      _selectedEvent = widget.eventLocation!;
    } else {
      _selectedEvent = _allEvents.first;
    }

    _filteredEvents = List.from(_allEvents);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredEvents = List.from(_allEvents);
      } else {
        _filteredEvents = _allEvents.where((e) {
          return e.eventTitle.toLowerCase().contains(q) ||
              e.venueName.toLowerCase().contains(q) ||
              e.address.toLowerCase().contains(q) ||
              (e.category?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
      if (_filteredEvents.isNotEmpty) {
        _selectedEvent = _filteredEvents.first;
        _mapController.move(_selectedEvent.coordinates, _defaultZoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showBottomNavBar) {
      return _buildMapContent();
    }
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: false,
      body: _buildMapContent(),
      bottomNavigationBar: ConvenaBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == _currentNavIndex) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }

  /// Tampilan Konten Peta & Informasi Event
  Widget _buildMapContent() {
    return Container(
      color: AppColors.black,
      child: Stack(
        children: [
          //leaflet
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedEvent.isValid
                    ? _selectedEvent.coordinates
                    : _bandungCenter,
                initialZoom: _defaultZoom,
                minZoom: 5.0,
                maxZoom: 18.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  // URL Template resmi OpenStreetMap: https://tile.openstreetmap.org/{z}/{x}/{y}.png
                  urlTemplate: _osmOfficialUrl,
                  userAgentPackageName: 'com.example.convena',
                  maxNativeZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint(
                      '[OSM TileLayer] Gagal mengunduh ubin peta: $error',
                    );
                  },
                ),

                // Marker
                MarkerLayer(
                  markers: _filteredEvents.map((event) {
                    final isSelected = event == _selectedEvent;
                    return Marker(
                      point: event.coordinates,
                      width: 44,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: _EventPinMarker(
                        isSelected: isSelected,
                        onTap: () {
                          final idx = _filteredEvents.indexOf(event);
                          setState(() {
                            _selectedEvent = event;
                          });
                          _mapController.move(event.coordinates, _defaultZoom);
                          if (idx != -1 && _pageController.hasClients) {
                            _pageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),

                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          //header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.black.withValues(alpha: 0.96),
                    AppColors.black.withValues(alpha: 0.85),
                    AppColors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul: "Explore Events"
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Explore ',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Events',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  //location header
                  const Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.accent,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ITB Ganesha, Bandung',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.grey2, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                            cursorColor: AppColors.accent,
                            decoration: const InputDecoration(
                              hintText: 'Cari event atau lokasi',
                              hintStyle: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // floating near me
          Positioned(
            top: MediaQuery.of(context).padding.top + 130,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _mapController.move(_bandungCenter, _defaultZoom);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey2, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      color: AppColors.white,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Near me',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // event detail card(s)
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: _filteredEvents.isEmpty
                ? const SizedBox.shrink()
                : _filteredEvents.length == 1
                ? _buildFloatingEventCard(_filteredEvents.first)
                : SizedBox(
                    height: 94,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _filteredEvents.length,
                      onPageChanged: (index) {
                        final ev = _filteredEvents[index];
                        setState(() {
                          _selectedEvent = ev;
                        });
                        _mapController.move(ev.coordinates, _defaultZoom);
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildFloatingEventCard(
                            _filteredEvents[index],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  //detail event
  Widget _buildFloatingEventCard(EventLocation event) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.grey2, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 66,
              height: 66,
              color: AppColors.grey2,
              child: Image.network(
                event.imageUrl ?? 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=300&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.grey2, AppColors.grey3],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.festival_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.accent,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        event.venueName,
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.distance,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          //button liat event
          GestureDetector(
            onTap: () {
              final eventService = context.read<EventService>();
              final matched = eventService.events.where(
                (e) => e.title.toLowerCase() == event.eventTitle.toLowerCase(),
              );
              final targetEvent = matched.isNotEmpty
                  ? matched.first
                  : Event(
                      id: 'evt-map-1',
                      createdBy: 'org-1',
                      title: event.eventTitle,
                      slug: event.eventTitle.toLowerCase().replaceAll(' ', '-'),
                      description:
                          'Acara ${event.eventTitle} diselenggarakan di ${event.venueName} (${event.address}). Ikuti keseruan rangkaian kegiatan ini dan dapatkan E-Sertifikat resmi.',
                      bannerUrl: event.imageUrl,
                      category: event.category ?? 'IT Competition & Summit',
                      startDate: DateTime.now().add(const Duration(days: 7)),
                      endDate: DateTime.now().add(const Duration(days: 8)),
                      venueName: event.venueName,
                      address: event.address,
                      city: 'Bandung',
                      organizationName: 'HMIF ITB & Convena',
                      company: 'ITB Bandung',
                      createdAt: DateTime.now(),
                      ticketTiers: const [
                        TicketTier(
                          id: 'tier-reg',
                          name: 'Regular Pass',
                          price: 0,
                          quota: 250,
                          benefits: [
                            'Akses penuh ke area utama acara',
                            'E-Sertifikat resmi terverifikasi Convena',
                          ],
                        ),
                        TicketTier(
                          id: 'tier-vip',
                          name: 'VIP Summit Pass',
                          price: 75000,
                          quota: 50,
                          benefits: [
                            'Kursi baris depan eksklusif',
                            'Merchandise kit & konsumsi',
                            'E-Sertifikat resmi terverifikasi Convena',
                          ],
                        ),
                      ],
                    );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(event: targetEvent),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Event',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.black,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //Navbar Bottom
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        left: 12,
        right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.grey2, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          //Home
          _buildNavItem(
            index: 0,
            customIcon: (color) =>
                Icon(Icons.home_outlined, color: color, size: 26),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomePage(initialIndex: 0),
                ),
                (route) => false,
              );
            },
          ),

          //QR
          _buildNavItem(
            index: 1,
            customIcon: (color) => Container(
              width: 25,
              height: 25,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: color, size: 17),
            ),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomePage(initialIndex: 1),
                ),
                (route) => false,
              );
            },
          ),

          // search/map
          _buildNavItem(
            index: 2,
            customIcon: (color) =>
                Icon(Icons.search_rounded, color: color, size: 26),
            onTap: () {
              setState(() => _currentNavIndex = 2);
            },
          ),

          // profile
          _buildNavItem(
            index: 3,
            customIcon: (color) =>
                Icon(Icons.person_outline_rounded, color: color, size: 26),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const HomePage(initialIndex: 3),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required Widget Function(Color color) customIcon,
    required VoidCallback onTap,
  }) {
    final isActive = _currentNavIndex == index;
    final iconColor = isActive ? AppColors.accent : AppColors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: customIcon(iconColor),
      ),
    );
  }
}

//marker

class _EventPinMarker extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _EventPinMarker({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: CustomPaint(
          size: const Size(36, 46),
          painter: _PinPainter(
            pinColor: AppColors.accent,
            dotColor: AppColors.black,
            hasGlow: isSelected,
          ),
        ),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color pinColor;
  final Color dotColor;
  final bool hasGlow;

  _PinPainter({
    required this.pinColor,
    required this.dotColor,
    this.hasGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
      ..quadraticBezierTo(w * 0.9, h * 0.65, w / 2, h)
      ..quadraticBezierTo(w * 0.1, h * 0.65, 0, r)
      ..close();

    if (hasGlow) {
      canvas.drawShadow(path, pinColor.withValues(alpha: 0.85), 10.0, true);
    } else {
      canvas.drawShadow(
        path,
        AppColors.black.withValues(alpha: 0.4),
        4.0,
        true,
      );
    }

    final pinPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, pinPaint);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(Offset(w / 2, r * 0.95), r * 0.32, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) {
    return oldDelegate.hasGlow != hasGlow;
  }
}

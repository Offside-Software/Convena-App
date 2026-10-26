import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/event_location.dart';

class EventMapScreen extends StatefulWidget {
  final EventLocation? eventLocation;
  final List<EventLocation>? events;

  const EventMapScreen({
    super.key,
    this.eventLocation,
    this.events,
  });

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  late final MapController _mapController;

  late List<EventLocation> _allEvents;
  late List<EventLocation> _filteredEvents;
  late EventLocation _selectedEvent;

  int _currentNavIndex = 2;

  static const LatLng _bandungCenter = LatLng(-6.8915, 107.6107);
  static const double _defaultZoom = 16.0;

  static const Color _bgDark = Color(0xFF0F1015);
  static const Color _surfaceDark = Color(0xFF16171D);
  static const Color _cardBorderDark = Color(0xFF262832);
  static const Color _inputDark = Color(0xFF1E2026);
  static const Color _neonLime = Color(0xFFD4F042);
  static const Color _textMuted = Color(0xFF8E909B);

  static const String _osmOfficialUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Dummy Data
    _allEvents = widget.events ??
        [
          const EventLocation(
            eventTitle: 'Arkadivia 2026',
            venueName: 'Aula Barat ITB, Bandung',
            address:
                'Institut Teknologi Bandung, Jl. Ganesa No. 10, Lb. Siliwangi, Coblong, Kota Bandung',
            latitude: -6.8915,
            longitude: 107.6107,
            distance: '850 m',
            category: 'IT Competition & Summit',
            imageUrl:
                'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=500&q=80',
          ),
        ];

    // Jika ada event custom dari parameter, sisipkan di posisi teratas
    if (widget.eventLocation != null) {
      final exists = _allEvents.any((e) =>
          e.latitude == widget.eventLocation!.latitude &&
          e.longitude == widget.eventLocation!.longitude);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      resizeToAvoidBottomInset: false,
      body: _buildMapContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Tampilan Konten Peta & Informasi Event
  Widget _buildMapContent() {
    return Container(
      color: _bgDark,
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
                  userAgentPackageName: 'com.example.convena_app',
                  maxNativeZoom: 19,
                  errorTileCallback: (tile, error, stackTrace) {
                    debugPrint('[OSM TileLayer] Gagal mengunduh ubin peta: $error');
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
                          setState(() {
                            _selectedEvent = event;
                          });
                          _mapController.move(event.coordinates, _defaultZoom);
                        },
                      ),
                    );
                  }).toList(),
                ),

                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                    ),
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
                    _bgDark.withOpacity(0.96),
                    _bgDark.withOpacity(0.85),
                    Colors.transparent,
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
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Events',
                          style: TextStyle(
                            color: _neonLime,
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
                        color: _neonLime,
                        size: 15,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ITB Ganesha, Bandung',
                        style: TextStyle(
                          color: _textMuted,
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
                      color: _inputDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _cardBorderDark,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Color(0xFF7E808C),
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cari event atau lokasi',
                            style: TextStyle(
                              color: Color(0xFF7E808C),
                              fontSize: 14,
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
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _inputDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _cardBorderDark,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
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
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Near me',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // event detail card
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: _buildFloatingEventCard(_selectedEvent),
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
        color: _surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _cardBorderDark,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
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
              color: const Color(0xFF262832),
              child: Image.network(
                event.imageUrl ??
                    'https://images.unsplash.com/photo-1511578314322-379afb476865?w=300&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E3240), Color(0xFF1E2028)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.festival_rounded,
                      color: _neonLime,
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
                    color: Colors.white,
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
                      color: _neonLime,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        event.venueName,
                        style: const TextStyle(
                          color: _textMuted,
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
                      color: _textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.distance,
                      style: const TextStyle(
                        color: _textMuted,
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
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: _neonLime,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _neonLime.withOpacity(0.3),
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
                      color: Color(0xFF14151A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF14151A),
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
        color: Color(0xFF000000),
        border: Border(
          top: BorderSide(
            color: Color(0xFF16181F),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          //Home
          _buildNavItem(
            index: 0,
            customIcon: (color) => Icon(
              Icons.home_outlined,
              color: color,
              size: 26,
            ),
            onTap: () {},
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
              child: Icon(
                Icons.qr_code_2_rounded,
                color: color,
                size: 17,
              ),
            ),
            onTap: () {},
          ),

          // search/map
          _buildNavItem(
            index: 2,
            customIcon: (color) => Icon(
              Icons.search_rounded,
              color: color,
              size: 26,
            ),
            onTap: () {
              setState(() => _currentNavIndex = 2);
            },
          ),

          // profile
          _buildNavItem(
            index: 3,
            customIcon: (color) => Icon(
              Icons.person_outline_rounded,
              color: color,
              size: 26,
            ),
            onTap: () {},
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
    final iconColor = isActive ? _neonLime : const Color(0xFFA2A4B0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4C5E1A) : Colors.transparent,
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

  const _EventPinMarker({
    required this.isSelected,
    required this.onTap,
  });

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
            pinColor: const Color(0xFFD4F042),
            dotColor: const Color(0xFF14151A),
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
      ..arcToPoint(
        Offset(w, r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..quadraticBezierTo(w * 0.9, h * 0.65, w / 2, h)
      ..quadraticBezierTo(w * 0.1, h * 0.65, 0, r)
      ..close();

    if (hasGlow) {
      canvas.drawShadow(path, pinColor.withOpacity(0.85), 10.0, true);
    } else {
      canvas.drawShadow(path, Colors.black.withOpacity(0.4), 4.0, true);
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

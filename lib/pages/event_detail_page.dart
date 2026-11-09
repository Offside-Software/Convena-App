import 'dart:async';

import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/models/event_location.dart';
import 'package:convena/pages/event_map_page.dart';
import 'package:convena/pages/registration_page.dart';
import 'package:convena/pages/scan_qr_page.dart';
import 'package:convena/services/event_service.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Event Detail Page displaying event metadata, agenda overview,
/// interactive ticket tier selection, and real-time registration & attendance check-in.
class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late TicketTier _selectedTier;
  EventRegistration? _myRegistration;
  AttendanceRealtimeEvent? _realtimeBanner;
  StreamSubscription<AttendanceRealtimeEvent>? _realtimeSub;
  Timer? _bannerTimer;

  final TextEditingController _qrInputController = TextEditingController();
  bool _verifyingAttendance = false;
  String? _attendanceFeedback;
  bool _attendanceSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.event.ticketTiers.isNotEmpty) {
      _selectedTier = widget.event.ticketTiers.first;
    } else {
      _selectedTier = const TicketTier(
        id: 'tier-default',
        name: 'General Admission',
        price: 0,
        quota: 500,
        benefits: ['Akses Acara Utama', 'E-Sertifikat Digital'],
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRegistrationAndStream();
    });
  }

  Future<void> _initRegistrationAndStream() async {
    if (!mounted) return;
    final eventService = context.read<EventService>();
    final cached = eventService.getCachedRegistration(widget.event.id);
    if (cached != null) {
      setState(() => _myRegistration = cached);
    }

    final remoteReg = await eventService.getMyRegistration(widget.event.id);
    if (mounted && remoteReg != null) {
      setState(() => _myRegistration = remoteReg);
    }

    if (!mounted) return;
    _realtimeSub = eventService.subscribeToEventAttendance(
      eventId: widget.event.id,
      onEvent: (evt) {
        if (!mounted) return;
        setState(() {
          _myRegistration = evt.registration;
          _realtimeBanner = evt;
          if (evt.eventType == 'attendance.checked_in') {
            _attendanceSuccess = true;
            _attendanceFeedback = evt.message;
          }
        });
        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) {
            setState(() => _realtimeBanner = null);
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _bannerTimer?.cancel();
    _qrInputController.dispose();
    super.dispose();
  }

  Future<void> _handleAttendByQrToken() async {
    final code = _qrInputController.text.trim();
    if (code.isEmpty || _verifyingAttendance) return;

    setState(() {
      _verifyingAttendance = true;
      _attendanceFeedback = null;
    });

    try {
      final eventService = context.read<EventService>();
      final res = await eventService.attendEventByQr(
        code,
        eventId: widget.event.id,
      );
      if (!mounted) return;
      if (res['registration'] is Map<String, dynamic>) {
        final reg = EventRegistration.fromJson(
          res['registration'] as Map<String, dynamic>,
        );
        setState(() {
          _myRegistration = reg;
          _attendanceSuccess = true;
          _attendanceFeedback =
              res['message']?.toString() ?? 'Presensi berhasil terverifikasi!';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attendanceSuccess = false;
        _attendanceFeedback = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _verifyingAttendance = false);
      }
    }
  }

  Future<void> _openQrScannerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Scan QR Presensi Event',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.grey),
                  ),
                ],
              ),
            ),
            const Expanded(child: ScanQrPage(isActive: true)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final tiers = event.ticketTiers.isNotEmpty
        ? event.ticketTiers
        : [_selectedTier];

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Detail Event',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-Time Event Banner when registration/check-in occurs
            if (_realtimeBanner != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141A05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.black,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _realtimeBanner!.eventType ==
                                    'attendance.checked_in'
                                ? 'PRESENSI REAL-TIME BERHASIL'
                                : 'TIKET TERKONFIRMASI REAL-TIME',
                            style: GoogleFonts.montserrat(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_realtimeBanner!.registration.attendeeName} (${_realtimeBanner!.registration.ticketCode})',
                            style: GoogleFonts.montserrat(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _realtimeBanner!.message,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFFD5E69C),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _realtimeBanner = null),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.grey,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Banner with Category & Campus Tags
            Stack(
              children: [
                Container(
                  height: 220,
                  width: double.infinity,
                  color: const Color(0xFF202020),
                  child: event.bannerUrl != null && event.bannerUrl!.isNotEmpty
                      ? Image.network(
                          event.bannerUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x99000000),
                          AppColors.black,
                        ],
                        stops: [0.3, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.category.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: AppColors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (event.company != null && event.company!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grey2),
                          ),
                          child: Text(
                            event.company!,
                            style: GoogleFonts.montserrat(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Main Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organizer
                  Row(
                    children: [
                      Text(
                        'Diselenggarakan oleh Organisasi: ',
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          event.organizationName ?? 'Convena Team',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Cards: Date & Location
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grey3,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.grey2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal & Waktu',
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    event.formattedDate,
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppColors.grey2, height: 20),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => EventMapPage(
                                  eventLocation: EventLocation(
                                    eventTitle: event.title,
                                    venueName: event.displayLocation,
                                    address:
                                        event.address ?? event.displayLocation,
                                    latitude: event.latitude ?? -6.8915,
                                    longitude: event.longitude ?? 107.6107,
                                    distance: '850 m',
                                    category: event.category,
                                    imageUrl: event.bannerUrl,
                                  ),
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lokasi (${event.locationType.toUpperCase()} • Ketuk untuk buka Peta)',
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      event.displayLocation,
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.map_outlined,
                                color: AppColors.accent,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ===========================================================
                  // ACTIVE REGISTRATION + PRESENSI KEHADIRAN ACARA (ATTENDING QR)
                  // Matches Web EventDetailPage.tsx lines 349-436
                  // ===========================================================
                  if (_myRegistration != null) ...[
                    _buildActiveRegistrationCard(_myRegistration!),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    Text(
                      'Tentang Acara',
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description!,
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Ticket Tiers Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pilihan Kategori Tiket',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tiers.length} Kategori',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tiers List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tiers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final tier = tiers[index];
                      final isSelected = _selectedTier.id == tier.id;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedTier = tier);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1E1E1E)
                                : AppColors.grey3,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.grey2,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? AppColors.accent
                                            : AppColors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        tier.name,
                                        style: GoogleFonts.montserrat(
                                          color: AppColors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    tier.formattedPrice,
                                    style: GoogleFonts.montserrat(
                                      color: tier.isFree
                                          ? AppColors.accent
                                          : AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sisa kuota: ${tier.quotaLeft} dari ${tier.quota}',
                                style: GoogleFonts.montserrat(
                                  color: AppColors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              if (tier.benefits.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Divider(
                                  color: AppColors.grey2.withValues(alpha: 0.5),
                                  height: 1,
                                ),
                                const SizedBox(height: 10),
                                ...tier.benefits.map(
                                  (benefit) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_rounded,
                                          color: AppColors.accent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            benefit,
                                            style: GoogleFonts.montserrat(
                                              color: AppColors.grey,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Pinned Bottom Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.black,
          border: Border(
            top: BorderSide(
              color: AppColors.grey2.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: _myRegistration != null
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _myRegistration!.isCheckedIn
                                ? 'Status Kehadiran'
                                : 'Tiket Terkonfirmasi',
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _myRegistration!.isCheckedIn
                                ? 'SUDAH HADIR (CHECKED-IN)'
                                : _myRegistration!.ticketCode,
                            style: GoogleFonts.montserrat(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_myRegistration!.isCheckedIn)
                      ElevatedButton.icon(
                        onPressed: _openQrScannerSheet,
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Scan QR Presensi',
                          style: GoogleFonts.montserrat(
                            color: AppColors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori Terpilih',
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          _selectedTier.formattedPrice,
                          style: GoogleFonts.montserrat(
                            color: _selectedTier.isFree
                                ? AppColors.accent
                                : AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        final reg = await Navigator.push<EventRegistration?>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistrationPage(
                              event: event,
                              selectedTier: _selectedTier,
                            ),
                          ),
                        );
                        if (reg != null && mounted) {
                          setState(() => _myRegistration = reg);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedTier.isFree
                            ? 'Daftar Gratis'
                            : 'Registrasi & Bayar',
                        style: GoogleFonts.montserrat(
                          color: AppColors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActiveRegistrationCard(EventRegistration reg) {
    final isCheckedIn = reg.isCheckedIn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCheckedIn
                      ? 'SUDAH HADIR (CHECKED-IN)'
                      : 'TIKET TERKONFIRMASI',
                  style: GoogleFonts.montserrat(
                    color: AppColors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                reg.ticketCode,
                style: GoogleFonts.robotoMono(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tier: ${reg.tierName} • ${reg.price <= 0 ? 'Tiket Gratis (Free Tier)' : 'Lunas ${reg.formattedPrice} (${reg.paymentMethod.toUpperCase()})'}',
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2E2E2E)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peserta Terdaftar:',
                  style: GoogleFonts.montserrat(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reg.attendeeName,
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reg.attendeeEmail.isNotEmpty)
                  Text(
                    reg.attendeeEmail,
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF262626), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.accent,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                'Presensi Kehadiran Acara (Attending QR)',
                style: GoogleFonts.montserrat(
                  color: AppColors.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCheckedIn
                ? 'Kehadiran Anda telah tercatat secara real-time di sistem penyelenggara.'
                : 'Saat berada di lokasi acara, pindai QR Presensi dari penyelenggara lewat Kamera atau masukkan kode token QR di bawah ini:',
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          if (_attendanceFeedback != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _attendanceSuccess
                    ? const Color(0xFF1E240A)
                    : const Color(0xFF2A1215),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _attendanceSuccess
                      ? AppColors.accent
                      : AppColors.danger,
                ),
              ),
              child: Text(
                _attendanceFeedback!,
                style: GoogleFonts.montserrat(
                  color: _attendanceSuccess
                      ? AppColors.accent
                      : const Color(0xFFFF8888),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (!isCheckedIn) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qrInputController,
                    style: GoogleFonts.robotoMono(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      hintText: 'CONVENA-ATTEND:... atau Token QR',
                      hintStyle: GoogleFonts.robotoMono(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0C0C0C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _verifyingAttendance
                      ? null
                      : _handleAttendByQrToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _verifyingAttendance ? '...' : 'Check-In',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.event.attendanceQrToken != null &&
                widget.event.attendanceQrToken!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _qrInputController.text =
                        'CONVENA-ATTEND:${widget.event.id}:${widget.event.attendanceQrToken}';
                  });
                },
                child: Text(
                  'Isi otomatis dengan QR Presensi Event aktif (${widget.event.attendanceQrToken})',
                  style: GoogleFonts.montserrat(
                    color: AppColors.accent,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(Icons.event_seat_rounded, color: AppColors.grey, size: 48),
      ),
    );
  }
}

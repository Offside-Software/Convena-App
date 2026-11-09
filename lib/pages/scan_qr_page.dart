import 'package:convena/models/event.dart';
import 'package:convena/services/event_service.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class ScanQrPage extends StatefulWidget {
  final bool isActive;

  const ScanQrPage({super.key, required this.isActive});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final TextEditingController _manualTokenController = TextEditingController();
  String? _scannedValue;
  bool _isHandlingScan = false;
  bool _isVerifying = false;
  String? _verificationMessage;
  bool _isVerifiedSuccess = false;
  EventRegistration? _verifiedRegistration;
  String? _verifiedEventTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
    }
  }

  @override
  void didUpdateWidget(covariant ScanQrPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;

    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.isActive) return;

    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else {
      _controller.stop();
    }
  }

  Future<void> _startCamera() async {
    if (!widget.isActive || _scannedValue != null) return;
    try {
      await _controller.start();
    } on Exception {
      if (mounted) setState(() {});
    }
  }

  Future<void> _verifyAttendanceQr(String value) async {
    setState(() {
      _scannedValue = value;
      _isVerifying = true;
      _verificationMessage = null;
      _isVerifiedSuccess = false;
      _verifiedRegistration = null;
      _verifiedEventTitle = null;
    });

    try {
      final eventService = context.read<EventService>();
      final res = await eventService.attendEventByQr(value);
      if (!mounted) return;
      EventRegistration? reg;
      if (res['registration'] is Map<String, dynamic>) {
        reg = EventRegistration.fromJson(
          res['registration'] as Map<String, dynamic>,
        );
      }
      final msg =
          res['message']?.toString() ?? 'Presensi kehadiran terverifikasi!';
      setState(() {
        _isVerifying = false;
        _isVerifiedSuccess = true;
        _verificationMessage = msg;
        _verifiedRegistration = reg;
        _verifiedEventTitle = res['eventTitle']?.toString();
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF141A05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reg != null
                      ? 'HADIR: ${reg.attendeeName} (${reg.ticketCode})'
                      : msg,
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isVerifiedSuccess = false;
        _verificationMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isHandlingScan || !widget.isActive) return;

    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null || value.isEmpty) return;

    _isHandlingScan = true;
    await _controller.stop();
    if (!mounted) return;
    await _verifyAttendanceQr(value);
  }

  Future<void> _scanAgain() async {
    setState(() {
      _scannedValue = null;
      _isHandlingScan = false;
      _isVerifying = false;
      _verificationMessage = null;
      _isVerifiedSuccess = false;
      _verifiedRegistration = null;
      _verifiedEventTitle = null;
    });
    await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pindai QR Presensi Event Penyelenggara',
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (context, state, _) => IconButton(
                  tooltip: state.torchState == TorchState.on
                      ? 'Matikan flash'
                      : 'Nyalakan flash',
                  onPressed: state.isRunning ? _controller.toggleTorch : null,
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Ganti kamera',
                onPressed: _controller.switchCamera,
                icon: const Icon(
                  Icons.cameraswitch_rounded,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.isActive)
                        MobileScanner(
                          controller: _controller,
                          onDetect: _handleDetection,
                          placeholderBuilder: (context) => const ColoredBox(
                            color: Color(0xFF151515),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          errorBuilder: (context, error) => ColoredBox(
                            color: const Color(0xFF151515),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.no_photography_outlined,
                                      color: AppColors.accent,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Kamera tidak dapat dibuka. Anda tetap dapat memasukkan kode QR Presensi secara langsung di bawah.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _startCamera,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Coba lagi'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const ColoredBox(
                          color: Color(0xFF151515),
                          child: Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              color: AppColors.accent,
                              size: 72,
                            ),
                          ),
                        ),
                      IgnorePointer(
                        child: CustomPaint(painter: _ScanFramePainter()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_scannedValue case final value?)
            _buildScanResult(value)
          else ...[
            Text(
              'Arahkan kamera ke QR Presensi penyelenggara atau tempel kode token di bawah:',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualTokenController,
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
                        vertical: 11,
                      ),
                      filled: true,
                      fillColor: AppColors.grey3,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.grey2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final code = _manualTokenController.text.trim();
                    if (code.isNotEmpty) {
                      _verifyAttendanceQr(code);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Verifikasi',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanResult(String value) {
    final borderColor = _isVerifying
        ? AppColors.grey2
        : (_isVerifiedSuccess ? AppColors.accent : AppColors.danger);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isVerifying
                    ? Icons.hourglass_top_rounded
                    : (_isVerifiedSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded),
                color: _isVerifiedSuccess ? AppColors.accent : AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isVerifying
                      ? 'Memverifikasi pendaftaran & pembayaran...'
                      : (_isVerifiedSuccess
                            ? 'Presensi Kehadiran Berhasil (Real-Time)!'
                            : 'Presensi Ditolak'),
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_verificationMessage != null)
            Text(
              _verificationMessage!,
              style: GoogleFonts.montserrat(
                color: _isVerifiedSuccess ? AppColors.accent : AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (_verifiedRegistration != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.grey2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_verifiedEventTitle != null)
                    Text(
                      _verifiedEventTitle!,
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    '${_verifiedRegistration!.attendeeName} • ${_verifiedRegistration!.ticketCode}',
                    style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kategori: ${_verifiedRegistration!.tierName} • Status: HADIR (CHECKED-IN)',
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Pindai lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 224.0;
    final left = (size.width - frameSize) / 2;
    final top = (size.height - frameSize) / 2;
    final rect = Rect.fromLTWH(left, top, frameSize, frameSize);

    final maskPaint = Paint()..color = const Color(0x88000000);
    final maskPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(maskPath, maskPaint);

    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 16.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLength)
        ..lineTo(rect.left, rect.top + radius)
        ..arcToPoint(
          Offset(rect.left + radius, rect.top),
          radius: const Radius.circular(radius),
        )
        ..lineTo(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.top)
        ..lineTo(rect.right - radius, rect.top)
        ..arcToPoint(
          Offset(rect.right, rect.top + radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLength)
        ..lineTo(rect.left, rect.bottom - radius)
        ..arcToPoint(
          Offset(rect.left + radius, rect.bottom),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLength, rect.bottom)
        ..lineTo(rect.right - radius, rect.bottom)
        ..arcToPoint(
          Offset(rect.right, rect.bottom - radius),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

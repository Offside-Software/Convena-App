import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQrPage extends StatefulWidget {
  final bool isActive;

  const ScanQrPage({super.key, required this.isActive});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _scannedValue;
  bool _isHandlingScan = false;

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
    setState(() => _scannedValue = value);
  }

  Future<void> _scanAgain() async {
    setState(() {
      _scannedValue = null;
      _isHandlingScan = false;
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
                  'Arahkan kamera ke QR tiket',
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
                                      'Kamera tidak dapat dibuka. Pastikan izin kamera aktif di pengaturan perangkat.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
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
          const SizedBox(height: 18),
          if (_scannedValue case final value?)
            _buildScanResult(value)
          else
            Text(
              'Arahkan kamera ke QR tiket untuk membaca datanya',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanResult(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'QR berhasil terbaca',
                style: GoogleFonts.montserrat(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 12),
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
    final frame = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameSize,
      height: frameSize,
    );
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    const cornerLength = 28.0;

    for (final corner in [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ]) {
      final (point, dx, dy) = corner;
      canvas
        ..drawLine(point, point.translate(dx * cornerLength, 0), paint)
        ..drawLine(point, point.translate(0, dy * cornerLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => false;
}

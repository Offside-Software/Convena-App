import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/services/event_service.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Payment & Checkout Page matching Convena's Web & Mobile event flow:
/// Paid Tier Ticket: Register -> Payment (SCAN QRIS / Pay via Bank) -> Done.
class PaymentPage extends StatefulWidget {
  final Event event;
  final TicketTier selectedTier;
  final String? attendeeName;
  final String? attendeeEmail;
  final String? attendeeInstitution;

  const PaymentPage({
    super.key,
    required this.event,
    required this.selectedTier,
    this.attendeeName,
    this.attendeeEmail,
    this.attendeeInstitution,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _quantity = 1;
  bool _memberDiscountActive = false;
  String _selectedPaymentMethod = 'qris'; // 'qris' or 'bank'
  bool _isSubmitting = false;

  String _formatRupiah(num value) {
    if (value <= 0) return 'GRATIS';
    final intPrice = value.toInt();
    final buffer = StringBuffer();
    final str = intPrice.toString();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  void _showSnackBar({
    required String title,
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.grey3,
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isError ? AppColors.danger : AppColors.accent,
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? AppColors.danger : AppColors.accent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmPayment() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    EventRegistration? confirmedRegistration;
    try {
      final eventService = context.read<EventService>();
      final res = await eventService.registerForEvent(
        eventId: widget.event.id,
        tierId: widget.selectedTier.id,
        paymentMethod: _selectedPaymentMethod == 'bank'
            ? 'bank_transfer'
            : 'qris',
        attendeeName: widget.attendeeName,
        attendeeEmail: widget.attendeeEmail,
        attendeeInstitution: widget.attendeeInstitution,
      );
      if (res['registration'] is Map<String, dynamic>) {
        confirmedRegistration = EventRegistration.fromJson(
          res['registration'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(
        title: 'Pembayaran Gagal',
        message: e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    confirmedRegistration ??= EventRegistration(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      eventId: widget.event.id,
      userId: 'usr-current',
      tierId: widget.selectedTier.id,
      tierName: widget.selectedTier.name,
      price: widget.selectedTier.price,
      paymentMethod: _selectedPaymentMethod == 'bank'
          ? 'bank_transfer'
          : 'qris',
      paymentStatus: 'paid',
      status: 'confirmed',
      attendeeName: widget.attendeeName ?? 'Peserta Convena',
      attendeeEmail: widget.attendeeEmail ?? '',
      attendeeInstitution: widget.attendeeInstitution,
      ticketCode:
          'TKT-${widget.event.id.substring(0, widget.event.id.length >= 4 ? 4 : widget.event.id.length).toUpperCase()}-PAID',
      createdAt: DateTime.now(),
    );

    await _showSuccessDialog(confirmedRegistration);
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = widget.selectedTier.price;
    final subtotal = basePrice * _quantity;
    final discount = (_memberDiscountActive && subtotal > 0)
        ? (subtotal * 0.15).round()
        : 0;
    final gatewayFee = subtotal > 0 ? 4500 : 0;
    final totalToPay = (subtotal - discount + gatewayFee)
        .clamp(0, double.infinity)
        .toInt();

    final ticketId = widget.event.id.length >= 6
        ? widget.event.id.substring(0, 6).toUpperCase()
        : 'TS-9482';

    final digitsOnly = widget.event.id.replaceAll(RegExp(r'\D'), '');
    final vaSuffix = digitsOnly.length >= 6
        ? digitsOnly.substring(0, 6)
        : digitsOnly.padRight(6, '8');
    final virtualAccountNumber = '8801 9920 $vaSuffix';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Pembayaran Tiket',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          children: [
            // -----------------------------------------------------------------
            // STEP 2 HEADER + ATTENDEE SUMMARY (Matching Web Step 2)
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LANGKAH 2 DARI 2 • PEMBAYARAN',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Ubah Data / Tier',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Selesaikan Pembayaran',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFF262626), height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Peserta Terdaftar:',
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.attendeeName ?? 'Peserta Convena',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.attendeeEmail != null &&
                      widget.attendeeEmail!.isNotEmpty)
                    Text(
                      widget.attendeeEmail!,
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  if (widget.attendeeInstitution != null &&
                      widget.attendeeInstitution!.isNotEmpty)
                    Text(
                      widget.attendeeInstitution!,
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 1: Verified Ticket & Event Card
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Verified Ticket',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'ID: #$ticketId',
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.event.title,
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.event.displayLocation,
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF262626), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kategori Tiket:',
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.selectedTier.name} (${widget.selectedTier.formattedPrice})',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 2: Quantity, Discount & Payment Method (SCAN QRIS vs Pay via Bank)
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ticket Quantity Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jumlah Tiket',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF262626)),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.montserrat(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() => _quantity++);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Member Discount Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diskon Mahasiswa (15%)',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: _memberDiscountActive,
                        activeThumbColor: AppColors.accent,
                        activeTrackColor: AppColors.accent.withValues(
                          alpha: 0.5,
                        ),
                        inactiveThumbColor: AppColors.grey,
                        inactiveTrackColor: const Color(0xFF2A2A2A),
                        onChanged: (val) {
                          setState(() => _memberDiscountActive = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Payment Method Selector matching Web: SCAN QRIS vs Pay via Bank
                  Text(
                    'Pilih Metode Pembayaran',
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPaymentOption(
                          id: 'qris',
                          label: 'SCAN QRIS',
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPaymentOption(
                          id: 'bank',
                          label: 'Pay via Bank',
                          icon: Icons.account_balance_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 3: RINGKASAN PEMBAYARAN
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RINGKASAN PEMBAYARAN',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPriceRow(
                    label: 'Harga Tiket (${_quantity}x)',
                    value: _formatRupiah(subtotal),
                  ),
                  if (_memberDiscountActive) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      label: 'Diskon Mahasiswa (15%)',
                      value: discount > 0
                          ? '-${_formatRupiah(discount)}'
                          : 'Rp 0',
                      valueColor: AppColors.accent,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Biaya Layanan',
                    value: _formatRupiah(gatewayFee),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF262626), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            totalToPay == 0
                                ? 'GRATIS'
                                : _formatRupiah(totalToPay),
                            style: GoogleFonts.montserrat(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Instan',
                        style: GoogleFonts.montserrat(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 4: Payment Instructions (QRIS vs Bank Virtual Account)
            // -----------------------------------------------------------------
            if (_selectedPaymentMethod == 'qris')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF262626),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Scan QRIS (GoPay, OVO, Dana, BCA, Mandiri)',
                            style: GoogleFonts.montserrat(
                              color: AppColors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            _showSnackBar(
                              title: 'QRIS Tersimpan',
                              message:
                                  'Kode QRIS berhasil diunduh ke perangkat.',
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_circle_down_rounded,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Unduh',
                                style: GoogleFonts.montserrat(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.black,
                          size: 136,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      'CONVENA-QRIS:${widget.event.id}:${widget.selectedTier.id}:$totalToPay',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        color: AppColors.grey,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pindai kode QRIS di atas melalui aplikasi m-banking atau e-wallet Anda.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF262626),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer Virtual Account Bank',
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C0C0C),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank Mandiri / BCA Virtual Account',
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  virtualAccountNumber,
                                  style: GoogleFonts.robotoMono(
                                    color: AppColors.accent,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: virtualAccountNumber),
                                  );
                                  _showSnackBar(
                                    title: 'Nomor VA Tersalin',
                                    message: virtualAccountNumber,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Salin VA',
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'a.n. Convena Escrow — ${widget.event.organizationName ?? "Convena Organizer"}',
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Complete Payment Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isSubmitting
                      ? 'Memverifikasi Pembayaran...'
                      : 'Konfirmasi Pembayaran (${_selectedPaymentMethod == 'qris' ? 'QRIS' : 'Bank'}) & Selesai',
                  style: GoogleFonts.montserrat(
                    color: AppColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A2205)
              : const Color(0xFF0C0C0C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFF262626),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: isSelected ? AppColors.accent : AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: AppColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: valueColor ?? AppColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showSuccessDialog(EventRegistration registration) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.grey3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pembayaran & Pendaftaran Berhasil!',
                style: GoogleFonts.montserrat(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.black,
                size: 88,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kode Tiket: ${registration.ticketCode}',
              style: GoogleFonts.robotoMono(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              registration.attendeeName,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tiket Anda untuk "${widget.event.title}" sudah aktif dan lunas. Saat hari pelaksanaan, pindai QR Presensi dari penyelenggara untuk mencatat kehadiran.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tier: ${registration.tierName}',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status Pembayaran: Lunas (${registration.paymentMethod.toUpperCase()})',
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.accent,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Siap Melakukan Scan QR Presensi Kehadiran',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context, registration);
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: Text(
                  'Lihat E-Tiket & Presensi QR',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.montserrat(
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

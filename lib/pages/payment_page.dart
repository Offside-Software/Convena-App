import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Payment & Checkout Page matching Convena's payment design system.
///
/// Implements:
/// - Event & Verified Ticket overview card
/// - Ticket Quantity stepper, Member Discount (15%) toggle, and Payment Method selector
/// - Order Price Summary breakdown
/// - QRIS payment visual scanner box with instant payment instructions
class PaymentPage extends StatefulWidget {
  final Event event;
  final TicketTier selectedTier;

  const PaymentPage({
    super.key,
    required this.event,
    required this.selectedTier,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _quantity = 1;
  bool _memberDiscountActive = true;
  String _selectedPaymentMethod = 'qris'; // 'qris', 'bank', 'ewallet'

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

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Dashboard',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          children: [
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
                          widget.event.venueName ??
                              'Telkom University Convention Hall',
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
                  Divider(color: const Color(0xFF262626), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Tier:',
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedTier.name,
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
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
            // CARD 2: Quantity, Discount & Payment Method
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
                        'Ticket Quantity',
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
                        'Member Discount (15%)',
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

                  // Payment Method
                  Text(
                    'Payment Method',
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
                          label: 'QRIS',
                          icon: Icons.qr_code_scanner_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPaymentOption(
                          id: 'bank',
                          label: 'Bank',
                          icon: Icons.account_balance_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPaymentOption(
                          id: 'ewallet',
                          label: 'E-Wallet',
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 3: ORDER PRICE SUMMARY
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
                    'ORDER PRICE SUMMARY',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildPriceRow(
                    label: 'Base Ticket Price (${_quantity}x)',
                    value: _formatRupiah(subtotal),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Member Discount (15%)',
                    value: discount > 0
                        ? '-${_formatRupiah(discount)}'
                        : 'Rp 0',
                    valueColor: AppColors.accent,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    label: 'Gateway Fee & Service',
                    value: _formatRupiah(gatewayFee),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: const Color(0xFF262626), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Est. To Be Paid',
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
                        'Expires in 15:00',
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // -----------------------------------------------------------------
            // CARD 4: Scan via GoPay, OVO, BCA, QRIS
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF262626), width: 1.2),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scan via GoPay, OVO, BCA, QRIS',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'QRIS diunduh ke galeri',
                                style: GoogleFonts.montserrat(
                                  color: AppColors.black,
                                ),
                              ),
                              backgroundColor: AppColors.accent,
                              behavior: SnackBarBehavior.floating,
                            ),
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
                  const SizedBox(height: 24),

                  // Stylized Glowing QRIS Box matching the design image
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C0C0C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.qr_code,
                            color: AppColors.white,
                            size: 120,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Point your banking camera app\nto complete the transaction instantly',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                      height: 1.4,
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
                onPressed: () {
                  _showSuccessDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Saya Sudah Bayar',
                  style: GoogleFonts.montserrat(
                    color: AppColors.black,
                    fontSize: 15,
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
          color: const Color(0xFF0C0C0C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFF262626),
            width: isSelected ? 1.5 : 1,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.grey3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.accent,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Pembayaran Berhasil',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'E-Tiket Anda untuk "${widget.event.title}" telah terkonfirmasi. Silakan periksa tab Profile atau scan QR saat hari-H.',
          style: GoogleFonts.montserrat(
            color: AppColors.grey,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.black,
            ),
            child: Text(
              'Selesai',
              style: GoogleFonts.montserrat(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

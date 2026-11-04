import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/pages/home_page.dart';
import 'package:convena/pages/payment_page.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationPage extends StatefulWidget {
  final Event event;
  final TicketTier selectedTier;

  const RegistrationPage({
    super.key,
    required this.event,
    required this.selectedTier,
  });

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  bool _isExternal = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _institutionController.dispose();
    super.dispose();
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isError
                    ? const Color(0xFF3A1A1E)
                    : const Color(0xFF283014),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? AppColors.danger : AppColors.accent,
                size: 22,
              ),
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
                      fontSize: 14,
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

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        title: 'Data Belum Lengkap',
        message: 'Mohon lengkapi seluruh kolom pendaftaran terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final payload = {
      'event_title': widget.event.title,
      'ticket_tier': widget.selectedTier.name,
      'ticket_price': widget.selectedTier.price,
      'name': _nameController.text.trim(),
      'nim': _nimController.text.trim(),
      'campus_category': _isExternal ? 'Luar Kampus' : 'Dalam Kampus',
      if (_isExternal) 'institution': _institutionController.text.trim(),
    };

    debugPrint('Payload Registrasi: $payload');

    // Jika tiket berbayar, arahkan ke PaymentPage
    if (!widget.selectedTier.isFree) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PaymentPage(
            event: widget.event,
            selectedTier: widget.selectedTier,
          ),
        ),
      );
      return;
    }

    // Jika tiket gratis, langsung selesaikan pendaftaran dan kembali ke HomePage
    _showSnackBar(
      title: 'Registrasi Berhasil!',
      message: 'Kamu berhasil terdaftar di ${widget.event.title}.',
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (ctx) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.selectedTier.isFree;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Registrasi Peserta',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Info Event, Kategori Tiket & Status Harga
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey3,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey2, width: 1.2),
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Text(
                            widget.selectedTier.name,
                            style: GoogleFonts.montserrat(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          widget.selectedTier.formattedPrice,
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.event.title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.formattedDate} • ${widget.event.displayLocation}',
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Input Nama Lengkap
              _buildLabel('Nama Lengkap'),
              const SizedBox(height: 8),
              _buildDarkTextField(
                controller: _nameController,
                hintText: 'Masukkan nama lengkap',
                icon: Icons.person_outline,
                validatorMsg: 'Nama lengkap wajib diisi',
              ),
              const SizedBox(height: 18),

              // 2. Input NIM
              _buildLabel('NIM (Nomor Induk Mahasiswa)'),
              const SizedBox(height: 8),
              _buildDarkTextField(
                controller: _nimController,
                hintText: 'Contoh: 103022400111',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validatorMsg: 'NIM wajib diisi',
              ),
              const SizedBox(height: 18),

              // 3. Pilihan Kategori Peserta Tanpa Logo
              _buildLabel('Kategori Asal Peserta'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildCampusOptionCard(
                      label: 'Dalam Kampus',
                      isSelected: !_isExternal,
                      onTap: () => setState(() => _isExternal = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCampusOptionCard(
                      label: 'Luar Kampus',
                      isSelected: _isExternal,
                      onTap: () => setState(() => _isExternal = true),
                    ),
                  ),
                ],
              ),

              // 4. Input Asal Kampus / Instansi (Muncul saat memilih Luar Kampus)
              if (_isExternal) ...[
                const SizedBox(height: 18),
                _buildLabel('Asal Kampus / Instansi'),
                const SizedBox(height: 8),
                _buildDarkTextField(
                  controller: _institutionController,
                  hintText: 'Masukkan nama kampus atau instansi',
                  icon: Icons.business_outlined,
                  validatorMsg: 'Asal kampus / instansi wajib diisi',
                ),
              ],
            ],
          ),
        ),
      ),

      // Tombol Bawah (Menyesuaikan Event Gratis vs Berbayar)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.black,
          border: Border(top: BorderSide(color: AppColors.grey2, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _submitForm,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isFree
                        ? 'Konfirmasi Pendaftaran'
                        : 'Lanjut ke Pembayaran (${widget.selectedTier.formattedPrice})',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13.5,
      ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String validatorMsg,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.montserrat(
          color: AppColors.grey,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: AppColors.grey3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey2, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.grey2, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMsg;
        }
        return null;
      },
    );
  }

  Widget _buildCampusOptionCard({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.grey3,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.grey2,
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: isSelected ? AppColors.accent : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}
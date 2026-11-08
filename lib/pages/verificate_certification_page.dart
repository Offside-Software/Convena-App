
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:convena/theme.dart';

class VerificateCertificationPage extends StatefulWidget {
  const VerificateCertificationPage({super.key});

  @override
  State<VerificateCertificationPage> createState() =>
      _VerificateCertificationPageState();
}

class _VerificateCertificationPageState
    extends State<VerificateCertificationPage> {
  final TextEditingController _certController = TextEditingController(
    text: 'CNV-2026-ITB-8821',
  );

  bool _isVerified = false;

  final String certificateId = 'CNV-2026-ITB-8821';

  @override
  void dispose() {
    _certController.dispose();
    super.dispose();
  }

  void _verifyCertificate() {
    if (_certController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Masukkan nomor sertifikat terlebih dahulu',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isVerified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.grey3,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 44),
            Text(
              'Dashboard',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // JUDUL DAN DESKRIPSI
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Verifikasi Keaslian\nE-Sertifikat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Validasi keabsahan dokumen penghargaan, '
                    'kepanitiaan, atau kehadiran peserta acara '
                    'mahasiswa melalui basis data Convena.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // FORM VERIFIKASI
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.grey3,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.grey2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOMOR SERTIFIKAT / ID',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // INPUT NOMOR SERTIFIKAT
                  TextField(
                    controller: _certController,
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.grey,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.black,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // BUTTON VERIFIKASI
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _verifyCertificate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'VERIFIKASI SEKARANG',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CONTOH CEPAT
                  Text(
                    'Contoh Cepat:',
                    style: GoogleFonts.montserrat(
                      color: AppColors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  _exampleCertificate(
                    'CNV-2026-ITB-8821 (ITB)',
                    AppColors.accent,
                  ),

                  const SizedBox(height: 8),

                  _exampleCertificate(
                    'CNV-2026-ITB-8821 (ITB)',
                    AppColors.white,
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // HASIL VERIFIKASI
            if (_isVerified) _verifiedCertificate(),

            const SizedBox(height: 20),

            // CTA
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.grey3,
                border: Border.all(
                  color: AppColors.accent,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIAP MENGANGKAT ORMAWA ANDA?',
                    style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Bergabung bersama ratusan BEM dan Himpunan '
                    'yang mengotomatisasi ticketing dan LPJ tanpa pusing.',
                    style: GoogleFonts.montserrat(
                      color: AppColors.white,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        Text(
                          'Jelajahi Demo Convena',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: AppColors.accent,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FOOTER
            _footer(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // CONTOH NOMOR SERTIFIKAT
  Widget _exampleCertificate(String text, Color dotColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _certController.text = certificateId;
          _isVerified = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.grey2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.montserrat(
                  color: AppColors.white,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD SERTIFIKAT TERVERIFIKASI
  Widget _verifiedCertificate() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        border: Border.all(
          color: AppColors.accent,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // STATUS VERIFIED
          Container(
            color: AppColors.accent,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.black,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SERTIFIKAT RESMI TERVERIFIKASI',
                      style: GoogleFonts.montserrat(
                        color: AppColors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      certificateId + ' (ITB)',
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ISI SERTIFIKAT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'HMIP ITB • INSTITUT TEKNOLOGI BANDUNG',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppColors.grey,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'SERTIFIKAT PENGHARGAAN',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Diberikan dengan bangga kepada:',
                  style: GoogleFonts.montserrat(
                    color: AppColors.grey,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 10),

                // NAMA PENERIMA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Muhammad Rizky Ramadhan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: AppColors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'NIM: 13522019',
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 16),

                // DESKRIPSI KEGIATAN
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.grey2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.montserrat(
                        color: AppColors.grey,
                        fontSize: 11,
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Atas partisipasi aktifnya sebagai ',
                        ),
                        TextSpan(
                          text: 'ATTENDEE',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' dalam kegiatan ',
                        ),
                        TextSpan(
                          text: 'Arkavidia 9.0: National Tech Festival & Hackathon',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ' yang diselenggarakan pada tanggal 2026-10-22.',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // TANDA TANGAN DIGITAL
                _digitalSignature(
                  'Dr. Techn. Saiful Akbar, S.T., M.T.',
                  'Ketua Program Studi STEI ITB',
                ),

                const SizedBox(height: 12),

                _digitalSignature(
                  'Arya Pratama',
                  'Ketua Pelaksana Arkavidia 9.0',
                ),

                const SizedBox(height: 14),

                // QR VERIFICATION
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.grey2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        color: AppColors.accent,
                        size: 50,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Otentikasi Convena',
                              style: GoogleFonts.montserrat(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pindai QR untuk verifikasi langsung '
                              'di jaringan blockchain/DB',
                              style: GoogleFonts.montserrat(
                                color: AppColors.grey,
                                fontSize: 10,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TANDA TANGAN DIGITAL
  Widget _digitalSignature(String name, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.grey2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accent,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '[Signed Digitally with Key]',
              style: GoogleFonts.montserrat(
                color: AppColors.accent,
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            role,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // FOOTER CONVENA
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Divider(
            color: AppColors.grey2,
          ),

          const SizedBox(height: 16),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _footerBadge('TEL-U', AppColors.danger),
              _footerBadge('ITB', AppColors.accent),
              _footerBadge('UI', AppColors.grey),
              _footerBadge('UGM', AppColors.danger),
              _footerBadge('ITS', AppColors.white),
              _footerBadge('UNAIR', AppColors.grey),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.grey3,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.grey2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _footerTitle('FITUR UTAMA'),
                _footerText('• Katalog Event Kampus'),
                _footerText('• Sponsorship CRM'),
                _footerText('• Manajemen Anggaran'),
                _footerText('• Verifikasi E-Sertifikat'),

                const SizedBox(height: 16),

                _footerTitle('OPERASIONAL'),
                _footerText('• Template LPJ Resmi'),
                _footerText('• Audit Kuitansi & SPJ'),
                _footerText('• QRIS & Virtual Account'),
                _footerText('• Hak Akses Panitia'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '2026 Convena. All rights reserved',
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'V1.0.0-rc  •  Akun Architecture',
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // FOOTER BADGE
  Widget _footerBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // FOOTER TITLE
  Widget _footerTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: AppColors.accent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // FOOTER TEXT
  Widget _footerText(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: AppColors.grey,
        fontSize: 10,
        height: 1.5,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import package Google Fonts
import 'package:convena/theme.dart'; // Import file theme.dart

class CertificatePage extends StatefulWidget {
  const CertificatePage({super.key});

  @override
  State<CertificatePage> createState() =>
      _CertificatePageState();
}

class _CertificatePageState
    extends State<CertificatePage> {
  final TextEditingController _certController = TextEditingController(
    text: 'CNV-2026-ITB-8821',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.grey3,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'C',
                style: GoogleFonts.montserrat(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CONVENA',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'PORTAL OTENTIKASI RESMI',
                      style: GoogleFonts.montserrat(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Verifikasi Keaslian\nE-Sertifikat',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Validasi keabsahan dokumen penghargaan, kepanitiaan, atau kehadiran peserta acara mahasiswa melalui basis data Convena.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 12, color: AppColors.grey, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.white),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _certController,
                    style: GoogleFonts.montserrat(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Masukkan ID Sertifikat',
                      hintStyle: GoogleFonts.montserrat(color: AppColors.grey),
                      prefixIcon:
                          Icon(Icons.search, color: AppColors.accent, size: 20),
                      filled: true,
                      fillColor: Colors.black,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Memverifikasi ${_certController.text}...',
                            style: GoogleFonts.montserrat(),
                          ),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'VERIFIKASI SEKARANG',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
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
}
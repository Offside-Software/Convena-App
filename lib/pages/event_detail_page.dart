import 'package:convena/components/components.dart';
import 'package:convena/models/event.dart';
import 'package:convena/pages/payment_page.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Event Detail Page displaying event metadata, agenda overview,
/// and interactive ticket tier selection.
class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late TicketTier _selectedTier;

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
                          errorBuilder: (ctx, err, stack) => _buildPlaceholder(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        'Diselenggarakan oleh: ',
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
                      const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 14),
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
                            const Icon(Icons.calendar_today_rounded, color: AppColors.accent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal & Waktu',
                                    style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 11),
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
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, color: AppColors.accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lokasi',
                                    style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 11),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (event.description != null && event.description!.isNotEmpty) ...[
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
                              color: isSelected ? AppColors.accent : AppColors.grey2,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected ? AppColors.accent : AppColors.grey,
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
                                      color: tier.isFree ? AppColors.accent : AppColors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (tier.benefits.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Divider(color: AppColors.grey2.withValues(alpha: 0.5), height: 1),
                                const SizedBox(height: 10),
                                ...tier.benefits.map((benefit) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.check_rounded, color: AppColors.accent, size: 14),
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
                                    )),
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
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori Terpilih',
                    style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 11),
                  ),
                  Text(
                    _selectedTier.formattedPrice,
                    style: GoogleFonts.montserrat(
                      color: _selectedTier.isFree ? AppColors.accent : AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(
                        event: event,
                        selectedTier: _selectedTier,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Lanjut Beli Tiket',
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

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(Icons.event_seat_rounded, color: AppColors.grey, size: 48),
      ),
    );
  }
}

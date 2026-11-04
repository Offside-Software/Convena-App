import 'package:convena/models/event.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modular Event Card matching Convena's Web design system.
///
/// Displays the event banner, category and location tags, organizer,
/// title, short description, date, venue, capacity progress bar,
/// and lowest ticket price with a "Detail Tiket" action button.
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowestPrice = event.lowestPrice;
    final isFree = lowestPrice <= 0;
    final capacity = event.totalCapacity;
    final attendees = event.attendeeCount;
    final progress = capacity > 0 ? (attendees / capacity).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.grey2.withValues(alpha: 0.8),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.accent.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image with Tags Overlay
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFF202020),
                    child: event.bannerUrl != null && event.bannerUrl!.isNotEmpty
                        ? Image.network(
                            event.bannerUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                  // Dark bottom gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x99000000),
                            AppColors.grey3,
                          ],
                          stops: [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Category tag (Top-Left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Location Type tag (Top-Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.grey2,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        event.locationType.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Card Content Body
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organizer and Campus/Company row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.organizationName ?? 'Convena Organizer',
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (event.company != null && event.company!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              event.company!,
                              style: GoogleFonts.montserrat(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      event.title,
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Short Description
                    if (event.shortDescription != null && event.shortDescription!.isNotEmpty)
                      Text(
                        event.shortDescription!,
                        style: GoogleFonts.montserrat(
                          color: AppColors.grey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 14),

                    // Date & Location Info Rows
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.formattedDate,
                            style: GoogleFonts.montserrat(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          color: AppColors.accent,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.displayLocation,
                            style: GoogleFonts.montserrat(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Capacity Quota Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people_outline_rounded,
                              color: AppColors.accent,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Terisi',
                              style: GoogleFonts.montserrat(
                                color: AppColors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$attendees / $capacity',
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFF262626),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Divider(
                      color: AppColors.grey2.withValues(alpha: 0.6),
                      height: 1,
                    ),
                    const SizedBox(height: 14),

                    // Price & Action Button Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MULAI DARI',
                              style: GoogleFonts.montserrat(
                                color: AppColors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isFree ? 'GRATIS' : event.formattedLowestPrice,
                              style: GoogleFonts.montserrat(
                                color: isFree ? AppColors.accent : AppColors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: onTap,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.black),
                          label: Text(
                            'Detail Tiket',
                            style: GoogleFonts.montserrat(
                              color: AppColors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
        child: Icon(
          Icons.event_seat_rounded,
          color: AppColors.grey,
          size: 48,
        ),
      ),
    );
  }
}


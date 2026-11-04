import 'package:convena/components/components.dart';
import 'package:convena/models/user.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/theme_services.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final User? user;
  final AuthService? auth;

  const HomePage({super.key, this.user, this.auth});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return "Selamat pagi,";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat siang,";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat sore,";
    } else {
      return "Selamat malam,";
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = widget.auth ?? context.watch<AuthService>();
    final currentUser = widget.user ?? authService.currentUser;
    final displayName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : (currentUser?.username ?? 'Pengguna');

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: _buildTopBarForCurrentTab(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(displayName, currentUser, authService),
          _buildQRScanTab(),
          _buildEventSearchTab(),
          _buildProfileTab(currentUser, authService),
        ],
      ),
      bottomNavigationBar: ConvenaBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }

  /// Selects the appropriate modular top bar for each tab.
  /// Shows the standard "Convena" variant on Home, and provides
  /// the back button variant on sub-tabs for seamless backward navigation.
  PreferredSizeWidget _buildTopBarForCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return ConvenaTopBar(
          onNotificationTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tidak ada notifikasi baru',
                  style: GoogleFonts.montserrat(color: AppColors.white),
                ),
                backgroundColor: AppColors.grey3,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      case 1:
        return ConvenaTopBar(title: "Scan QR", showNotification: false);
      case 2:
        return ConvenaTopBar(title: "Cari Event", showNotification: false);
      case 3:
        return ConvenaTopBar(title: "Profil Pengguna", showNotification: false);
      default:
        return const ConvenaTopBar();
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 0: HOME
  // ---------------------------------------------------------------------------
  Widget _buildHomeTab(
    String displayName,
    User? currentUser,
    AuthService authService,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting matching Figma Design
          Text(
            _getGreeting(),
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayName,
            style: GoogleFonts.montserrat(
              color: AppColors.accent,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 28),

          // Dashboard Navigation Card (demonstrates Top Bar with back button variant)
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DashboardDetailPage(user: currentUser),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.grey3,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.grey2.withValues(alpha: 0.8),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_rounded,
                      color: AppColors.accent,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buka Dashboard',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lihat statistik dan ringkasan aktivitas',
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Action Cards
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Scan Tiket',
                  subtitle: 'Kamera QR',
                  icon: Icons.qr_code_scanner_rounded,
                  onTap: () => _onTabSelected(1),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Jelajah Event',
                  subtitle: 'Cari acara',
                  icon: Icons.search_rounded,
                  onTap: () => _onTabSelected(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Featured Upcoming Events section
          Text(
            'Event Mendatang',
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildEventItem(
            title: 'Convena Developer Festival 2026',
            date: '15 Nov 2026 • 09:00 WIB',
            location: 'Main Auditorium, Jakarta',
            category: 'Conference',
          ),
          const SizedBox(height: 12),
          _buildEventItem(
            title: 'Tech Meetup & Networking Night',
            date: '28 Nov 2026 • 18:30 WIB',
            location: 'Community Hub, Bandung',
            category: 'Meetup',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey3,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.grey2.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.accent, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventItem({
    required String title,
    required String date,
    required String location,
    required String category,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.grey2.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.montserrat(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.bookmark_border_rounded,
                color: AppColors.grey,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.grey,
                size: 13,
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place_outlined, color: AppColors.grey, size: 13),
              const SizedBox(width: 6),
              Text(
                location,
                style: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: QR SCAN
  // ---------------------------------------------------------------------------
  Widget _buildQRScanTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Viewfinder box
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.grey3.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.accent,
                    size: 80,
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Arahkan ke QR Code',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            Text(
              'Pindai Tiket Acara',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Arahkan kamera ke tiket QR pengunjung untuk verifikasi kehadiran secara instan.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: AppColors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Simulasi kamera aktif',
                      style: GoogleFonts.montserrat(color: AppColors.black),
                    ),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.flash_on_rounded, color: AppColors.black),
              label: Text(
                'Nyalakan Flash',
                style: GoogleFonts.montserrat(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: EVENT SEARCH
  // ---------------------------------------------------------------------------
  Widget _buildEventSearchTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.grey3,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.grey2.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: TextField(
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 14,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: AppColors.grey),
                hintText: 'Cari konser, seminar, festival...',
                hintStyle: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Categories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('Semua', isSelected: true),
                _buildCategoryChip('Musik'),
                _buildCategoryChip('Teknologi'),
                _buildCategoryChip('Seminar'),
                _buildCategoryChip('Workshop'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Hasil Pencarian',
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildEventItem(
            title: 'UI/UX Design Masterclass 2026',
            date: '5 Des 2026 • 13:00 WIB',
            location: 'Online via Zoom',
            category: 'Workshop',
          ),
          const SizedBox(height: 12),
          _buildEventItem(
            title: 'Indie Sound Showcase #4',
            date: '12 Des 2026 • 19:00 WIB',
            location: 'Hall A, Senayan',
            category: 'Musik',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String title, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : AppColors.grey3,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.grey2,
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          color: isSelected ? AppColors.black : AppColors.white,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: PROFILE
  // ---------------------------------------------------------------------------
  Widget _buildProfileTab(User? currentUser, AuthService authService) {
    final theme = context.watch<ThemeService>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        children: [
          // User Avatar & Name Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.grey3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey2, width: 1.2),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    (currentUser?.username.isNotEmpty == true)
                        ? currentUser!.username[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.montserrat(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  currentUser?.displayName ?? 'Pengguna Convena',
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${currentUser?.username ?? 'username'}',
                  style: GoogleFonts.montserrat(
                    color: AppColors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1),
                  ),
                  child: Text(
                    (currentUser?.role ?? 'USER').toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey2, width: 1.2),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: currentUser?.email ?? '-',
                ),
                const Divider(color: AppColors.grey2, height: 24),
                _buildInfoRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Mode Tema',
                  value: theme.isDark ? 'Gelap' : 'Terang',
                  trailing: Switch(
                    value: theme.isDark,
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accent.withValues(alpha: 0.5),
                    onChanged: (_) => theme.toggelTheme(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.grey3,
                    title: Text(
                      'Konfirmasi Keluar',
                      style: GoogleFonts.montserrat(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      'Apakah Anda yakin ingin keluar dari akun ini?',
                      style: GoogleFonts.montserrat(color: AppColors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.montserrat(color: AppColors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        child: Text(
                          'Keluar',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authService.logout();
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text(
                'Keluar dari Akun',
                style: GoogleFonts.montserrat(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.grey, size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }
}

/// Standalone subpage demonstrating the [ConvenaTopBar.withBack] variant
/// with the "Dashboard" label and back navigation, matching the Figma design.
class DashboardDetailPage extends StatelessWidget {
  final User? user;

  const DashboardDetailPage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: ConvenaTopBar.withBack(
        label: 'Dashboard',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Aktivitas',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Event Terdaftar',
                    value: '3',
                    icon: Icons.event_available_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Tiket Dipindai',
                    value: '18',
                    icon: Icons.qr_code_2_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Riwayat Kehadiran Terakhir',
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey3,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.grey2, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convena Developer Fest',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pukul 09:12 WIB • Check-in berhasil',
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey2, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

import 'package:convena/components/components.dart';
import 'package:convena/models/user.dart';
import 'package:convena/pages/event_detail_page.dart';
import 'package:convena/pages/scan_qr_page.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/event_service.dart';
import 'package:convena/services/theme_services.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final User? user;
  final AuthService? auth;
  final int initialIndex;

  const HomePage({super.key, this.user, this.auth, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex = widget.initialIndex;
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final eventService = context.read<EventService>();
    try {
      await eventService.fetchEvents(
        category: _selectedCategory != 'Semua' ? _selectedCategory : null,
        search: _searchController.text,
      );
    } catch (_) {
      // Handled via eventService.errorMessage in UI
    }
  }

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
          ScanQrPage(isActive: _currentIndex == 1),
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
        return ConvenaTopBar.withBack(
          label: 'Scan QR',
          onBackPressed: () => _onTabSelected(0),
        );
      case 2:
        return ConvenaTopBar.withBack(
          label: 'Cari Event',
          onBackPressed: () => _onTabSelected(0),
        );
      case 3:
        return ConvenaTopBar.withBack(
          label: 'Profil Pengguna',
          onBackPressed: () => _onTabSelected(0),
        );
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
    final eventService = context.watch<EventService>();

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: AppColors.black,
      backgroundColor: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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

            // Dashboard Navigation Card
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        DashboardDetailPage(user: currentUser),
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
            const SizedBox(height: 32),

            // Live Featured Events Header matching Web
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AGENDA PILIHAN',
                          style: GoogleFonts.montserrat(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Event Mahasiswa Terpopuler',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!eventService.isLoading &&
                    eventService.errorMessage == null)
                  TextButton.icon(
                    onPressed: () => _onTabSelected(2),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    label: Text(
                      'Semua (${eventService.events.length})',
                      style: GoogleFonts.montserrat(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // State Handling for Events
            if (eventService.isLoading) ...[
              _buildLoadingSkeleton(),
              const SizedBox(height: 16),
              _buildLoadingSkeleton(),
            ] else if (eventService.errorMessage != null) ...[
              _buildErrorView(eventService.errorMessage!),
            ] else if (eventService.events.isEmpty) ...[
              _buildEmptyState(),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventService.events.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 18),
                itemBuilder: (ctx, index) {
                  final event = eventService.events[index];
                  return EventCard(
                    event: event,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailPage(event: event),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 14, width: 120, color: const Color(0xFF262626)),
          const SizedBox(height: 8),
          Container(height: 18, width: 220, color: const Color(0xFF262626)),
          const SizedBox(height: 12),
          Container(
            height: 12,
            width: double.infinity,
            color: const Color(0xFF262626),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.danger,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Koneksi API Terputus',
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: AppColors.grey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.black,
              size: 16,
            ),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.montserrat(
                color: AppColors.black,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.grey3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey2),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, color: AppColors.grey, size: 40),
          const SizedBox(height: 12),
          Text(
            'Belum ada event tersedia saat ini.',
            style: GoogleFonts.montserrat(color: AppColors.grey, fontSize: 13),
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

  // ---------------------------------------------------------------------------
  // TAB 2: EVENT SEARCH
  // ---------------------------------------------------------------------------
  Widget _buildEventSearchTab() {
    final eventService = context.watch<EventService>();
    final categories = [
      'Semua',
      'competition',
      'seminar',
      'workshop',
      'festival',
      'conference',
      'gathering',
    ];

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
              controller: _searchController,
              onChanged: (_) => _loadEvents(),
              style: GoogleFonts.montserrat(
                color: AppColors.white,
                fontSize: 14,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: AppColors.grey),
                hintText: 'Cari event, lomba, seminar...',
                hintStyle: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.grey,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _loadEvents();
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Categories horizontal scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected =
                    _selectedCategory.toLowerCase() == cat.toLowerCase();
                return _buildCategoryChip(
                  cat,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _loadEvents();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Hasil Event (${eventService.events.length})',
            style: GoogleFonts.montserrat(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),

          if (eventService.isLoading) ...[
            _buildLoadingSkeleton(),
          ] else if (eventService.errorMessage != null) ...[
            _buildErrorView(eventService.errorMessage!),
          ] else if (eventService.events.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Text(
                'Tidak ada event yang sesuai dengan pencarian.',
                style: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eventService.events.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, index) {
                final event = eventService.events[index];
                return EventCard(
                  event: event,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(event: event),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String title, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: isSelected ? AppColors.black : AppColors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
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

import 'dart:ui';

import 'package:convena/models/user.dart';
import 'package:convena/services/auth_service.dart';
import 'package:convena/services/theme_services.dart';
import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;

  // Login Controllers
  final TextEditingController _loginIdentifierController =
      TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Register Controllers
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _loginIdentifierController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: isSuccess ? AppColors.black : AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isSuccess ? AppColors.accent : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleLogin(AuthService auth) async {
    final identifier = _loginIdentifierController.text.trim();
    final password = _loginPasswordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackbar("Silakan masukkan username/email dan kata sandi");
      return;
    }

    try {
      await auth.login(identifier, password);
      if (mounted) {
        final name = auth.currentUser?.displayName ?? auth.currentUser?.username ?? '';
        _showSnackbar("Login berhasil! Selamat datang $name", isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString());
      }
    }
  }

  Future<void> _handleRegister(AuthService auth) async {
    final username = _registerUsernameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirmPassword = _registerConfirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackbar("Username, email, dan kata sandi wajib diisi");
      return;
    }

    if (password.length < 6) {
      _showSnackbar("Kata sandi minimal 6 karakter");
      return;
    }

    if (password != confirmPassword) {
      _showSnackbar("Konfirmasi kata sandi tidak cocok");
      return;
    }

    try {
      await auth.register(username, email, password);
      if (mounted) {
        final name = auth.currentUser?.displayName ?? auth.currentUser?.username ?? '';
        _showSnackbar("Pendaftaran berhasil! Selamat datang, $name", isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeService>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: theme.colors.bg,
      body: Stack(
        children: [
          // Ambient bottom glow effect matching design
          const _BottomGlowBackground(),

          // Main form content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28.0,
                  vertical: 24.0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(4, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: auth.isAuthenticated
                      ? _buildLoggedInView(auth.currentUser!, auth)
                      : (_isLogin
                          ? _buildLoginView(
                              key: const ValueKey('login_view'),
                              auth: auth,
                            )
                          : _buildRegisterView(
                              key: const ValueKey('register_view'),
                              auth: auth,
                            )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header widget with "Welcome to" and "Convena"
  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Welcome to",
          style: GoogleFonts.montserrat(
            color: AppColors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Convena",
          style: GoogleFonts.montserrat(
            color: AppColors.accent,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  /// Reusable Input Field with styled Label, grey3 Fill, and grey2 Outline
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(color: AppColors.white, fontSize: 12),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.grey3,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.grey2, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Full-width capsule action button with loading state
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  /// Login View
  Widget _buildLoginView({required Key key, required AuthService auth}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 48),

        // Username / email input
        _buildInputField(
          label: "Username / email",
          controller: _loginIdentifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),

        // Password input
        _buildInputField(
          label: "Password",
          controller: _loginPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 14),

        // Forgot password link
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              _showSnackbar("Fitur lupa kata sandi akan segera hadir!");
            },
            child: const Text(
              "Forgot password?",
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Login button
        _buildActionButton(
          label: "Login",
          isLoading: auth.isLoading,
          onPressed: () => _handleLogin(auth),
        ),
        const SizedBox(height: 26),

        // Register navigation link
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "Don't have an account yet?",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "register here",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Register View
  Widget _buildRegisterView({required Key key, required AuthService auth}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 36),

        // Username
        _buildInputField(
          label: "Username",
          controller: _registerUsernameController,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Email
        _buildInputField(
          label: "Email",
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Password
        _buildInputField(
          label: "Password",
          controller: _registerPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Retype your password
        _buildInputField(
          label: "Retype your password",
          controller: _registerConfirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),

        // Register button
        _buildActionButton(
          label: "Register",
          isLoading: auth.isLoading,
          onPressed: () => _handleRegister(auth),
        ),
        const SizedBox(height: 22),

        // Login navigation link
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = true;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: const Text(
            "Have an account? login here",
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Logged In State View
  Widget _buildLoggedInView(User user, AuthService auth) {
    return Column(
      key: const ValueKey('logged_in_view'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 36),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.grey3,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey2, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.montserrat(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "@${user.username}",
                          style: GoogleFonts.montserrat(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent, width: 1),
                    ),
                    child: Text(
                      user.role.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.grey2, height: 1),
              const SizedBox(height: 16),
              Text(
                "Email",
                style: GoogleFonts.montserrat(
                  color: AppColors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: GoogleFonts.montserrat(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildActionButton(
          label: "Logout",
          onPressed: () async {
            await auth.logout();
            if (mounted) {
              _showSnackbar("Berhasil logout", isSuccess: true);
            }
          },
        ),
      ],
    );
  }
}

/// Ambient glow background at the bottom of the auth screen
class _BottomGlowBackground extends StatelessWidget {
  const _BottomGlowBackground();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: size.height * 0.44,
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Upper glow: Deep magenta / ruby gradient
            Positioned(
              bottom: size.height * 0.05,
              left: -size.width * 0.25,
              right: -size.width * 0.25,
              height: size.height * 0.35,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, 0.2),
                    radius: 0.9,
                    colors: [
                      Color(0xFFBA0A58),
                      Color(0xFF6B0032),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Lower glow: Radiant lime & neon yellow glow at the bottom edge
            Positioned(
              bottom: -size.height * 0.08,
              left: -size.width * 0.2,
              right: -size.width * 0.2,
              height: size.height * 0.30,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.8),
                    radius: 0.9,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.95),
                      const Color(0xFFE2FF00).withValues(alpha: 0.75),
                      const Color(0xFFC07B00).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // Soft blur backdrop to diffuse the glow seamlessly into black
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:convena/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modular and customizable top app bar for Convena.
///
/// Features two primary variants:
/// 1. [ConvenaTopBar] - Standard variant with "Convena" brand title and notification bell button.
/// 2. [ConvenaTopBar.withBack] - Navigation variant with circular back button and a label
///    (e.g., "Dashboard") to navigate backward.
class ConvenaTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title or label to display.
  final String? title;

  /// Whether this top bar displays the stylized "Convena" brand title.
  final bool isBrandTitle;

  /// Whether the back button is shown.
  final bool showBackButton;

  /// Callback when the back button is pressed. Defaults to [Navigator.maybePop].
  final VoidCallback? onBackPressed;

  /// Whether the circular notification bell button is displayed.
  final bool showNotification;

  /// Callback when the notification button is pressed.
  final VoidCallback? onNotificationTap;

  /// Custom trailing widget on the right side (overrides [showNotification] if provided).
  final Widget? trailing;

  /// Custom leading widget on the left side (overrides the title/back button prefix if provided).
  final Widget? leading;

  /// Whether to show the subtle bottom divider border.
  final bool showBottomBorder;

  /// Background color of the top bar. Defaults to [AppColors.black].
  final Color backgroundColor;

  /// Toolbar height. Defaults to 60.0.
  final double height;

  /// Standard variant with "Convena" brand title and notification bell.
  const ConvenaTopBar({
    super.key,
    this.title = 'Convena',
    this.showNotification = true,
    this.onNotificationTap,
    this.trailing,
    this.leading,
    this.showBottomBorder = true,
    this.backgroundColor = AppColors.black,
    this.height = 60.0,
  })  : isBrandTitle = true,
        showBackButton = false,
        onBackPressed = null;

  /// Navigation variant with circular back button and label (e.g. "Dashboard").
  const ConvenaTopBar.withBack({
    super.key,
    required String label,
    this.onBackPressed,
    this.showNotification = false,
    this.onNotificationTap,
    this.trailing,
    this.leading,
    this.showBottomBorder = true,
    this.backgroundColor = AppColors.black,
    this.height = 60.0,
  })  : title = label,
        isBrandTitle = false,
        showBackButton = true;

  /// Custom variant allowing full control of all properties.
  const ConvenaTopBar.custom({
    super.key,
    this.title,
    this.isBrandTitle = false,
    this.showBackButton = false,
    this.onBackPressed,
    this.showNotification = false,
    this.onNotificationTap,
    this.trailing,
    this.leading,
    this.showBottomBorder = true,
    this.backgroundColor = AppColors.black,
    this.height = 60.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  Widget _buildCircularButton({
    required Widget icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.grey3,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.grey2.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      centerTitle: false,
      titleSpacing: 20,
      title: leading ??
          (showBackButton
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircularButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onTap: () {
                        if (onBackPressed != null) {
                          onBackPressed!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(
                        title ?? '',
                        style: GoogleFonts.montserrat(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  title ?? 'Convena',
                  style: GoogleFonts.montserrat(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: isBrandTitle ? FontWeight.w800 : FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                )),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(child: trailing),
          )
        else if (showNotification)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: _buildCircularButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
                onTap: () {
                  if (onNotificationTap != null) {
                    onNotificationTap!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Belum ada notifikasi baru',
                          style: GoogleFonts.montserrat(
                            color: AppColors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: AppColors.grey3,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                tooltip: 'Notifications',
              ),
            ),
          )
        else
          const SizedBox(width: 20),
      ],
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: AppColors.grey2.withValues(alpha: 0.6),
                height: 0.8,
              ),
            )
          : null,
    );
  }
}


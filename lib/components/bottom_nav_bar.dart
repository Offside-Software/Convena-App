import 'package:convena/theme.dart';
import 'package:flutter/material.dart';

/// Navigation item model for [ConvenaBottomNavBar].
class ConvenaNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const ConvenaNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// A modular bottom navigation bar matching Convena's design.
///
/// Features 4 primary tabs by default:
/// 1. Home
/// 2. QR Scan (Camera)
/// 3. Event Search
/// 4. Profile
class ConvenaBottomNavBar extends StatelessWidget {
  /// The index of the currently active tab.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onTap;

  /// Custom items. Defaults to standard 4 tabs (Home, QR Scan, Search, Profile).
  final List<ConvenaNavItem>? items;

  /// Background color of the navigation bar.
  final Color backgroundColor;

  /// Color of the selected tab icon.
  final Color activeColor;

  /// Color of unselected tab icons.
  final Color inactiveColor;

  /// Whether to display the subtle top border divider.
  final bool showTopBorder;

  /// Height of the icon area inside the navigation bar.
  final double height;

  const ConvenaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.backgroundColor = AppColors.black,
    this.activeColor = AppColors.accent,
    this.inactiveColor = AppColors.grey,
    this.showTopBorder = true,
    this.height = 62.0,
  });

  /// Default 4 navigation items: Home, QR scan, Event search, Profile.
  static const List<ConvenaNavItem> defaultItems = [
    ConvenaNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    ConvenaNavItem(
      icon: Icons.qr_code_scanner_rounded,
      activeIcon: Icons.qr_code_scanner_rounded,
      label: 'QR Scan',
    ),
    ConvenaNavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    ConvenaNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final navItems = items ?? defaultItems;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: AppColors.grey2.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = currentIndex == index;
              final iconData = (isSelected && item.activeIcon != null)
                  ? item.activeIcon!
                  : item.icon;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkResponse(
                    onTap: () => onTap(index),
                    radius: 28,
                    splashColor: activeColor.withValues(alpha: 0.15),
                    highlightColor: Colors.transparent,
                    child: Center(
                      child: Icon(
                        iconData,
                        size: 27,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavBarItem(
              icon: Icons.home_rounded,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _AddButton(
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavBarItem(
              icon: Icons.photo_album_rounded,
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: 28,
        color: isSelected ? AppTheme.accentCyan : Colors.white.withValues(alpha: 0.5),
      ),
      onPressed: onTap,
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _AddButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.accentPurple.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainWrapper extends StatelessWidget {
  final Widget child;

  const MainWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    int currentIndex = 0;
    if (currentLocation == '/dashboard') {
      currentIndex = 0;
    } else if (currentLocation == '/cards') {
      currentIndex = 1;
    } else if (currentLocation == '/transactions') {
      currentIndex = 2;
    } else if (currentLocation == '/rewards') {
      currentIndex = 3;
    } else if (currentLocation == '/profile') {
      currentIndex = 4;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => context.go('/dashboard'),
              ),
              _buildNavItem(
                context,
                icon: Icons.credit_card_outlined,
                selectedIcon: Icons.credit_card,
                label: 'Card',
                isSelected: currentIndex == 1,
                onTap: () => context.go('/cards'),
              ),
              _buildNavItem(
                context,
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'History',
                isSelected: currentIndex == 2,
                onTap: () => context.go('/transactions'),
              ),
              _buildNavItem(
                context,
                icon: Icons.card_giftcard_outlined,
                selectedIcon: Icons.card_giftcard,
                label: 'Reward',
                isSelected: currentIndex == 3,
                onTap: () => context.go('/rewards'),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
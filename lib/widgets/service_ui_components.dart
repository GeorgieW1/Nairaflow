import 'package:flutter/material.dart';

class ServiceTabController extends StatelessWidget {
  final List<String> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final int selectedIndex;

  const ServiceTabController({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.selectedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTap?.call(index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                      ),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double amount;
  final String? cashback;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;

  const PlanCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    this.cashback,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF1E1E1E) // Dark card in dark mode
        : Colors.white; // Light card in light mode

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (accentColor ?? Theme.of(context).colorScheme.primary)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Reduced font size
                  ),
              textAlign: TextAlign.center,
              maxLines: 2, // Limit lines
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8), // Reduced spacing
            Text(
              '₦${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (cashback != null) ...[
              const SizedBox(height: 8),
              Text(
                cashback!,
                style: TextStyle(
                  color: accentColor ?? const Color(0xFF00C896),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

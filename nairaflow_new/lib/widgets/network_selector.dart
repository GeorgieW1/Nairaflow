import 'package:flutter/material.dart';
import 'package:nairaflow/models/transaction.dart';

class NetworkSelector extends StatelessWidget {
  final NetworkProvider selectedNetwork;
  final Function(NetworkProvider) onNetworkChanged;

  const NetworkSelector({
    super.key,
    required this.selectedNetwork,
    required this.onNetworkChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: NetworkProvider.values.map((network) {
        final isSelected = network == selectedNetwork;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onNetworkChanged(network),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getNetworkColor(network).withValues(alpha: isSelected ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.phone_android,
                        size: 18,
                        color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimary
                          : _getNetworkColor(network),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getNetworkDisplayName(network),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getNetworkDisplayName(NetworkProvider network) {
    switch (network) {
      case NetworkProvider.mtn:
        return 'MTN';
      case NetworkProvider.airtel:
        return 'Airtel';
      case NetworkProvider.glo:
        return 'Glo';
      case NetworkProvider.nmobile:
        return '9mobile';
    }
  }

  Color _getNetworkColor(NetworkProvider network) {
    switch (network) {
      case NetworkProvider.mtn:
        return const Color(0xFFFFD700); // MTN Yellow
      case NetworkProvider.airtel:
        return const Color(0xFFFF0000); // Airtel Red
      case NetworkProvider.glo:
        return const Color(0xFF00FF00); // Glo Green
      case NetworkProvider.nmobile:
        return const Color(0xFF00A86B); // 9mobile Green
    }
  }
}
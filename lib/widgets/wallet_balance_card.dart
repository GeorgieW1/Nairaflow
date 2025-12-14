import 'package:flutter/material.dart';

class WalletBalanceCard extends StatefulWidget {
  final double balance;
  final VoidCallback onFundWallet;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    required this.onFundWallet,
  });

  @override
  State<WalletBalanceCard> createState() => _WalletBalanceCardState();
}

class _WalletBalanceCardState extends State<WalletBalanceCard> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF1A1A1A) // Near Black for Start
                : Color(0xFF1565C0), // Blue 800
            Theme.of(context).brightness == Brightness.dark
                ? Color(0xFF0D47A1) // Deep Blue for End (BlackBlue gradient)
                : Color(0xFF42A5F5), // Blue 400
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Balance',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _isBalanceVisible
                        ? '₦${_formatBalance(widget.balance)}'
                        : '****',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Refresh for balance update',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: widget.onFundWallet,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Money',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    } else {
      return balance.toStringAsFixed(2);
    }
  }
}

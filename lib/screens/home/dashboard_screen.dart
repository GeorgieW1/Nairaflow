import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_service.dart';
import '../../widgets/wallet_balance_card.dart';
import '../../utils/ui_utils.dart';
import '../../providers/theme_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        TransactionService.initializeSampleData();
        ref.read(transactionProvider.notifier).loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light greyish background
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () => showComingSoonDialog(context),
                        ),


                        IconButton(
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark 
                                ? Icons.light_mode 
                                : Icons.dark_mode
                          ),
                          onPressed: () {
                            final brightness = Theme.of(context).brightness;
                            final newMode = brightness == Brightness.dark 
                                ? ThemeMode.light 
                                : ThemeMode.dark;
                            ref.read(themeModeProvider.notifier).state = newMode;
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Email Verification Banner
                if (user != null && !user.isEmailVerified)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Verify your email',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                              ),
                              Text(
                                'Unlock all features by verifying your email.',
                                style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/verify-email'),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  ),

                // Wallet Balance Card
                WalletBalanceCard(
                  balance: user?.walletBalance ?? 0.0,
                  onFundWallet: () => context.push('/fund-wallet'),
                ),

                const SizedBox(height: 24),

                // Quick Actions Pill Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickActionItem(
                        context,
                        icon: Icons.history,
                        label: 'History',
                        color: Colors.blue,
                        onTap: () => context.go('/transactions'),
                      ),
                      _buildQuickActionItem(
                        context,
                        icon: Icons.card_giftcard,
                        label: 'Refer & Win',
                        color: Colors.orange,
                        onTap: () => context.go('/rewards'),
                      ),
                      _buildQuickActionItem(
                        context,
                        icon: Icons.support_agent,
                        label: 'Support',
                        color: Colors.green,
                        onTap: () => showComingSoonDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment List',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Services Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                  children: [
                    _buildServiceItem(
                      context,
                      icon: Icons.phone_android,
                      label: 'Airtime',
                      onTap: () => context.push('/airtime'),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.wifi,
                      label: 'Data',
                      onTap: () => context.push('/data'),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.tv,
                      label: 'TV',
                      onTap: () => context.push('/tv-subscription'),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.lightbulb_outline,
                      label: 'Electricity',
                      onTap: () => context.push('/electricity'),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.school,
                      label: 'E-pin',
                      onTap: () => context.push('/epin'),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.sports_soccer,
                      label: 'Betting',
                      onTap: () => showComingSoonDialog(context),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.wifi_tethering,
                      label: 'Internet',
                      onTap: () => showComingSoonDialog(context),
                    ),
                    _buildServiceItem(
                      context,
                      icon: Icons.more_horiz,
                      label: 'More',
                      onTap: () => showComingSoonDialog(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Banner (Optional, matching the bottom of the screenshot)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Take Control, Stay Informed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add your email, get the latest from Nairapay',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  Future<void> _onRefresh() async {
    if (ref.read(authProvider).isAuthenticated) {
      await Future.wait([
        ref.read(authProvider.notifier).refreshUser(),
        ref.read(transactionProvider.notifier).loadTransactions(),
      ]);
    }
  }
}

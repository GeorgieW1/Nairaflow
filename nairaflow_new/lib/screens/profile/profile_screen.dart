import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nairaflow/providers/auth_provider.dart';
import 'package:nairaflow/widgets/custom_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Profile picture
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true 
                            ? user!.name[0].toUpperCase()
                            : 'U',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Profile information
              _buildInfoSection(
                context,
                title: 'Account Information',
                items: [
                  _buildInfoItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: user?.name ?? 'N/A',
                  ),
                  _buildInfoItem(
                    context,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? 'N/A',
                  ),
                  _buildInfoItem(
                    context,
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user?.phone ?? 'N/A',
                  ),
                  _buildInfoItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet Balance',
                    value: '₦${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                    valueColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Account actions
              _buildInfoSection(
                context,
                title: 'Account Actions',
                items: [
                  _buildActionItem(
                    context,
                    icon: Icons.security,
                    label: 'Security Settings',
                    onTap: () {
                      // TODO: Navigate to security settings
                      _showComingSoon(context, 'Security Settings');
                    },
                  ),
                  _buildActionItem(
                    context,
                    icon: Icons.notifications_outlined,
                    label: 'Notification Settings',
                    onTap: () {
                      // TODO: Navigate to notification settings
                      _showComingSoon(context, 'Notification Settings');
                    },
                  ),
                  _buildActionItem(
                    context,
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {
                      // TODO: Navigate to help
                      _showComingSoon(context, 'Help & Support');
                    },
                  ),
                  _buildActionItem(
                    context,
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () {
                      _showAbout(context);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Logout button
              CustomButton(
                text: 'Logout',
                onPressed: authState.isLoading ? null : () => _showLogoutDialog(context, ref),
                isLoading: authState.isLoading,
                isOutlined: true,
                prefixIcon: Icons.logout,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: items.map((item) {
              final index = items.indexOf(item);
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Logout',
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              
              // IMMEDIATELY clear auth state to stop ALL API calls
              await ref.read(authProvider.notifier).logout();
              
              // Navigate to login after clearing state
              if (context.mounted) {
                GoRouter.of(context).go('/login');
              }
            },
            width: 100,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About NairaPay'),
        content: const Text(
          'NairaPay v1.0.0\n\n'
          'Your trusted digital payment platform for airtime, data, and bill payments in Nigeria.\n\n'
          'Built with Flutter and powered by secure payment infrastructure.',
        ),
        actions: [
          CustomButton(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
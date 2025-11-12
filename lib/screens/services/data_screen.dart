import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nairaflow/models/transaction.dart';
import 'package:nairaflow/providers/auth_provider.dart';
import 'package:nairaflow/providers/transaction_provider.dart';
import 'package:nairaflow/widgets/custom_button.dart';
import 'package:nairaflow/widgets/custom_text_field.dart';
import 'package:nairaflow/widgets/network_selector.dart';

class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  
  NetworkProvider _selectedNetwork = NetworkProvider.mtn;
  String? _selectedDataPackage;
  
  final Map<NetworkProvider, List<Map<String, dynamic>>> _dataPackages = {
    NetworkProvider.mtn: [
      {'name': '100MB - 1 Day', 'price': 100.0, 'validity': '1 Day'},
      {'name': '500MB - 7 Days', 'price': 300.0, 'validity': '7 Days'},
      {'name': '1GB - 30 Days', 'price': 500.0, 'validity': '30 Days'},
      {'name': '2GB - 30 Days', 'price': 1000.0, 'validity': '30 Days'},
      {'name': '5GB - 30 Days', 'price': 2000.0, 'validity': '30 Days'},
      {'name': '10GB - 30 Days', 'price': 3500.0, 'validity': '30 Days'},
    ],
    NetworkProvider.airtel: [
      {'name': '200MB - 3 Days', 'price': 200.0, 'validity': '3 Days'},
      {'name': '750MB - 14 Days', 'price': 500.0, 'validity': '14 Days'},
      {'name': '1.5GB - 30 Days', 'price': 1000.0, 'validity': '30 Days'},
      {'name': '3GB - 30 Days', 'price': 1500.0, 'validity': '30 Days'},
      {'name': '6GB - 30 Days', 'price': 2500.0, 'validity': '30 Days'},
      {'name': '12GB - 30 Days', 'price': 4000.0, 'validity': '30 Days'},
    ],
    NetworkProvider.glo: [
      {'name': '150MB - 1 Day', 'price': 100.0, 'validity': '1 Day'},
      {'name': '650MB - 7 Days', 'price': 350.0, 'validity': '7 Days'},
      {'name': '1.35GB - 14 Days', 'price': 500.0, 'validity': '14 Days'},
      {'name': '2.9GB - 30 Days', 'price': 1000.0, 'validity': '30 Days'},
      {'name': '5.8GB - 30 Days', 'price': 2000.0, 'validity': '30 Days'},
      {'name': '14GB - 30 Days', 'price': 5000.0, 'validity': '30 Days'},
    ],
    NetworkProvider.nmobile: [
      {'name': '500MB - 30 Days', 'price': 500.0, 'validity': '30 Days'},
      {'name': '1.5GB - 30 Days', 'price': 1000.0, 'validity': '30 Days'},
      {'name': '3.5GB - 30 Days', 'price': 2000.0, 'validity': '30 Days'},
      {'name': '7.5GB - 30 Days', 'price': 4000.0, 'validity': '30 Days'},
      {'name': '15GB - 30 Days', 'price': 8000.0, 'validity': '30 Days'},
    ],
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final user = ref.watch(authProvider).user;
    final currentPackages = _dataPackages[_selectedNetwork] ?? [];

    ref.listen<TransactionState>(transactionProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          _showSuccessDialog();
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buy Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet balance info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wallet Balance: ₦${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Network selection
                Text(
                  'Select Network',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                NetworkSelector(
                  selectedNetwork: _selectedNetwork,
                  onNetworkChanged: (network) {
                    setState(() {
                      _selectedNetwork = network;
                      _selectedDataPackage = null; // Reset selection when network changes
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Phone number input
                Text(
                  'Phone Number',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (!RegExp(r'^[0-9+]+$').hasMatch(value.replaceAll(' ', ''))) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Data package selection
                Text(
                  'Select Data Package',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                ...currentPackages.map((package) {
                  final isSelected = _selectedDataPackage == package['name'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDataPackage = package['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.wifi,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    package['name'],
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Valid for ${package['validity']}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₦${package['price'].toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 32),
                
                // Purchase button
                CustomButton(
                  text: 'Purchase Data',
                  onPressed: (transactionState.isLoading || _selectedDataPackage == null) 
                    ? null 
                    : _handlePurchase,
                  isLoading: transactionState.isLoading,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePurchase() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDataPackage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a data package'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final selectedPackage = _dataPackages[_selectedNetwork]!
          .firstWhere((package) => package['name'] == _selectedDataPackage);
      
      final amount = selectedPackage['price'] as double;
      final user = ref.read(authProvider).user;
      
      if (amount > (user?.walletBalance ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insufficient wallet balance'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      
      ref.read(transactionProvider.notifier).purchaseData(
        phone: _phoneController.text.trim(),
        network: _selectedNetwork,
        amount: amount,
        dataPackage: _selectedDataPackage!,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Data Purchase Successful!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your data package has been purchased successfully.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Done',
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
          ),
        ],
      ),
    );
  }
}
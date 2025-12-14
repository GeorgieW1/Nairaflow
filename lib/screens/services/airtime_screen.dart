import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/service_ui_components.dart';

class AirtimeScreen extends ConsumerStatefulWidget {
  const AirtimeScreen({super.key});

  @override
  ConsumerState<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends ConsumerState<AirtimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  NetworkProvider _selectedNetwork = NetworkProvider.mtn;
  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];
  
  // Using tabs for networks
  final List<String> _networkTabs = ['MTN', 'Airtel', 'Glo', '9mobile'];
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final user = ref.watch(authProvider).user;

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
        title: const Text('Airtime Top-up'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/transactions'),
            child: const Text('History'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section: Network Tabs
                ServiceTabController(
                  tabs: _networkTabs,
                  selectedIndex: _selectedTabIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                      _selectedNetwork = _getNetworkFromIndex(index);
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Phone Number Input
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!RegExp(r'^0[789][01]\d{8}$').hasMatch(value)) {
                      return 'Invalid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Quick Amounts Grid
                Text(
                  'Select Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _quickAmounts.length,
                  itemBuilder: (context, index) {
                    final amount = _quickAmounts[index];
                    final isSelected = _amountController.text == amount.toStringAsFixed(0);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _amountController.text = amount.toStringAsFixed(0);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '₦${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Custom Amount Input
                CustomTextField(
                  controller: _amountController,
                  hintText: 'Or enter amount (₦50 - ₦50,000)',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  onChanged: (val) => setState(() {}), // Rebuild to update selection state
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 50) return 'Min ₦50';
                    if (amount > (user?.walletBalance ?? 0)) return 'Insufficient balance';
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Pay Button
                CustomButton(
                  text: 'Top up ${_amountController.text.isEmpty ? '' : '₦${_amountController.text}'}',
                  onPressed: transactionState.isLoading ? null : _handlePurchase,
                  isLoading: transactionState.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NetworkProvider _getNetworkFromIndex(int index) {
    switch (index) {
      case 0: return NetworkProvider.mtn;
      case 1: return NetworkProvider.airtel;
      case 2: return NetworkProvider.glo;
      case 3: return NetworkProvider.nmobile;
      default: return NetworkProvider.mtn;
    }
  }

  void _handlePurchase() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text);
      ref.read(transactionProvider.notifier).purchaseAirtime(
            phone: _phoneController.text.trim(),
            network: _selectedNetwork,
            amount: amount,
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
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Successful!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Airtime purchase successful.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

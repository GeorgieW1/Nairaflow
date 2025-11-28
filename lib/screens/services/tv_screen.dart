import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nairaflow_new/providers/transaction_provider.dart';
import 'package:nairaflow_new/services/tv_service.dart';
import 'package:nairaflow_new/widgets/custom_button.dart';
import 'package:nairaflow_new/widgets/custom_text_field.dart';

class TVScreen extends ConsumerStatefulWidget {
  const TVScreen({super.key});

  @override
  ConsumerState<TVScreen> createState() => _TVScreenState();
}

class _TVScreenState extends ConsumerState<TVScreen> {
  final _formKey = GlobalKey<FormState>();
  final _smartcardController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _selectedProvider = 'DSTV';
  String? _selectedBouquetCode;
  Map<String, dynamic>? _selectedBouquet;
  
  bool _isVerifying = false;
  bool _isSmartcardVerified = false;
  Map<String, dynamic>? _customerDetails;
  
  bool _isLoadingPlans = false;
  List<dynamic> _availablePlans = [];
  
  final List<Map<String, dynamic>> _providers = [
    {'code': 'DSTV', 'name': 'DSTV', 'color': const Color(0xFF00A4E4)},
    {'code': 'GOTV', 'name': 'GOtv', 'color': const Color(0xFFF37021)},
    {'code': 'STARTIMES', 'name': 'Startimes', 'color': const Color(0xFF0072CE)},
  ];

  @override
  void dispose() {
    _smartcardController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _availablePlans = [];
      _selectedBouquetCode = null;
      _selectedBouquet = null;
    });

    try {
      final plans = await TVService.getTVPlans(_selectedProvider);
      if (mounted) {
        setState(() {
          _availablePlans = plans;
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlans = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load plans: $e')),
        );
      }
    }
  }

  Future<void> _verifySmartcard() async {
    if (_smartcardController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid smartcard number')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _customerDetails = null;
      _isSmartcardVerified = false;
    });

    try {
      final details = await TVService.verifySmartcard(
        smartcardNumber: _smartcardController.text,
        provider: _selectedProvider,
      );

      if (mounted) {
        setState(() {
          _customerDetails = details['data'];
          _isSmartcardVerified = true;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isSmartcardVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  void _onProviderChanged(String provider) {
    if (_selectedProvider != provider) {
      setState(() {
        _selectedProvider = provider;
        _isSmartcardVerified = false;
        _customerDetails = null;
        _smartcardController.clear();
      });
      _loadPlans();
    }
  }

  Future<void> _handleSubscription() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSmartcardVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify smartcard first')),
      );
      return;
    }
    if (_selectedBouquet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bouquet')),
      );
      return;
    }

    double amount;
    try {
      amount = double.parse(_selectedBouquet!['amount'].toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid plan amount')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: $_selectedProvider'),
            const SizedBox(height: 8),
            Text('Bouquet: ${_selectedBouquet!['name']}'),
            const SizedBox(height: 8),
            Text('Smartcard: ${_smartcardController.text}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Customer: ${_customerDetails?['customerName'] ?? 'Unknown'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: ₦${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(transactionProvider.notifier).subscribeTVService(
      smartcardNumber: _smartcardController.text,
      provider: _selectedProvider,
      bouquetCode: _selectedBouquetCode!,
      amount: amount,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    if (mounted) {
      final state = ref.read(transactionProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      } else {
        _showSuccessDialog(amount);
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Subscription Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have successfully subscribed to ${_selectedBouquet!['name']}'),
            const SizedBox(height: 8),
            Text(
              'Amount: ₦${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Smartcard: ${_smartcardController.text}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/dashboard'); // Go to dashboard
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final isLoading = transactionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV Subscription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Selection
              Text(
                'Select Provider',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: _providers.map((provider) {
                  final isSelected = _selectedProvider == provider['code'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: isLoading ? null : () => _onProviderChanged(provider['code']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? provider['color'] 
                              : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                ? provider['color']
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                provider['name'],
                                style: TextStyle(
                                  color: isSelected 
                                    ? Colors.white 
                                    : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),

              // Smartcard Verification
              Text(
                'Smartcard Number',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _smartcardController,
                      hintText: 'Enter Smartcard / IUC Number',
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      onChanged: (_) {
                        if (_isSmartcardVerified) {
                          setState(() {
                            _isSmartcardVerified = false;
                            _customerDetails = null;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 10) {
                          return 'Invalid length';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: isLoading || _isVerifying 
                        ? null 
                        : _verifySmartcard,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                    ),
                  ),
                ],
              ),

              // Verification Result
              if (_customerDetails != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customer Verified',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Name: ${_customerDetails!['customerName']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_customerDetails!['currentBouquet'] != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Plan: ${_customerDetails!['currentBouquet']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Bouquet Selection
              Text(
                'Select Package',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isLoadingPlans)
                const Center(child: CircularProgressIndicator())
              else if (_availablePlans.isEmpty)
                const Text('No plans available')
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedBouquetCode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  hint: const Text('Choose a package'),
                  items: _availablePlans.map((plan) {
                    return DropdownMenuItem<String>(
                      value: plan['code'],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₦${plan['amount']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isLoading ? null : (value) {
                    setState(() {
                      _selectedBouquetCode = value;
                      _selectedBouquet = _availablePlans.firstWhere(
                        (p) => p['code'] == value,
                        orElse: () => null,
                      );
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Phone Number (Optional)
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                hintText: 'For transaction notifications',
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
              ),

              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Subscribe',
                isLoading: isLoading,
                onPressed: _handleSubscription,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


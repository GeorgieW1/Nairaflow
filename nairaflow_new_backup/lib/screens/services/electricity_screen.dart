import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/electricity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ElectricityScreen extends ConsumerStatefulWidget {
  const ElectricityScreen({super.key});

  @override
  ConsumerState<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends ConsumerState<ElectricityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meterNumberController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedDisco = 'AEDC';
  String _selectedMeterType = 'prepaid';

  bool _isMeterVerified = false;
  bool _isVerifying = false;
  Map<String, dynamic>? _customerDetails;

  final List<Map<String, String>> _discos = [
    {'code': 'AEDC', 'name': 'Abuja Electricity'},
    {'code': 'EKEDC', 'name': 'Eko Electricity'},
    {'code': 'KEDCO', 'name': 'Kano Electricity'},
    {'code': 'PHED', 'name': 'Port Harcourt Electricity'},
    {'code': 'JED', 'name': 'Jos Electricity'},
    {'code': 'IBEDC', 'name': 'Ibadan Electricity'},
    {'code': 'KAEDCO', 'name': 'Kaduna Electricity'},
    {'code': 'EEDC', 'name': 'Enugu Electricity'},
    {'code': 'BEDC', 'name': 'Benin Electricity'},
    {'code': 'YEDC', 'name': 'Yola Electricity'},
  ];

  final List<String> _meterTypes = ['prepaid', 'postpaid'];
  final List<double> _quickAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _meterNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _verifyMeter() async {
    if (_meterNumberController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid meter number')),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _customerDetails = null;
      _isMeterVerified = false;
    });

    try {
      final details = await ElectricityService.verifyMeter(
        meterNumber: _meterNumberController.text,
        disco: _selectedDisco,
        meterType: _selectedMeterType,
      );

      if (mounted) {
        setState(() {
          _customerDetails = details;
          _isMeterVerified = true;
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _isMeterVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
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
          _showSuccessDialog(
            _meterNumberController.text.trim(),
            _selectedDisco,
            double.parse(_amountController.text),
          );
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
          'Pay Electricity',
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
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
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

                // Distribution company selection
                Text(
                  'Distribution Company',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDisco,
                      isExpanded: true,
                      items: _discos.map((disco) {
                        return DropdownMenuItem<String>(
                          value: disco['code'],
                          child: Text(
                            disco['name']!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDisco = value;
                            _isMeterVerified = false;
                            _customerDetails = null;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Meter type selection
                Text(
                  'Meter Type',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMeterType,
                      isExpanded: true,
                      items: _meterTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type.toUpperCase(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMeterType = value;
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Meter number input
                Text(
                  'Meter Number',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _meterNumberController,
                        hintText: 'Enter meter number',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.electrical_services,
                        onChanged: (value) {
                          if (_isMeterVerified) {
                            setState(() {
                              _isMeterVerified = false;
                              _customerDetails = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter meter number';
                          }
                          if (!RegExp(r'^[0-9\-\/]{11,16}$').hasMatch(value)) {
                            return '11-16 digits required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isVerifying ||
                                _meterNumberController.text.length < 10
                            ? null
                            : _verifyMeter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Meter Verified',
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
                                'Name: ${_customerDetails!['customerName'] ?? _customerDetails!['name'] ?? 'Unknown'}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_customerDetails!['address'] != null)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Address: ${_customerDetails!['address']}',
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

                // Quick amount selection
                Text(
                  'Quick Amounts',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _quickAmounts.map((amount) {
                    return GestureDetector(
                      onTap: () {
                        _amountController.text = amount.toStringAsFixed(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '₦${amount.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Amount input
                Text(
                  'Amount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _amountController,
                  hintText: 'Enter amount',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.money,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount < 500) {
                      return 'Minimum amount is ₦500';
                    }
                    if (amount > (user?.walletBalance ?? 0)) {
                      return 'Insufficient wallet balance';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Pay button
                CustomButton(
                  text: 'Pay Electricity Bill',
                  onPressed: transactionState.isLoading ? null : _handlePayment,
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

  void _handlePayment() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isMeterVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please verify meter number first'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Verify',
              textColor: Colors.white,
              onPressed: _verifyMeter,
            ),
          ),
        );
        return;
      }

      final amount = double.parse(_amountController.text);

      ref.read(transactionProvider.notifier).payElectricity(
            meterNumber: _meterNumberController.text.trim(),
            amount: amount,
            disco: _selectedDisco,
            meterType: _selectedMeterType,
          );
    }
  }

  void _showSuccessDialog(String meterNumber, String provider, double amount) {
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
              'Payment Successful!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '₦${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$provider - $meterNumber',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your electricity bill has been paid successfully.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
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

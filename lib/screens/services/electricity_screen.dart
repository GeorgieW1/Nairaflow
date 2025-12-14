import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/electricity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/service_ui_components.dart';

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
    {'code': 'AEDC', 'name': 'Abuja'},
    {'code': 'EKEDC', 'name': 'Eko'},
    {'code': 'KEDCO', 'name': 'Kano'},
    {'code': 'PHED', 'name': 'Port Harcourt'},
    {'code': 'JED', 'name': 'Jos'},
    {'code': 'IBEDC', 'name': 'Ibadan'},
    {'code': 'KAEDCO', 'name': 'Kaduna'},
    {'code': 'EEDC', 'name': 'Enugu'},
    {'code': 'BEDC', 'name': 'Benin'},
    {'code': 'YEDC', 'name': 'Yola'},
  ];

  final List<String> _meterTypes = ['Prepaid', 'Postpaid'];
  int _selectedMeterTypeIndex = 0;

  @override
  void dispose() {
    _meterNumberController.dispose();
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
        title: const Text('Electricity Bill'),
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
                // Meter Type Tabs
                ServiceTabController(
                  tabs: _meterTypes,
                  selectedIndex: _selectedMeterTypeIndex,
                  onTap: (index) {
                    setState(() {
                      _selectedMeterTypeIndex = index;
                      _selectedMeterType = _meterTypes[index].toLowerCase();
                      _isMeterVerified = false;
                      _customerDetails = null;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Disco Grid
                Text(
                  'Select Provider',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _discos.length,
                  itemBuilder: (context, index) {
                    final disco = _discos[index];
                    final isSelected = _selectedDisco == disco['code'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDisco = disco['code']!;
                          _isMeterVerified = false;
                          _customerDetails = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primaryContainer 
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              disco['name']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Meter Number Input
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _meterNumberController,
                        hintText: 'Meter Number',
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_isMeterVerified) {
                            setState(() {
                              _isMeterVerified = false;
                              _customerDetails = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isVerifying ? null : _verifyMeter,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Verify'),
                      ),
                    ),
                  ],
                ),

                if (_customerDetails != null) ...[
                  const SizedBox(height: 12),
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
                                _customerDetails!['customerName'] ?? 'Verified User',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_customerDetails!['address'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 28),
                            child: Text(
                              _customerDetails!['address'],
                              style: TextStyle(fontSize: 12, color: Colors.green[700]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Amount Input
                CustomTextField(
                  controller: _amountController,
                  hintText: 'Amount (Min ₦500)',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.attach_money,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 500) return 'Min ₦500';
                    if (amount > (user?.walletBalance ?? 0)) return 'Insufficient balance';
                    return null;
                  },
                ),

                const SizedBox(height: 40),

                // Pay Button
                CustomButton(
                  text: 'Pay Bill',
                  onPressed: transactionState.isLoading ? null : _handlePayment,
                  isLoading: transactionState.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyMeter() async {
    if (_meterNumberController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid meter number')),
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

  void _handlePayment() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isMeterVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify meter first')),
        );
        return;
      }

      ref.read(transactionProvider.notifier).payElectricity(
            meterNumber: _meterNumberController.text.trim(),
            amount: double.parse(_amountController.text),
            disco: _selectedDisco,
            meterType: _selectedMeterType,
          );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            const Text('Payment Successful!'),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nairaflow_new/models/transaction.dart' as model;
import 'package:nairaflow_new/providers/auth_provider.dart';
import 'package:nairaflow_new/providers/transaction_provider.dart';
import 'package:nairaflow_new/services/epin_service.dart'; // Service import
import 'package:nairaflow_new/widgets/custom_button.dart';
import 'package:nairaflow_new/widgets/custom_text_field.dart';

class EpinScreen extends ConsumerStatefulWidget {
  const EpinScreen({super.key});

  @override
  ConsumerState<EpinScreen> createState() => _EpinScreenState();
}

class _EpinScreenState extends ConsumerState<EpinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'WAEC';
  String? _selectedPlanId;
  Map<String, dynamic>? _selectedPlan;
  int _quantity = 1;

  bool _isLoadingPlans = false;
  List<dynamic> _availablePlans = [];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'WAEC', 'name': 'WAEC Result Checker', 'icon': Icons.school},
    {'id': 'NECO', 'name': 'NECO Result Token', 'icon': Icons.menu_book},
    {'id': 'JAMB', 'name': 'JAMB UTME PIN', 'icon': Icons.assignment},
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPlans();

    // Pre-fill email/phone from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _emailController.text = user.email;
        _phoneController.text = user.phone;
      }
    });
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _availablePlans = [];
      _selectedPlanId = null;
      _selectedPlan = null;
    });

    try {
      final plans = await EpinService.getEpinPlans(_selectedCategory);
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

  void _onCategoryChanged(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      _loadPlans();
    }
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan')),
      );
      return;
    }

    final amount = (_selectedPlan!['amount'] as num).toDouble() * _quantity;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam: $_selectedCategory'),
            const SizedBox(height: 8),
            Text('Plan: ${_selectedPlan!['name']}'),
            const SizedBox(height: 8),
            Text('Quantity: $_quantity'),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ₦${amount.toStringAsFixed(2)}',
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
            child: const Text('Purchase'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(transactionProvider.notifier).purchaseEpin(
          category: _selectedCategory,
          quantity: _quantity,
          amount: amount,
          phone:
              _phoneController.text.isNotEmpty ? _phoneController.text : null,
        );

    if (mounted) {
      final state = ref.read(transactionProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      } else {
        // Find the latest transaction (which is the one we just created)
        final latestTransaction = state.transactions.first;
        _showSuccessDialog(latestTransaction);
      }
    }
  }

  void _showSuccessDialog(model.Transaction transaction) {
    final pins =
        (transaction as dynamic).metadata?['pins'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Purchase Successful'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'You have successfully purchased $_quantity ${_selectedCategory} PIN(s)'),
              const SizedBox(height: 16),
              if (pins.isNotEmpty) ...[
                const Text(
                  'Your PINs:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: pins
                          .map((pin) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.grey.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pin.toString(),
                                        style: const TextStyle(
                                          fontFamily: 'Monospace',
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: pin.toString()));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'PIN copied to clipboard')),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
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
    final user = ref.watch(authProvider).user;
    final isLoading = transactionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam PINs'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Text(
                        'Wallet Balance: ₦${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Select Exam',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['id'];
                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _onCategoryChanged(category['id']),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'],
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category['name'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Plan Selection
              Text(
                'Select Package',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isLoadingPlans)
                const Center(child: CircularProgressIndicator())
              else if (_availablePlans.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Text('No plans available'),
                      TextButton.icon(
                        onPressed: _loadPlans,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedPlanId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  hint: const Text('Choose a package'),
                  items: _availablePlans.map((plan) {
                    return DropdownMenuItem<String>(
                      value: plan['id'], // Assuming plan has an ID
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          children: [
                            TextSpan(text: plan['name']),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: '₦${plan['amount']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedPlanId = value;
                            _selectedPlan = _availablePlans.firstWhere(
                              (p) => p['id'] == value,
                              orElse: () => null,
                            );
                          });
                        },
                ),

              const SizedBox(height: 24),

              // Quantity Selection
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _quantity,
                    isExpanded: true,
                    items: List.generate(10, (index) => index + 1).map((val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val'),
                      );
                    }).toList(),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _quantity = value;
                              });
                            }
                          },
                  ),
                ),
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
                text: 'Purchase',
                isLoading: isLoading,
                onPressed: _handlePurchase,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nairapay/models/transaction.dart' as model;
import 'package:nairapay/providers/auth_provider.dart';
import 'package:nairapay/providers/transaction_provider.dart';
import 'package:nairapay/services/epin_service.dart';
import 'package:nairapay/widgets/custom_button.dart';
import 'package:nairapay/widgets/custom_text_field.dart';
import 'package:nairapay/widgets/service_ui_components.dart';

class EpinScreen extends ConsumerStatefulWidget {
  const EpinScreen({super.key});

  @override
  ConsumerState<EpinScreen> createState() => _EpinScreenState();
}

class _EpinScreenState extends ConsumerState<EpinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String _selectedCategory = 'WAEC';
  String? _selectedPlanId;
  Map<String, dynamic>? _selectedPlan;
  int _quantity = 1;

  bool _isLoadingPlans = false;
  List<dynamic> _availablePlans = [];

  final List<String> _examTabs = ['WAEC', 'NECO', 'JAMB'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _phoneController.text = user.phone;
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _availablePlans = [];
      _selectedPlanId = null;
      _selectedPlan = null;
    });

    try {
      // Only fetch for WAEC for now as others might not be ready
      if (_selectedCategory == 'WAEC') {
        final plans = await EpinService.getEpinPlans(_selectedCategory);
        if (mounted) {
          setState(() {
            _availablePlans = plans;
            _isLoadingPlans = false;
          });
        }
      } else {
        // Simulate empty or coming soon for others
        setState(() {
          _availablePlans = [];
          _isLoadingPlans = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlans = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load plans: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Exam PINs'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/transactions'),
            child: const Text('History'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section: Exam Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ServiceTabController(
                tabs: _examTabs,
                selectedIndex: _selectedTabIndex,
                onTap: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                    _selectedCategory = _examTabs[index];
                    _selectedPlanId = null;
                    _selectedPlan = null;
                  });
                  _loadPlans();
                },
              ),
            ),

            // Content
            Expanded(
              child: _selectedCategory != 'WAEC'
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.construction, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '$_selectedCategory PINs Coming Soon',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : _isLoadingPlans
                      ? const Center(child: CircularProgressIndicator())
                      : _availablePlans.isEmpty
                          ? const Center(child: Text('No plans available'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Package',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _availablePlans.length,
                                    itemBuilder: (context, index) {
                                      final plan = _availablePlans[index];
                                      final isSelected = _selectedPlanId == plan['id'];
                                      
                                      return PlanCard(
                                        title: plan['name'],
                                        amount: double.parse(plan['amount'].toString()),
                                        isSelected: isSelected,
                                        onTap: () {
                                          setState(() {
                                            _selectedPlanId = plan['id'];
                                            _selectedPlan = plan;
                                          });
                                        },
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 32),

                                  // Quantity
                                  Text(
                                    'Quantity',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      IconButton.filledTonal(
                                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Container(
                                        width: 60,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_quantity',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        onPressed: _quantity < 10 ? () => setState(() => _quantity++) : null,
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),

                                  // Phone Number
                                  CustomTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number (Optional)',
                                    hintText: 'For transaction notifications',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_android,
                                  ),
                                ],
                              ),
                            ),
            ),

            // Bottom Action Bar
            if (_selectedPlan != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomButton(
                    text: 'Pay ₦${((_selectedPlan!['amount'] as num) * _quantity).toStringAsFixed(0)}',
                    onPressed: transactionState.isLoading ? null : _handlePurchase,
                    isLoading: transactionState.isLoading,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    if (!_formKey.currentState!.validate()) return; // Although we don't have a form key wrapping everything, we might need one if we add validation. Currently phone is optional.
    
    final amount = (_selectedPlan!['amount'] as num).toDouble() * _quantity;

    // Show confirmation dialog (simplified for this refactor, ideally match others)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Exam: $_selectedCategory'),
            Text('Plan: ${_selectedPlan!['name']}'),
            Text('Quantity: $_quantity'),
            const SizedBox(height: 8),
            Text('Total: ₦${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Purchase')),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(transactionProvider.notifier).purchaseEpin(
      category: _selectedCategory,
      quantity: _quantity,
      amount: amount,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
    );

    if (mounted) {
      final state = ref.read(transactionProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
      } else {
        final latestTransaction = state.transactions.first;
        _showSuccessDialog(latestTransaction);
      }
    }
  }

  void _showSuccessDialog(model.Transaction transaction) {
    final pins = (transaction as dynamic).metadata?['pins'] as List<dynamic>? ?? [];

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
              Text('You have successfully purchased $_quantity $_selectedCategory PIN(s)'),
              const SizedBox(height: 16),
              if (pins.isNotEmpty) ...[
                const Text('Your PINs:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: pins.map((pin) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                pin.toString(),
                                style: const TextStyle(fontFamily: 'Monospace', fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: pin.toString()));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN copied')));
                              },
                            ),
                          ],
                        ),
                      )).toList(),
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
              Navigator.pop(context);
              context.go('/dashboard');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

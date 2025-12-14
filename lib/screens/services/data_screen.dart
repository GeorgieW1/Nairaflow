import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/data_plan.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/data_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/network_selector.dart';
import '../../widgets/service_ui_components.dart';

class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  NetworkProvider _selectedNetwork = NetworkProvider.mtn;
  DataPlan? _selectedDataPlan;
  List<DataPlan> _allDataPlans = [];
  bool _isLoadingPlans = false;
  String? _plansError;

  int _selectedTabIndex = 0;
  final List<String> _tabs = ['HOT', 'Daily', 'Weekly', 'Monthly', 'Always-On'];

  @override
  void initState() {
    super.initState();
    _loadDataPlans();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadDataPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _plansError = null;
    });

    try {
      final plans = await DataService.fetchDataPlans(_selectedNetwork);
      setState(() {
        _allDataPlans = plans;
        _isLoadingPlans = false;
        _selectedDataPlan = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlans = false;
        _plansError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<DataPlan> _getFilteredPlans() {
    if (_allDataPlans.isEmpty) return [];

    final category = _tabs[_selectedTabIndex];
    
    return _allDataPlans.where((plan) {
      // Normalize strings for comparison
      final name = plan.name.toLowerCase();
      // Use validity if available, otherwise fallback to name which often contains duration
      final validity = (plan.validity ?? name).toLowerCase();
      
      switch (category) {
        case 'HOT':
          // Heuristic: Cheap plans (< 500) or specifically named
          return plan.amount <= 500 || name.contains('hot') || name.contains('special') || name.contains('promo');
        case 'Daily':
          // Matches "1 Day", "2 Days", "24 hours"
          return (validity.contains('day') && !validity.contains('30 day') && !validity.contains('7 day')) || 
                 validity.contains('24 hours') || 
                 validity.contains('daily');
        case 'Weekly':
          // Matches "7 Days", "1 Week", "Weekly"
          return validity.contains('7 day') || validity.contains('week');
        case 'Monthly':
          // Matches "30 Days", "Month", "Monthly"
          return validity.contains('30 day') || validity.contains('month');
        case 'Always-On':
          // Plans that don't fit the standard daily/weekly/monthly buckets or are long-term
          return !validity.contains('1 day') && 
                 !validity.contains('2 day') && 
                 !validity.contains('daily') &&
                 !validity.contains('7 day') && 
                 !validity.contains('week') && 
                 !validity.contains('30 day') && 
                 !validity.contains('month');
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final user = ref.watch(authProvider).user;

    ref.listen<TransactionState>(transactionProvider, (previous, next) {
      if (previous?.isLoading == true && next.isLoading == false) {
        if (next.error != null) {
          final errorMessage = next.error!
              .replaceFirst('Exception: ', '')
              .replaceFirst('Data purchase failed: ', '');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else {
          _showSuccessDialog();
        }
      }
    });

    final filteredPlans = _getFilteredPlans();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mobile Data'),
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
            // Top Section (Wallet & Network)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Selector (Using existing widget but could be tabs if preferred)
                  NetworkSelector(
                    selectedNetwork: _selectedNetwork,
                    onNetworkChanged: (network) {
                      setState(() {
                        _selectedNetwork = network;
                        _selectedDataPlan = null;
                      });
                      _loadDataPlans();
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Phone Input
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      controller: _phoneController,
                      hintText: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_android,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),

                  // Tabs
                  ServiceTabController(
                    tabs: _tabs,
                    selectedIndex: _selectedTabIndex,
                    onTap: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                        _selectedDataPlan = null;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoadingPlans
                  ? const Center(child: CircularProgressIndicator())
                  : _plansError != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_plansError!, style: const TextStyle(color: Colors.red)),
                              TextButton(
                                onPressed: _loadDataPlans,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredPlans.isEmpty
                          ? Center(
                              child: Text(
                                'No ${_tabs[_selectedTabIndex]} plans available',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: filteredPlans.length,
                              itemBuilder: (context, index) {
                                final plan = filteredPlans[index];
                                final isSelected = _selectedDataPlan?.variationCode == plan.variationCode;
                                
                                return PlanCard(
                                  title: _formatPlanName(plan.name),
                                  subtitle: plan.validity ?? _extractValidity(plan.name),
                                  amount: plan.amount,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedDataPlan = plan;
                                    });
                                  },
                                );
                              },
                            ),
            ),

            // Bottom Action Bar
            if (_selectedDataPlan != null)
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
                    text: 'Pay ₦${_selectedDataPlan!.amount.toStringAsFixed(0)}',
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

  String _formatPlanName(String name) {
    // Helper to clean up plan names if needed, e.g., "1.5GB Data" -> "1.5GB"
    // For now, just return the name or split it if it's too long
    return name.split(' - ').first; 
  }

  String _extractValidity(String name) {
    // Try to find patterns like "1 Day", "30 Days", "Weekly", "Monthly" in the name
    final lowerName = name.toLowerCase();
    if (lowerName.contains('1 day')) return '1 Day';
    if (lowerName.contains('2 day')) return '2 Days';
    if (lowerName.contains('7 day') || lowerName.contains('weekly')) return '7 Days';
    if (lowerName.contains('30 day') || lowerName.contains('monthly')) return '30 Days';
    if (lowerName.contains('3 month')) return '3 Months';
    return 'Unknown';
  }

  void _handlePurchase() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDataPlan == null) return;

      final user = ref.read(authProvider).user;
      if (_selectedDataPlan!.amount > (user?.walletBalance ?? 0)) {
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
            amount: _selectedDataPlan!.amount,
            dataPackage: _selectedDataPlan!.name,
            variationCode: _selectedDataPlan!.variationCode,
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
            const Text(
              'Successful!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text('Your data purchase was successful.'),
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

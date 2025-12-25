import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/transaction_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class FundWalletScreen extends ConsumerStatefulWidget {
  const FundWalletScreen({super.key});

  @override
  ConsumerState<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends ConsumerState<FundWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Palmpay Transfer',
  ];
  
  final List<double> _quickAmounts = [1000, 2000, 5000, 10000, 20000, 50000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fund Wallet',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                _buildBalanceCard(user?.walletBalance ?? 0.0),
                const SizedBox(height: 32),
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._paymentMethods.map((method) => _buildPaymentMethodTile(method)),
                const SizedBox(height: 24),
                Text(
                  'Quick Amounts',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildQuickAmountGrid(),
                const SizedBox(height: 24),
                Text(
                  'Enter Funding Amount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _amountController,
                  hintText: 'Min ₦100',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.account_balance_wallet,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 100) return 'Minimum funding is ₦100';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: _isLoading ? 'Processing...' : 'Generate Transfer Details',
                  onPressed: _isLoading ? null : _handlePalmpayFunding,
                ),
                const SizedBox(height: 24),
                _buildSecurityNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)], 
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Current Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '₦${balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String method) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildQuickAmountGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _quickAmounts.map((amount) {
        return InkWell(
          onTap: () => _amountController.text = amount.toStringAsFixed(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text('₦${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your RSA-signed Palmpay request ensures top-tier security. Follow transfer instructions carefully.',
              style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePalmpayFunding() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      try {
        final amount = double.parse(_amountController.text);
        
        final authState = ref.read(authProvider);
        
        // Fix: According to your auth_provider.dart, AuthState does NOT have a token.
        // It is stored inside the User object. We access it via authState.user?.token.
        final String? sessionToken = authState.token;

        
        if (sessionToken == null || sessionToken.isEmpty) {
          throw Exception('Authentication session error. Please logout and login back.');
        }

        final result = await TransactionService.initiatePalmpay(sessionToken, amount);
        
        setState(() => _isLoading = false);

        if (result != null && mounted) {
          _showTransferSheet(
            bankName: result['bankName'] ?? 'Palmpay',
            accountNumber: result['accountNumber'] ?? '',
            accountName: result['accountName'] ?? '',
            amount: amount,
            reference: result['reference'] ?? '',
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showTransferSheet({
    required String bankName,
    required String accountNumber,
    required String accountName,
    required double amount,
    required String reference,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            const Text('Transfer Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Use your bank app to transfer exactly ₦${amount.toStringAsFixed(2)}.', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            
            _copyableRow('Bank Name', bankName),
            _copyableRow('Account Number', accountNumber),
            _copyableRow('Account Name', accountName),
            _copyableRow('Payment Ref/Memo', reference, isHighlight: true),
            
            const SizedBox(height: 32),
            CustomButton(
              text: 'I have made the transfer',
              onPressed: () {
                Navigator.pop(context);
                context.pop();
                _showSuccessDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Your transfer is being verified via Palmpay webhooks. Please allow 2-5 minutes for your balance to reflect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _copyableRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isHighlight ? Colors.blue : Colors.black87
                  )
                )
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied!'), duration: const Duration(seconds: 1)),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
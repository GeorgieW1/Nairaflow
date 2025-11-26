import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nairaflow/models/transaction.dart';
import 'package:share_plus/share_plus.dart';

class TransactionReceiptScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionReceiptScreen({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Transaction Receipt',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(),
            tooltip: 'Share Receipt',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            _buildStatusHeader(context),
            
            const SizedBox(height: 24),
            
            // Receipt Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo/Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'NairaFlow',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Receipt Details
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Amount
                          Text(
                            '₦${transaction.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Transaction Type
                          Text(
                            transaction.typeDisplayName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          
                          // Transaction Details
                          _buildDetailRow('Transaction ID', transaction.id),
                          _buildDetailRow('Status', _getStatusText()),
                          _buildDetailRow(
                            'Date',
                            DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.createdAt),
                          ),
                          
                          // Conditional fields based on transaction type
                          if (transaction.type == TransactionType.airtime || 
                              transaction.type == TransactionType.data)
                            ...[
                              _buildDetailRow('Phone Number', transaction.phone ?? 'N/A'),
                              _buildDetailRow('Network', transaction.networkDisplayName),
                            ],
                          
                          if (transaction.type == TransactionType.electricity)
                            _buildDetailRow('Meter Number', transaction.phone ?? 'N/A'),
                          
                          if (transaction.type == TransactionType.funding)
                            _buildDetailRow('Payment Method', 'Paystack'),
                          
                          if (transaction.description != null)
                            _buildDetailRow('Description', transaction.description!),
                          
                          if (transaction.type == TransactionType.data && 
                              transaction.description != null)
                            _buildDetailRow('Data Plan', transaction.description!),
                        ],
                      ),
                    ),
                    
                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Thank you for using NairaFlow!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For support: support@nairaflow.com',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Copy Transaction ID
                  OutlinedButton.icon(
                    onPressed: () => _copyTransactionId(context),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Transaction ID'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Share Receipt
                  ElevatedButton.icon(
                    onPressed: _shareReceipt,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Receipt'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (transaction.status) {
      case TransactionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Transaction Successful';
        break;
      case TransactionStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Transaction Pending';
        break;
      case TransactionStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Transaction Failed';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      color: statusColor.withValues(alpha: 0.1),
      child: Column(
        children: [
          Icon(
            statusIcon,
            size: 64,
            color: statusColor,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.success:
        return 'Success';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  void _copyTransactionId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transaction.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareReceipt() {
    final receiptText = '''
━━━━━━━━━━━━━━━━━━━━━━
   NAIRAFLOW RECEIPT
━━━━━━━━━━━━━━━━━━━━━━

Amount: ₦${transaction.amount.toStringAsFixed(2)}
Type: ${transaction.typeDisplayName}
Status: ${_getStatusText()}

Transaction ID: ${transaction.id}
Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(transaction.createdAt)}

${transaction.type == TransactionType.airtime || transaction.type == TransactionType.data ? 'Phone: ${transaction.phone ?? 'N/A'}\nNetwork: ${transaction.networkDisplayName}' : ''}
${transaction.type == TransactionType.electricity ? 'Meter: ${transaction.phone ?? 'N/A'}' : ''}
${transaction.type == TransactionType.funding ? 'Payment Method: Paystack' : ''}
${transaction.description != null ? 'Description: ${transaction.description}' : ''}

━━━━━━━━━━━━━━━━━━━━━━
Thank you for using NairaFlow!
━━━━━━━━━━━━━━━━━━━━━━
''';
    
    Share.share(receiptText, subject: 'NairaFlow Transaction Receipt');
  }
}

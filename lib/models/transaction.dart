enum TransactionType { airtime, data, electricity, funding }

enum TransactionStatus { pending, success, failed }

enum NetworkProvider { mtn, airtel, glo, nmobile }

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String? phone;
  final NetworkProvider? network;
  final String? description;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.phone,
    this.network,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Map backend transaction types to Flutter enum
    String typeString = json['type'] ?? 'airtime';
    
    // Backend sends "credit" for wallet funding, map it to "funding"
    if (typeString == 'credit' || typeString == 'debit') {
      typeString = 'funding';
    }
    
    // Extract metadata if it exists (phone and network are nested)
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    
    return Transaction(
      // Backend uses _id instead of id
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == typeString,
        orElse: () => TransactionType.airtime,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      // Phone can be at root or in metadata
      phone: json['phone'] ?? metadata['phone'],
      // Network can be at root or in metadata, and may be uppercase
      network: _parseNetwork(json['network'] ?? metadata['network']),
      description: json['description'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper method to parse network from backend (handles uppercase values)
  static NetworkProvider? _parseNetwork(dynamic network) {
    if (network == null) return null;
    
    String networkString = network.toString().toLowerCase();
    
    // Handle 9mobile variations
    if (networkString == '9mobile' || networkString == '9mob') {
      networkString = 'nmobile';
    }
    
    return NetworkProvider.values.firstWhere(
      (e) => e.name == networkString,
      orElse: () => NetworkProvider.mtn,
    );
  }

  // Helper method to parse status from backend
  static TransactionStatus _parseStatus(dynamic status) {
    String statusString = (status ?? 'pending').toString().toLowerCase();
    
    // Backend sends "completed", map it to "success"
    if (statusString == 'completed') {
      statusString = 'success';
    }
    
    return TransactionStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => TransactionStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'phone': phone,
      'network': network?.name,
      'description': description,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? phone,
    NetworkProvider? network,
    String? description,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      phone: phone ?? this.phone,
      network: network ?? this.network,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get networkDisplayName {
    switch (network) {
      case NetworkProvider.mtn:
        return 'MTN';
      case NetworkProvider.airtel:
        return 'Airtel';
      case NetworkProvider.glo:
        return 'Glo';
      case NetworkProvider.nmobile:
        return '9mobile';
      default:
        return '';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.airtime:
        return 'Airtime';
      case TransactionType.data:
        return 'Data';
      case TransactionType.electricity:
        return 'Electricity';
      case TransactionType.funding:
        return 'Wallet Funding';
    }
  }
}
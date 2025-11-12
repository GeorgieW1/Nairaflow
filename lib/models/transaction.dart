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
    return Transaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.airtime,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      phone: json['phone'],
      network: json['network'] != null 
        ? NetworkProvider.values.firstWhere(
            (e) => e.name == json['network'],
            orElse: () => NetworkProvider.mtn,
          )
        : null,
      description: json['description'],
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
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
class DataPlan {
  final String variationCode;  // THIS IS THE KEY! (e.g. "mtn-1gb")
  final String name;            // e.g. "MTN 1GB Data"
  final double amount;          // e.g. 300.0
  final String? validity;       // e.g. "30 Days"

  const DataPlan({
    required this.variationCode,
    required this.name,
    required this.amount,
    this.validity,
  });

  factory DataPlan.fromJson(Map<String, dynamic> json) {
    final amountValue = json['variation_amount'] ?? json['fixedPrice'] ?? json['amount'];
    final parsedAmount = _parseAmount(amountValue);
    
    print('🔍 Parsing plan: ${json['name']}, amount value: $amountValue, parsed: $parsedAmount'); // Debug
    
    return DataPlan(
      variationCode: json['variation_code'] ?? json['variationCode'] ?? '',
      name: json['name'] ?? '',
      // VTpass API returns variation_amount or fixedPrice
      amount: parsedAmount,
      validity: json['validity'] ?? json['duration'],
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount is num) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'variation_code': variationCode,
      'name': name,
      'amount': amount,
      'validity': validity,
    };
  }
}

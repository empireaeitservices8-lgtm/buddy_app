/// Model representing an individual coin transaction (Credit / Debit)
class CoinTransaction {
  final String id;
  final String transactionType; // 'CREDIT' or 'DEBIT'
  final int amount;
  final int coins;
  final String description;
  final String status;
  final String date;
  final String createdAt;

  const CoinTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.coins,
    required this.description,
    required this.status,
    required this.date,
    required this.createdAt,
  });

  bool get isCredit => transactionType.toUpperCase() == 'CREDIT';

  String get formattedCoins => isCredit ? '+$coins Coins' : '-$coins Coins';

  String get formattedDate {
    if (date.isNotEmpty) {
      try {
        final parts = date.split(' ');
        if (parts.isNotEmpty) return parts[0];
      } catch (_) {}
      return date;
    }
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    return 'Recent';
  }

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? 'CREDIT',
      amount: json['amount'] is num
          ? (json['amount'] as num).toInt()
          : (int.tryParse(json['amount']?.toString() ?? '') ?? 0),
      coins: json['coins'] is num
          ? (json['coins'] as num).toInt()
          : (int.tryParse(json['coins']?.toString() ?? '') ?? 0),
      description: json['description']?.toString() ?? 'Coin Transaction',
      status: json['status']?.toString() ?? 'SUCCESS',
      date: json['date']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

/// Model encapsulating the full coins/history/ API response
class CoinHistoryResponse {
  final int currentBalance;
  final int totalCoinsPurchased;
  final int totalCoinsSpent;
  final int totalPurchases;
  final int totalTransactions;
  final List<CoinTransaction> purchases;
  final List<CoinTransaction> transactions;

  const CoinHistoryResponse({
    this.currentBalance = 0,
    this.totalCoinsPurchased = 0,
    this.totalCoinsSpent = 0,
    this.totalPurchases = 0,
    this.totalTransactions = 0,
    this.purchases = const [],
    this.transactions = const [],
  });

  factory CoinHistoryResponse.fromJson(Map<String, dynamic> json) {
    final map = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final purchasesList = <CoinTransaction>[];
    if (map['purchases'] is List) {
      for (final item in map['purchases'] as List) {
        if (item is Map<String, dynamic>) {
          purchasesList.add(CoinTransaction.fromJson(item));
        }
      }
    }

    final txList = <CoinTransaction>[];
    if (map['transactions'] is List) {
      for (final item in map['transactions'] as List) {
        if (item is Map<String, dynamic>) {
          txList.add(CoinTransaction.fromJson(item));
        }
      }
    }

    return CoinHistoryResponse(
      currentBalance: map['current_balance'] is num
          ? (map['current_balance'] as num).toInt()
          : (int.tryParse(map['current_balance']?.toString() ?? '') ?? 0),
      totalCoinsPurchased: map['total_coins_purchased'] is num
          ? (map['total_coins_purchased'] as num).toInt()
          : (int.tryParse(map['total_coins_purchased']?.toString() ?? '') ?? 0),
      totalCoinsSpent: map['total_coins_spent'] is num
          ? (map['total_coins_spent'] as num).toInt()
          : (int.tryParse(map['total_coins_spent']?.toString() ?? '') ?? 0),
      totalPurchases: map['total_purchases'] is num
          ? (map['total_purchases'] as num).toInt()
          : (int.tryParse(map['total_purchases']?.toString() ?? '') ?? 0),
      totalTransactions: map['total_transactions'] is num
          ? (map['total_transactions'] as num).toInt()
          : (int.tryParse(map['total_transactions']?.toString() ?? '') ?? 0),
      purchases: purchasesList,
      transactions: txList.isNotEmpty ? txList : purchasesList,
    );
  }
}

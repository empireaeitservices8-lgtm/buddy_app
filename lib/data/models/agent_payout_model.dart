class AgentPayoutModel {
  final bool success;
  final String? message;
  final List<AgentPayoutItem> data;
  final AgentPayoutSummary? summary;

  const AgentPayoutModel({
    required this.success,
    this.message,
    this.data = const [],
    this.summary,
  });

  factory AgentPayoutModel.fromJson(dynamic json) {
    if (json is List) {
      return AgentPayoutModel(
        success: true,
        data: json
            .whereType<Map<String, dynamic>>()
            .map((e) => AgentPayoutItem.fromJson(e))
            .toList(),
      );
    }

    if (json is Map<String, dynamic>) {
      final isSuccess = json['success'] == true ||
          json['status'] == 'success' ||
          !json.containsKey('error');

      List<AgentPayoutItem> items = [];
      final rawData = json['data'] ??
          json['payouts'] ??
          json['results'] ??
          json['history'] ??
          json['items'];

      if (rawData is List) {
        items = rawData
            .whereType<Map<String, dynamic>>()
            .map((e) => AgentPayoutItem.fromJson(e))
            .toList();
      } else if (rawData is Map<String, dynamic>) {
        // In case a single checkout item or summary is wrapped
        if (rawData.containsKey('payouts') && rawData['payouts'] is List) {
          items = (rawData['payouts'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => AgentPayoutItem.fromJson(e))
              .toList();
        } else {
          items = [AgentPayoutItem.fromJson(rawData)];
        }
      }

      return AgentPayoutModel(
        success: isSuccess,
        message: json['message']?.toString(),
        data: items,
        summary: json['summary'] is Map<String, dynamic>
            ? AgentPayoutSummary.fromJson(json['summary'] as Map<String, dynamic>)
            : null,
      );
    }

    return const AgentPayoutModel(success: false);
  }
}

class AgentPayoutSummary {
  final double totalPaidOut;
  final double pendingPayout;
  final int totalRequests;

  const AgentPayoutSummary({
    this.totalPaidOut = 0.0,
    this.pendingPayout = 0.0,
    this.totalRequests = 0,
  });

  factory AgentPayoutSummary.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v != null) return double.tryParse(v.toString()) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v != null) return int.tryParse(v.toString()) ?? 0;
      return 0;
    }

    return AgentPayoutSummary(
      totalPaidOut: parseDouble(json['total_paid_out'] ?? json['total_paid']),
      pendingPayout: parseDouble(json['pending_payout'] ?? json['pending_amount']),
      totalRequests: parseInt(json['total_requests'] ?? json['count']),
    );
  }
}

class AgentPayoutItem {
  final dynamic id;
  final dynamic agentId;
  final double amount;
  final int coins;
  final String status; // 'pending', 'processing', 'completed', 'failed', 'rejected'
  final String? payoutMethod; // 'upi', 'bank_transfer', etc.
  final String? upiId;
  final String? accountNumber;
  final String? ifscCode;
  final String? transactionId;
  final String? referenceId;
  final String? remarks;
  final DateTime? createdAt;
  final String? rawCreatedAt;

  const AgentPayoutItem({
    this.id,
    this.agentId,
    this.amount = 0.0,
    this.coins = 0,
    this.status = 'pending',
    this.payoutMethod,
    this.upiId,
    this.accountNumber,
    this.ifscCode,
    this.transactionId,
    this.referenceId,
    this.remarks,
    this.createdAt,
    this.rawCreatedAt,
  });

  factory AgentPayoutItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v != null) return double.tryParse(v.toString()) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v != null) return int.tryParse(v.toString()) ?? 0;
      return 0;
    }

    final rawDate = json['created_at'] ??
        json['createdAt'] ??
        json['requested_at'] ??
        json['date'] ??
        json['timestamp'];

    DateTime? parsedDate;
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString())?.toLocal();
    }

    final rawAmount = json['amount'] ??
        json['payout_amount'] ??
        json['inr_amount'] ??
        json['total_inr'] ??
        json['inr'];

    final rawCoins = json['coins'] ??
        json['coins_redeemed'] ??
        json['coin_amount'] ??
        json['coins_count'];

    return AgentPayoutItem(
      id: json['id'] ?? json['payout_id'] ?? json['pk'],
      agentId: json['agent_id'] ??
          json['agentId'] ??
          (json['agent'] is Map ? json['agent']['id'] : json['agent']),
      amount: parseDouble(rawAmount),
      coins: parseInt(rawCoins),
      status: (json['status']?.toString() ?? 'pending').toLowerCase().trim(),
      payoutMethod: json['payout_method']?.toString() ??
          json['payment_method']?.toString() ??
          json['method']?.toString(),
      upiId: json['upi_id']?.toString() ?? json['upiId']?.toString(),
      accountNumber: json['account_number']?.toString() ??
          json['bank_account']?.toString(),
      ifscCode: json['ifsc_code']?.toString() ?? json['ifsc']?.toString(),
      transactionId: json['transaction_id']?.toString() ??
          json['txn_id']?.toString() ??
          json['utr']?.toString(),
      referenceId: json['reference_id']?.toString() ??
          json['ref_id']?.toString(),
      remarks: json['remarks']?.toString() ??
          json['message']?.toString() ??
          json['description']?.toString(),
      createdAt: parsedDate,
      rawCreatedAt: rawDate?.toString(),
    );
  }

  String get formattedAmount {
    return amount % 1 == 0
        ? '₹${amount.toInt()}'
        : '₹${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (createdAt != null) {
      final d = createdAt!;
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24 && d.day == now.day) return '${diff.inHours}h ago';
      if (diff.inDays == 1 || (diff.inHours < 48 && d.day == now.subtract(const Duration(days: 1)).day)) {
        return 'Yesterday';
      }
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return rawCreatedAt ?? 'Recently';
  }

  bool get isCompleted =>
      status == 'completed' ||
      status == 'success' ||
      status == 'paid' ||
      status == 'settled';

  bool get isPending =>
      status == 'pending' ||
      status == 'requested' ||
      status == 'initiated' ||
      status == 'in_review';

  bool get isProcessing =>
      status == 'processing' ||
      status == 'in_progress' ||
      status == 'queued';

  bool get isFailed =>
      status == 'failed' ||
      status == 'rejected' ||
      status == 'cancelled' ||
      status == 'declined';
}

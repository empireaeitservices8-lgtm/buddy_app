/// Model representing the rating and reviews response from /api/agent/rating/?agent_id={id}
class AgentRatingData {
  final bool success;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingBreakdown;
  final List<AgentReviewItem> recentReviews;

  const AgentRatingData({
    this.success = true,
    this.averageRating = 5.0,
    this.totalReviews = 0,
    this.ratingBreakdown = const {},
    this.recentReviews = const [],
  });

  factory AgentRatingData.fromJson(Map<String, dynamic> json) {
    // Parse rating breakdown map { "1": 0, "2": 0, "3": 0, "4": 0, "5": 1 }
    final rawBreakdown = json['rating_breakdown'];
    final Map<int, int> breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, value) {
        final k = int.tryParse(key.toString()) ?? 0;
        final v = int.tryParse(value.toString()) ?? 0;
        if (k >= 1 && k <= 5) {
          breakdown[k] = v;
        }
      });
    }

    // Parse recent reviews list
    final rawReviews = json['recent_reviews'];
    List<AgentReviewItem> reviews = [];
    if (rawReviews is List) {
      for (final item in rawReviews) {
        if (item is Map<String, dynamic>) {
          reviews.add(AgentReviewItem.fromJson(item));
        } else if (item is Map) {
          reviews.add(AgentReviewItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final avgRating = json['average_rating'] is num
        ? (json['average_rating'] as num).toDouble()
        : (double.tryParse(json['average_rating']?.toString() ?? '') ??
            (json['rating'] is num
                ? (json['rating'] as num).toDouble()
                : 5.0));

    final totalRev = json['total_reviews'] is num
        ? (json['total_reviews'] as num).toInt()
        : (int.tryParse(json['total_reviews']?.toString() ?? '') ?? reviews.length);

    return AgentRatingData(
      success: json['success'] == true,
      averageRating: avgRating,
      totalReviews: totalRev,
      ratingBreakdown: breakdown,
      recentReviews: reviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'rating_breakdown': ratingBreakdown.map((k, v) => MapEntry(k.toString(), v)),
      'recent_reviews': recentReviews.map((r) => r.toJson()).toList(),
    };
  }

  /// Calculates the percentage of reviews for a given star (1 to 5)
  double percentageForStar(int star) {
    if (totalReviews <= 0) return 0.0;
    final count = ratingBreakdown[star] ?? 0;
    return (count / totalReviews).clamp(0.0, 1.0);
  }
}

/// Represents an individual review left by a caller for an agent
class AgentReviewItem {
  final int id;
  final int callId;
  final int rating;
  final String feedback;
  final String callerName;
  final String createdAt;

  const AgentReviewItem({
    required this.id,
    required this.callId,
    required this.rating,
    required this.feedback,
    required this.callerName,
    required this.createdAt,
  });

  factory AgentReviewItem.fromJson(Map<String, dynamic> json) {
    return AgentReviewItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      callId: json['call_id'] is int
          ? json['call_id'] as int
          : int.tryParse(json['call_id']?.toString() ?? '') ?? 0,
      rating: json['rating'] is int
          ? json['rating'] as int
          : (int.tryParse(json['rating']?.toString() ?? '') ??
              (json['rating'] is num ? (json['rating'] as num).toInt() : 5)),
      feedback: json['feedback']?.toString() ?? '',
      callerName: json['caller_name']?.toString() ??
          json['caller']?.toString() ??
          json['user_name']?.toString() ??
          'Anonymous Caller',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_id': callId,
      'rating': rating,
      'feedback': feedback,
      'caller_name': callerName,
      'created_at': createdAt,
    };
  }

  /// Formatted date string for display
  String get formattedDate {
    if (createdAt.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {
      return createdAt.split('T').first;
    }
  }
}

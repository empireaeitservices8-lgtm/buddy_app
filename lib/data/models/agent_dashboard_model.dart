class AgentDashboardModel {
  final bool success;
  final AgentDashboardData? data;
  final String? message;

  const AgentDashboardModel({
    required this.success,
    this.data,
    this.message,
  });

  factory AgentDashboardModel.fromJson(Map<String, dynamic> json) {
    return AgentDashboardModel(
      success: json['success'] == true,
      data: json['data'] is Map<String, dynamic>
          ? AgentDashboardData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
    );
  }
}

class AgentDashboardData {
  final AgentProfileModel? profile;
  final AgentDutyModel? duty;
  final AgentEarningsModel? earnings;
  final AgentCallsModel? calls;
  final List<AgentSessionModel> recentSessions;

  const AgentDashboardData({
    this.profile,
    this.duty,
    this.earnings,
    this.calls,
    this.recentSessions = const [],
  });

  factory AgentDashboardData.fromJson(Map<String, dynamic> json) {
    var sessions = <AgentSessionModel>[];
    final rawRecent = json['recent_sessions'] ?? json['recentSessions'] ?? json['sessions'];
    if (rawRecent is List) {
      for (final item in rawRecent) {
        if (item is Map) {
          sessions.add(AgentSessionModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return AgentDashboardData(
      profile: json['profile'] is Map<String, dynamic>
          ? AgentProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      duty: json['duty'] is Map<String, dynamic>
          ? AgentDutyModel.fromJson(json['duty'] as Map<String, dynamic>)
          : null,
      earnings: json['earnings'] is Map<String, dynamic>
          ? AgentEarningsModel.fromJson(json['earnings'] as Map<String, dynamic>)
          : null,
      calls: json['calls'] is Map<String, dynamic>
          ? AgentCallsModel.fromJson(json['calls'] as Map<String, dynamic>)
          : null,
      recentSessions: sessions,
    );
  }
}

class AgentProfileModel {
  final int? id;
  final String? agentId;
  final int? userId;
  final String? name;
  final String? displayName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? profession;
  final String? professionName;
  final String? bio;
  final int ratePerSecond;
  final double rating;
  final int totalCalls;
  final int totalEarnedCoins;
  final bool isOnDuty;
  final bool isBusy;
  final bool isAvailable;
  final bool isVerified;
  final String? avatar;
  final String? profilePicture;
  final String? profilePictureUrl;
  final String? gender;
  final String? language;
  final List<String> interests;
  final String? createdAt;
  final String? updatedAt;

  const AgentProfileModel({
    this.id,
    this.agentId,
    this.userId,
    this.name,
    this.displayName,
    this.username,
    this.email,
    this.phoneNumber,
    this.profession,
    this.professionName,
    this.bio,
    this.ratePerSecond = 5,
    this.rating = 5.0,
    this.totalCalls = 0,
    this.totalEarnedCoins = 0,
    this.isOnDuty = false,
    this.isBusy = false,
    this.isAvailable = true,
    this.isVerified = false,
    this.avatar,
    this.profilePicture,
    this.profilePictureUrl,
    this.gender,
    this.language,
    this.interests = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AgentProfileModel.fromJson(Map<String, dynamic> json) {
    final interestsRaw = json['interests'];
    List<String> parsedInterests = [];
    if (interestsRaw is List) {
      parsedInterests = interestsRaw
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final categoryName = json['category'] is Map
        ? (json['category'] as Map)['name']?.toString()
        : null;

    final resolvedProfessionName = json['profession_name']?.toString() ??
        categoryName ??
        json['profession']?.toString() ??
        'General';

    final rawAgentId = json['agent_id'] ??
        (json['agent'] is Map ? (json['agent'] as Map)['id'] : json['agent']) ??
        json['listener_id'] ??
        json['agent_profile_id'] ??
        json['profile_id'];

    final rawUserId = json['user_id'] ??
        (json['user'] is Map ? (json['user'] as Map)['id'] : json['user']);

    final parsedId = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '') ??
            (rawAgentId is int
                ? rawAgentId
                : int.tryParse(rawAgentId?.toString() ?? '')));

    return AgentProfileModel(
      id: parsedId,
      agentId: rawAgentId?.toString() ?? json['id']?.toString(),
      userId: rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId?.toString() ?? ''),
      name: json['name']?.toString(),
      displayName: json['display_name']?.toString() ?? json['name']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      profession: json['profession']?.toString() ?? resolvedProfessionName,
      professionName: resolvedProfessionName,
      bio: json['bio']?.toString() ?? '',
      ratePerSecond: (() {
        final parsed = json['rate_per_second'] is num
            ? (json['rate_per_second'] as num).toInt()
            : (int.tryParse(json['rate_per_second']?.toString() ?? '') ?? 5);
        return (parsed <= 0 || parsed == 3) ? 5 : parsed;
      })(),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : (double.tryParse(json['rating']?.toString() ?? '') ?? 5.0),
      totalCalls: json['total_calls'] is num
          ? (json['total_calls'] as num).toInt()
          : (int.tryParse(json['total_calls']?.toString() ?? '') ?? 0),
      totalEarnedCoins: json['total_earned_coins'] is num
          ? (json['total_earned_coins'] as num).toInt()
          : (int.tryParse(json['total_earned_coins']?.toString() ?? '') ?? 0),
      isOnDuty: json['is_on_duty'] == true,
      isBusy: json['is_busy'] == true,
      isAvailable: json['is_available'] == true || json['is_available'] == null,
      isVerified: json['is_verified'] == true,
      avatar: json['avatar']?.toString() ?? json['profile_picture_url']?.toString() ?? json['profile_picture']?.toString(),
      profilePicture: json['profile_picture']?.toString() ?? json['profile_picture_url']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString() ?? json['profile_picture']?.toString(),
      gender: json['gender']?.toString(),
      language: json['language']?.toString(),
      interests: parsedInterests,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class AgentDutyModel {
  final bool isOnDuty;
  final int activeSessionSeconds;
  final int todayDutySeconds;

  const AgentDutyModel({
    this.isOnDuty = false,
    this.activeSessionSeconds = 0,
    this.todayDutySeconds = 0,
  });

  factory AgentDutyModel.fromJson(Map<String, dynamic> json) {
    return AgentDutyModel(
      isOnDuty: json['is_on_duty'] == true,
      activeSessionSeconds: json['active_session_seconds'] is num
          ? (json['active_session_seconds'] as num).toInt()
          : (int.tryParse(json['active_session_seconds']?.toString() ?? '') ?? 0),
      todayDutySeconds: json['today_duty_seconds'] is num
          ? (json['today_duty_seconds'] as num).toInt()
          : (int.tryParse(json['today_duty_seconds']?.toString() ?? '') ?? 0),
    );
  }

  String get formattedDutyTime {
    final seconds = todayDutySeconds > 0 ? todayDutySeconds : activeSessionSeconds;
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class AgentEarningsModel {
  final int todayCoins;
  final int lifetimeCoins;
  final int walletBalance;

  const AgentEarningsModel({
    this.todayCoins = 0,
    this.lifetimeCoins = 0,
    this.walletBalance = 0,
  });

  factory AgentEarningsModel.fromJson(Map<String, dynamic> json) {
    return AgentEarningsModel(
      todayCoins: json['today_coins'] is num
          ? (json['today_coins'] as num).toInt()
          : (int.tryParse(json['today_coins']?.toString() ?? '') ?? 0),
      lifetimeCoins: json['lifetime_coins'] is num
          ? (json['lifetime_coins'] as num).toInt()
          : (int.tryParse(json['lifetime_coins']?.toString() ?? '') ?? 0),
      walletBalance: json['wallet_balance'] is num
          ? (json['wallet_balance'] as num).toInt()
          : (int.tryParse(json['wallet_balance']?.toString() ?? '') ?? 0),
    );
  }
}

class AgentCallsModel {
  final int todayCount;
  final int lifetimeCount;

  const AgentCallsModel({
    this.todayCount = 0,
    this.lifetimeCount = 0,
  });

  factory AgentCallsModel.fromJson(Map<String, dynamic> json) {
    return AgentCallsModel(
      todayCount: json['today_count'] is num
          ? (json['today_count'] as num).toInt()
          : (int.tryParse(json['today_count']?.toString() ?? '') ?? 0),
      lifetimeCount: json['lifetime_count'] is num
          ? (json['lifetime_count'] as num).toInt()
          : (int.tryParse(json['lifetime_count']?.toString() ?? '') ?? 0),
    );
  }
}

class AgentSessionModel {
  final String? id;
  final String? callerName;
  final String? callType;
  final String? duration;
  final int coinsEarned;
  final String? timeAgo;

  const AgentSessionModel({
    this.id,
    this.callerName,
    this.callType,
    this.duration,
    this.coinsEarned = 0,
    this.timeAgo,
  });

  factory AgentSessionModel.fromJson(Map<String, dynamic> json) {
    // 1. Duration Formatting
    String formattedDuration = '0s';
    final rawDurationSeconds = json['duration_seconds'] ?? json['durationSeconds'] ?? json['seconds'];
    if (rawDurationSeconds != null) {
      final sec = (rawDurationSeconds is num)
          ? rawDurationSeconds.toInt()
          : (int.tryParse(rawDurationSeconds.toString()) ?? 0);
      if (sec < 60) {
        formattedDuration = '${sec}s';
      } else {
        final m = sec ~/ 60;
        final s = sec % 60;
        formattedDuration = s > 0 ? '${m}m ${s}s' : '${m}m';
      }
    } else if (json['duration'] != null && json['duration'].toString().trim().isNotEmpty) {
      formattedDuration = json['duration'].toString().trim();
    }

    // 2. Time Ago Formatting
    final rawTimeStr = json['time_ago'] ??
        json['ended_at'] ??
        json['endedAt'] ??
        json['created_at'] ??
        json['createdAt'] ??
        json['timestamp'] ??
        json['started_at'];

    String formattedTimeAgo = 'Just now';
    if (rawTimeStr != null) {
      final str = rawTimeStr.toString().trim();
      final parsedDate = DateTime.tryParse(str)?.toLocal();
      if (parsedDate != null) {
        final now = DateTime.now();
        final diff = now.difference(parsedDate);
        if (diff.isNegative || diff.inSeconds < 60) {
          formattedTimeAgo = 'Just now';
        } else if (diff.inMinutes < 60) {
          formattedTimeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24 && parsedDate.day == now.day) {
          formattedTimeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays == 1 || (diff.inHours < 48 && parsedDate.day == now.subtract(const Duration(days: 1)).day)) {
          formattedTimeAgo = 'Yesterday';
        } else if (diff.inDays < 7) {
          formattedTimeAgo = '${diff.inDays}d ago';
        } else {
          formattedTimeAgo = '${parsedDate.day}/${parsedDate.month}';
        }
      } else {
        formattedTimeAgo = str.isNotEmpty ? str : 'Recently';
      }
    }

    // 3. Call Type / Category
    String callType = 'Voice Call 📞';
    if (json['category'] != null && json['category'].toString().trim().isNotEmpty) {
      final cat = json['category'].toString().trim();
      callType = cat.toLowerCase().contains('call') ? cat : '$cat Call 📞';
    } else if (json['call_type'] != null && json['call_type'].toString().trim().isNotEmpty) {
      callType = json['call_type'].toString().trim();
    }

    // 4. Coins Earned
    final coins = json['coins_earned'] is num
        ? (json['coins_earned'] as num).toInt()
        : (int.tryParse(json['coins_earned']?.toString() ??
                json['coins']?.toString() ??
                '') ??
            0);

    // 5. Caller Name
    final caller = json['caller_name']?.toString() ??
        json['client_name']?.toString() ??
        json['user']?.toString() ??
        json['caller']?.toString() ??
        json['name']?.toString() ??
        'Caller';

    // 6. ID
    final id = json['call_id']?.toString() ??
        json['id']?.toString() ??
        json['session_id']?.toString();

    return AgentSessionModel(
      id: id,
      callerName: caller,
      callType: callType,
      duration: formattedDuration,
      coinsEarned: coins,
      timeAgo: formattedTimeAgo,
    );
  }
}

import 'package:flutter/material.dart';

class ProfessionCategory {
  final String id;
  final String title;
  final String subTitle;
  final int matchCount;
  final String emoji;
  final Color bgColor;
  final IconData? iconData;
  final List<MatchProfile> matches;

  const ProfessionCategory({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.matchCount,
    required this.emoji,
    required this.bgColor,
    this.iconData,
    this.matches = const [],
  });

  factory ProfessionCategory.fromJson(
    Map<String, dynamic> json, [
    int index = 0,
  ]) {
    final id = json['id']?.toString() ?? '';
    final name =
        (json['name'] ??
                json['title'] ??
                json['category'] ??
                json['category_name'] ??
                json['profession'])
            ?.toString() ??
        '';
    final description =
        json['tagline']?.toString() ??
        json['description_text']?.toString() ??
        (json['description'] is List
            ? (json['description'] as List).join(', ')
            : (json['description']?.toString() ?? ''));

    final matchCount = json['matches_count'] is int
        ? json['matches_count'] as int
        : (json['count'] is int ? json['count'] as int : 0);

    String emoji = (json['emoji'] != null && json['emoji'].toString().trim().isNotEmpty)
        ? json['emoji'].toString().trim()
        : '❤️';
    final n = name.toLowerCase();
    if (json['emoji'] == null || json['emoji'].toString().trim().isEmpty) {
      if (n.contains('just talk') ||
          (n.contains('talk') &&
              !n.contains('student') &&
              !n.contains('career'))) {
        emoji = '❤️';
      } else if (n.contains('friendly') || n.contains('conversation')) {
        emoji = '😊';
      } else if (n.contains('advice') || n.contains('perspective')) {
        emoji = '🧠';
      } else if (n.contains('career') ||
          n.contains('profession') ||
          n.contains('job')) {
        emoji = '💼';
      } else if (n.contains('travel') ||
          n.contains('place') ||
          n.contains('trip')) {
        emoji = '🌍';
      } else if (n.contains('elder') ||
          n.contains('senior') ||
          n.contains('companion') && !n.contains('student')) {
        emoji = '👴';
      } else if (n.contains('student') ||
          n.contains('college') ||
          n.contains('study') ||
          n.contains('studies')) {
        emoji = '🎓';
      } else if (n.contains('language') ||
          n.contains('english') ||
          n.contains('practice')) {
        emoji = '🗣️';
      } else if (n.contains('casual') || n.contains('chat')) {
        emoji = '☕';
      } else if (n.contains('teacher') || n.contains('educat')) {
        emoji = '📚';
      } else if (n.contains('doctor') || n.contains('medic')) {
        emoji = '🩺';
      } else if (n.contains('engineer')) {
        emoji = '⚙️';
      } else if (n.contains('software') || n.contains('tech')) {
        emoji = '💻';
      } else if (n.contains('artist') || n.contains('music')) {
        emoji = '🎨';
      }
    }

    const bgColors = [
      Color(0xFFFFB7D5), // Pink (Just talk)
      Color(0xFFFFF7CE), // Pale Yellow (Friendly Conversation)
      Color(0xFFB8C4FE), // Lavender (Advice)
      Color(0xFFD6F887), // Lime (Career)
      Color(0xFFD0E8FF), // Sky blue (Travel)
      Color(0xFFFFE5D9), // Peach (Elder)
      Color(0xFFE8D7FF), // Purple (Student)
      Color(0xFFD8F3DC), // Mint (Language)
      Color(0xFFFFF1DB), // Cream (Casual)
    ];
    final bgColor = bgColors[index % bgColors.length];

    final parsedMatches = <MatchProfile>[];
    if (json['matches'] is List) {
      final matchesList = json['matches'] as List;
      for (int i = 0; i < matchesList.length; i++) {
        if (matchesList[i] is Map) {
          parsedMatches.add(
            MatchProfile.fromJson(matchesList[i] as Map<String, dynamic>, i),
          );
        }
      }
    }

    return ProfessionCategory(
      id: id,
      title: name,
      subTitle: description,
      matchCount: matchCount,
      emoji: emoji,
      bgColor: bgColor,
      matches: parsedMatches,
    );
  }

  ProfessionCategory copyWith({
    String? id,
    String? title,
    String? subTitle,
    int? matchCount,
    String? emoji,
    Color? bgColor,
    IconData? iconData,
    List<MatchProfile>? matches,
  }) {
    return ProfessionCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      matchCount: matchCount ?? this.matchCount,
      emoji: emoji ?? this.emoji,
      bgColor: bgColor ?? this.bgColor,
      iconData: iconData ?? this.iconData,
      matches: matches ?? this.matches,
    );
  }
}

class MatchProfile {
  final String id;
  final String? userId;
  final String name;
  final int age;
  final String location;
  final String profession;
  final String professionCategory;
  final String? professionId;
  final String? categoryDescription;
  final String bio;
  final int rateCoinsPerSec;
  final bool isOnline;
  final Color cardColor;
  final Color avatarColor;
  final String? avatarUrl;
  final List<String> conversationCategoryIds;
  final List<String> conversationCategoryNames;
  final List<String> interests;
  final double rating;
  final String? gender;

  const MatchProfile({
    required this.id,
    this.userId,
    required this.name,
    required this.age,
    required this.location,
    required this.profession,
    required this.professionCategory,
    this.professionId,
    this.categoryDescription,
    required this.bio,
    this.rateCoinsPerSec = 5,
    this.isOnline = true,
    required this.cardColor,
    required this.avatarColor,
    this.avatarUrl,
    this.conversationCategoryIds = const [],
    this.conversationCategoryNames = const [],
    this.interests = const [],
    this.rating = 5.0,
    this.gender,
  });

  bool get isFemale {
    final g = (gender ?? '').trim().toLowerCase();
    if (g == 'woman' ||
        g == 'female' ||
        g == 'girl' ||
        g == 'lady' ||
        g == 'f' ||
        g == 'w') {
      return true;
    }
    if (g == 'man' ||
        g == 'male' ||
        g == 'boy' ||
        g == 'guy' ||
        g == 'm') {
      return false;
    }
    final n = name.trim().toLowerCase();
    return n.endsWith('a') ||
        n.endsWith('i') ||
        n.endsWith('e') ||
        n.contains('girl') ||
        (id.hashCode.abs() % 2 == 0);
  }

  bool get isMale => !isFemale;

  bool get isNonBinary => false;

  IconData get genderIcon =>
      isFemale ? Icons.female_rounded : Icons.male_rounded;

  Color get genderColor =>
      isFemale ? const Color(0xFFD81B60) : const Color(0xFF0284C7);

  String get genderImageAsset =>
      isFemale ? 'assets/images/Girl.png' : 'assets/images/Boy.png';

  factory MatchProfile.fromJson(Map<String, dynamic> json, [int index = 0]) {
    final profObj = json['profession'] is Map
        ? json['profession'] as Map<String, dynamic>
        : null;
    final catObj = json['category'] is Map
        ? json['category'] as Map<String, dynamic>
        : null;

    final rawProfStr = (json['profession_name'] ??
            profObj?['name'] ??
            catObj?['name'] ??
            json['profession'] ??
            json['conversation_category'] ??
            json['category'])
        ?.toString()
        .trim();

    final professionName =
        (rawProfStr != null && rawProfStr.isNotEmpty && rawProfStr.toLowerCase() != 'null')
            ? rawProfStr
            : 'General';

    final rawCatStr = (json['profession_name'] ??
            json['profession_category'] ??
            json['conversation_category'] ??
            catObj?['name'] ??
            profObj?['name'] ??
            catObj?['id'] ??
            json['category_id'] ??
            json['category'])
        ?.toString()
        .trim();

    final categoryName =
        (rawCatStr != null && rawCatStr.isNotEmpty && rawCatStr.toLowerCase() != 'null')
            ? rawCatStr
            : professionName;

    final categoryDescription = catObj?['description'] is List
        ? (catObj!['description'] as List).join(', ')
        : (profObj?['description'] is List
              ? (profObj!['description'] as List).join(', ')
              : (catObj?['description']?.toString() ??
                    profObj?['description']?.toString()));

    final professionId =
        profObj?['id']?.toString() ?? catObj?['id']?.toString();

    final rawBio = json['bio']?.toString() ?? '';
    final interestsRaw = json['interests'];
    final interestsList = <String>[];
    if (interestsRaw is List) {
      for (final item in interestsRaw) {
        if (item is Map) {
          final name = (item['name'] ?? item['title'] ?? item['label'])?.toString();
          if (name != null && name.trim().isNotEmpty) interestsList.add(name.trim());
        } else if (item != null) {
          final str = item.toString().trim();
          if (str.isNotEmpty && str.toLowerCase() != 'null') interestsList.add(str);
        }
      }
    }

    // Parse conversation categories from discover API
    final convCatIds = <String>[];
    final convCatNames = <String>[];
    if (json['conversation_categories'] is List) {
      for (final item in json['conversation_categories'] as List) {
        if (item is Map) {
          final cid = item['id']?.toString();
          final cname = item['name']?.toString();
          if (cid != null && cid.isNotEmpty) convCatIds.add(cid);
          if (cname != null && cname.isNotEmpty) convCatNames.add(cname);
        } else if (item != null) {
          final str = item.toString();
          convCatIds.add(str);
          convCatNames.add(str);
        }
      }
    }

    if (interestsList.isEmpty && convCatNames.isNotEmpty) {
      interestsList.addAll(convCatNames);
    }
    if (interestsList.isEmpty && json['conversation_category'] != null) {
      final str = json['conversation_category'].toString().trim();
      if (str.isNotEmpty && str.toLowerCase() != 'null') interestsList.add(str);
    }

    final effectiveBio = rawBio.isNotEmpty
        ? rawBio
        : (interestsList.isNotEmpty
              ? interestsList.join(" • ")
              : 'Available for calls ✨');

    final language = json['language']?.toString();
    final location =
        json['location']?.toString() ??
        (language != null && language.isNotEmpty
            ? 'Language: $language'
            : 'Online');

    const cardColors = [
      Color(0xFFB8C4FE),
      Color(0xFFFFF7CE),
      Color(0xFFFFB7D5),
      Color(0xFFD6F887),
    ];
    const avatarColors = [
      Color(0xFF8392F8),
      Color(0xFFF0C850),
      Color(0xFFFF8DA1),
      Color(0xFFAEC4FE),
    ];

    final isOnline =
        json['is_online'] == true ||
        json['is_available'] == true ||
        json['is_on_duty'] == true;

    final parsedRate = json['rate_per_second'] is int
        ? json['rate_per_second'] as int
        : (json['rate_per_second'] is num
              ? (json['rate_per_second'] as num).toInt()
              : (int.tryParse(json['rate_per_second']?.toString() ?? '') ?? 5));
    final rate = (parsedRate <= 0 || parsedRate == 3) ? 5 : parsedRate;

    final rawRating = json['rating'];
    final ratingVal = rawRating is num
        ? rawRating.toDouble()
        : (double.tryParse(rawRating?.toString() ?? '') ?? 5.0);

    final rawGender = json['gender']?.toString() ??
        json['sex']?.toString() ??
        (json['user'] is Map ? json['user']['gender']?.toString() : null) ??
        (json['profile'] is Map ? json['profile']['gender']?.toString() : null);

    final rawUserId = (json['user_id'] ??
        json['userId'] ??
        json['agent_id'] ??
        json['agent_user_id'] ??
        (json['user'] is Map ? json['user']['id'] : null))?.toString();
    final effectiveId = rawUserId ?? json['id']?.toString() ?? '';

    return MatchProfile(
      id: effectiveId,
      userId: rawUserId ?? json['id']?.toString(),
      name:
          json['name']?.toString() ??
          json['username']?.toString() ??
          'Listener',
      age: json['age'] is int
          ? json['age'] as int
          : (int.tryParse(json['age']?.toString() ?? '') ?? 25),
      location: location,
      profession: professionName,
      professionCategory: categoryName,
      professionId: professionId,
      categoryDescription: categoryDescription,
      bio: effectiveBio,
      rateCoinsPerSec: rate,
      isOnline: isOnline,
      avatarUrl: json['profile_picture']?.toString(),
      cardColor: cardColors[index % cardColors.length],
      avatarColor: avatarColors[index % avatarColors.length],
      conversationCategoryIds: convCatIds,
      conversationCategoryNames: convCatNames,
      interests: interestsList,
      rating: ratingVal,
      gender: rawGender,
    );
  }

  bool matchesCategory(String? categoryId, [String? categoryTitle]) {
    final catIdLower = (categoryId ?? '').trim().toLowerCase();
    final catTitleLower = (categoryTitle ?? '').trim().toLowerCase();

    // 1. Check conversationCategoryIds (e.g. '1', '2', '3')
    if (catIdLower.isNotEmpty) {
      if (conversationCategoryIds.any((id) => id.toLowerCase() == catIdLower)) {
        return true;
      }
    }

    // 2. Check conversationCategoryNames (e.g. 'Just Talk', 'Friendly Conversation', 'Advice')
    if (catTitleLower.isNotEmpty) {
      if (conversationCategoryNames.any((n) {
        final nl = n.toLowerCase();
        return nl == catTitleLower ||
            nl.contains(catTitleLower) ||
            catTitleLower.contains(nl);
      })) {
        return true;
      }
    }

    if (catIdLower.isNotEmpty) {
      if (conversationCategoryNames.any((n) {
        final nl = n.toLowerCase();
        return nl == catIdLower ||
            nl.contains(catIdLower) ||
            catTitleLower.contains(nl);
      })) {
        return true;
      }
    }

    // 3. Check professionCategory, profession, interests, bio
    final pCat = professionCategory.toLowerCase();
    final prof = profession.toLowerCase();

    for (final q in [catIdLower, catTitleLower]) {
      if (q.isEmpty) continue;
      if (pCat == q || pCat.contains(q) || q.contains(pCat)) return true;
      if (prof == q || prof.contains(q) || q.contains(prof)) return true;
      if (interests.any((i) => i.toLowerCase().contains(q) || q.contains(i.toLowerCase()))) return true;
    }

    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'location': location,
      'profession': profession,
      'profession_category': professionCategory,
      'bio': bio,
      'rate_per_second': rateCoinsPerSec,
      'is_online': isOnline,
      'profile_picture': avatarUrl,
      'conversation_categories': conversationCategoryIds,
      'interests': interests,
      'rating': rating,
      'gender': gender,
    };
  }
}

class CallLogItem {
  final String id;
  final String name;
  final String profession;
  final String professionEmoji;
  final String timeAgo;
  final String callType; // "Incoming", "Outgoing", "Missed"
  final String duration;
  final String status;
  final Color avatarColor;
  final MatchProfile? matchProfile;

  const CallLogItem({
    required this.id,
    required this.name,
    required this.profession,
    required this.professionEmoji,
    required this.timeAgo,
    required this.callType,
    required this.duration,
    this.status = '',
    this.avatarColor = const Color(0xFFAEC4FE),
    this.matchProfile,
  });

  factory CallLogItem.fromJson(Map<String, dynamic> json) {
    final otherUser = json['other_user'] is Map
        ? json['other_user'] as Map<String, dynamic>
        : null;
    final agent = json['agent'] is Map
        ? json['agent'] as Map<String, dynamic>
        : null;
    final caller = json['caller'] is Map
        ? json['caller'] as Map<String, dynamic>
        : null;

    final name =
        otherUser?['name']?.toString() ??
        agent?['name']?.toString() ??
        json['receiver_name']?.toString() ??
        caller?['name']?.toString() ??
        json['caller_name']?.toString() ??
        'Listener';

    final category =
        json['category']?.toString() ??
        otherUser?['role']?.toString() ??
        agent?['role']?.toString() ??
        'Doctor';

    String emoji = '🎧';
    final catLower = category.toLowerCase();
    if (catLower.contains('doctor') || catLower.contains('medic')) {
      emoji = '🩺';
    } else if (catLower.contains('engineer') ||
        catLower.contains('tech') ||
        catLower.contains('code')) {
      emoji = '💻';
    } else if (catLower.contains('design') || catLower.contains('art')) {
      emoji = '🎨';
    } else if (catLower.contains('law')) {
      emoji = '⚖️';
    } else if (catLower.contains('business') || catLower.contains('startup')) {
      emoji = '💼';
    } else if (catLower.contains('fit') || catLower.contains('gym')) {
      emoji = '🏋️';
    }

    final durationFormatted =
        json['duration_formatted']?.toString() ??
        _formatDurationSeconds(
          json['duration_seconds'] is int
              ? json['duration_seconds'] as int
              : (json['duration'] is int ? json['duration'] as int : 0),
        );

    final isIncoming = json['is_incoming'] == true;
    final status = json['status']?.toString().toUpperCase();
    final callType = status == 'MISSED'
        ? 'Missed'
        : (isIncoming ? 'Incoming' : 'Outgoing');

    final timeAgo = _formatTimeAgo(
      json['started_at']?.toString() ??
          json['start_time']?.toString() ??
          json['created_at']?.toString(),
    );

    const avatarColors = [
      Color(0xFFAEC4FE),
      Color(0xFFFFB7D5),
      Color(0xFFFFF7CE),
      Color(0xFFD6F887),
    ];
    final rawId = json['id'] is int
        ? json['id'] as int
        : (int.tryParse(json['id']?.toString() ?? '') ?? 0);
    final colorIndex = rawId.abs() % avatarColors.length;

    return CallLogItem(
      id: json['id']?.toString() ?? '',
      name: name,
      profession: category,
      professionEmoji: emoji,
      timeAgo: timeAgo,
      callType: callType,
      duration: durationFormatted,
      status: status ?? '',
      avatarColor: avatarColors[colorIndex],
      matchProfile: MatchProfile(
        id:
            (otherUser?['id'] ??
                    agent?['id'] ??
                    json['receiver_id'] ??
                    json['id'])
                ?.toString() ??
            '',
        name: name,
        age: 25,
        location: 'Available',
        profession: category,
        professionCategory: catLower,
        bio: 'Verified listener on Gabby Talk',
        cardColor: avatarColors[colorIndex],
        avatarColor: avatarColors[colorIndex],
        gender: otherUser?['gender']?.toString() ??
            agent?['gender']?.toString() ??
            caller?['gender']?.toString() ??
            json['gender']?.toString(),
      ),
    );
  }

  static String _formatDurationSeconds(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _formatTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recently';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} min ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return 'Recently';
    }
  }
}

enum Gender {
  woman,
  man,
  nonBinary;

  String get displayName {
    switch (this) {
      case Gender.woman:
        return 'Woman';
      case Gender.man:
        return 'Man';
      case Gender.nonBinary:
        return 'Non-Binary';
    }
  }

  static Gender fromString(String? value) {
    if (value == null) return Gender.woman;
    switch (value.toLowerCase()) {
      case 'man':
      case 'male':
        return Gender.man;
      case 'non_binary':
      case 'non-binary':
      case 'other':
        return Gender.nonBinary;
      case 'woman':
      case 'female':
      default:
        return Gender.woman;
    }
  }

  String toJson() {
    switch (this) {
      case Gender.woman:
        return 'woman';
      case Gender.man:
        return 'man';
      case Gender.nonBinary:
        return 'non_binary';
    }
  }
}

/// Domain model representing a user profile with JSON serialization
class UserProfile {
  final String? id;
  final String? userId;
  final String phoneNumber;
  final String countryCode;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? bio;
  final String? profession;
  final String? location;
  final String? language;
  final int? age;
  final Gender? gender;
  final String? avatarUrl;
  final List<String> interests;
  final int voiceCallsCount;
  final double rating;
  final bool isOnline;
  final bool profileVisibleInFeed;
  final bool ghostCallingMode;
  final bool isAgent;
  final String? agentId;
  final String? role;

  const UserProfile({
    this.id,
    this.userId,
    this.phoneNumber = '',
    this.countryCode = '+1',
    this.firstName = '',
    this.lastName,
    this.email,
    this.bio,
    this.profession,
    this.location,
    this.language,
    this.age,
    this.gender = Gender.woman,
    this.avatarUrl,
    this.interests = const [],
    this.voiceCallsCount = 0,
    this.rating = 5.0,
    this.isOnline = false,
    this.profileVisibleInFeed = true,
    this.ghostCallingMode = false,
    this.isAgent = false,
    this.agentId,
    this.role,
  });

  String get fullPhoneNumber => phoneNumber.startsWith('+') ? phoneNumber : '$countryCode $phoneNumber';
  String get fullName => lastName != null && lastName!.isNotEmpty ? '$firstName $lastName' : firstName;

  /// Factory constructor to parse JSON maps from API responses (supports direct and wrapped envelopes)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final map = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : (json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : (json['user'] is Map<String, dynamic>
                ? json['user'] as Map<String, dynamic>
                : json));

    final rawName = map['display_name']?.toString() ??
        map['name']?.toString() ??
        map['first_name']?.toString() ??
        map['username']?.toString() ??
        map['listener_id']?.toString() ??
        '';
    final nameParts = rawName.trim().split(' ');
    final fName = map['first_name']?.toString() ??
        map['name']?.toString() ??
        map['display_name']?.toString() ??
        (nameParts.isNotEmpty ? nameParts.first : '');
    final lName = map['last_name']?.toString() ??
        (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null);

    final roleUpper = (map['role'] ?? json['role'])?.toString().toUpperCase();
    final isAgentUser = map['is_agent'] == true ||
        json['is_agent'] == true ||
        roleUpper == 'AGENT' ||
        roleUpper == 'LISTENER';

    return UserProfile(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? map['id']?.toString(),
      phoneNumber: map['phone_number']?.toString() ?? map['phone']?.toString() ?? '',
      countryCode: map['country_code']?.toString() ?? '+1',
      firstName: fName.isNotEmpty ? fName : rawName,
      lastName: lName,
      email: map['email']?.toString(),
      bio: map['bio']?.toString(),
      profession: map['profession_name']?.toString() ??
          map['profession']?.toString() ??
          map['conversation_category']?.toString(),
      location: map['location']?.toString(),
      language: map['language']?.toString(),
      age: map['age'] is int
          ? map['age'] as int
          : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      gender: Gender.fromString(map['gender']?.toString()),
      avatarUrl: map['profile_picture']?.toString() ??
          map['profile_picture_url']?.toString() ??
          map['avatar_url']?.toString() ??
          map['avatar']?.toString() ??
          map['profile_pic']?.toString() ??
          map['photo']?.toString(),
      interests: map['interests'] is List
          ? (map['interests'] as List).map((e) {
              if (e is Map) {
                return (e['name'] ?? e['title'] ?? e['label'] ?? e.toString()).toString();
              }
              return e.toString();
            }).toList()
          : (map['interest_names'] is List
              ? (map['interest_names'] as List).map((e) => e.toString()).toList()
              : const []),
      voiceCallsCount: map['voice_calls_count'] is int
          ? map['voice_calls_count'] as int
          : (map['total_calls'] is int
              ? map['total_calls'] as int
              : (int.tryParse(map['voice_calls_count']?.toString() ?? map['total_calls']?.toString() ?? '') ?? 0)),
      rating: map['rating'] is num
          ? (map['rating'] as num).toDouble()
          : (double.tryParse(map['rating']?.toString() ?? '') ?? 5.0),
      isOnline: map['is_online'] == true || map['is_available'] == true,
      profileVisibleInFeed: map['profile_visible_in_feed'] != false,
      ghostCallingMode: map['ghost_calling_mode'] == true,
      isAgent: isAgentUser,
      agentId: map['agent_id']?.toString() ?? json['agent_id']?.toString(),
      role: map['role']?.toString() ?? (isAgentUser ? 'AGENT' : 'USER'),
    );
  }

  /// Converts the model to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'first_name': firstName,
      'name': fullName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (bio != null) 'bio': bio,
      if (profession != null) 'profession': profession,
      if (location != null) 'location': location,
      if (language != null) 'language': language,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender!.displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'interests': interests,
      'voice_calls_count': voiceCallsCount,
      'rating': rating,
      'is_online': isOnline,
      'profile_visible_in_feed': profileVisibleInFeed,
      'ghost_calling_mode': ghostCallingMode,
      'is_agent': isAgent,
      if (agentId != null) 'agent_id': agentId,
      if (role != null) 'role': role,
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? phoneNumber,
    String? countryCode,
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    String? profession,
    String? location,
    String? language,
    int? age,
    Gender? gender,
    String? avatarUrl,
    List<String>? interests,
    int? voiceCallsCount,
    double? rating,
    bool? isOnline,
    bool? profileVisibleInFeed,
    bool? ghostCallingMode,
    bool? isAgent,
    String? agentId,
    String? role,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profession: profession ?? this.profession,
      location: location ?? this.location,
      language: language ?? this.language,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      voiceCallsCount: voiceCallsCount ?? this.voiceCallsCount,
      rating: rating ?? this.rating,
      isOnline: isOnline ?? this.isOnline,
      profileVisibleInFeed: profileVisibleInFeed ?? this.profileVisibleInFeed,
      ghostCallingMode: ghostCallingMode ?? this.ghostCallingMode,
      isAgent: isAgent ?? this.isAgent,
      agentId: agentId ?? this.agentId,
      role: role ?? this.role,
    );
  }

  @override
  String toString() => 'UserProfile(id: $id, name: $fullName, phone: $fullPhoneNumber, age: $age)';
}

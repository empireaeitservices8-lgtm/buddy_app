import 'package:flutter/material.dart';

/// Represents a category / intent option from the caller matching the 3D illustrated cards
class CallerIntent {
  final String id;
  final String title;
  final String emoji;
  final String description; // Tagline e.g. "I need someone to talk to."
  final String targetCategory;
  final List<String> listenerStrengths;
  final Color badgeColor;
  final String ageRange;
  final String languages;
  final String profession;
  final String interests;
  final String bubbleEmoji;
  final String imagePath;

  const CallerIntent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.targetCategory,
    this.listenerStrengths = const [],
    this.badgeColor = const Color(0xFFF15B70),
    this.ageRange = '20–45',
    this.languages = 'English / Hindi',
    this.profession = 'Professional',
    this.interests = 'Talk, Life, Stories',
    this.bubbleEmoji = '💬',
    this.imagePath = '',
  });

  String get fullDisplay => '$emoji $title';

  factory CallerIntent.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['category_id'] ?? '').toString();
    final name = (json['name'] ?? json['title'] ?? json['category_name'] ?? '')
        .toString();
    final desc =
        (json['description'] ?? json['tagline'] ?? json['subtitle'] ?? '')
            .toString();
    final emoji = (json['emoji'] ?? json['icon'] ?? '').toString();
    final image =
        (json['image'] ?? json['image_url'] ?? json['image_path'] ?? '')
            .toString();

    // Match with default local high-res asset templates by id, name, or slug
    CallerIntent? matched;
    for (final def in defaultCallerIntents) {
      if (def.id == id ||
          def.id.toLowerCase() == name.toLowerCase().replaceAll(' ', '_') ||
          def.title.toLowerCase() == name.toLowerCase()) {
        matched = def;
        break;
      }
    }

    return CallerIntent(
      id: id.isNotEmpty
          ? id
          : (matched?.id ?? name.toLowerCase().replaceAll(' ', '_')),
      title: name.isNotEmpty ? name : (matched?.title ?? 'Category'),
      emoji: emoji.isNotEmpty ? emoji : (matched?.emoji ?? '💬'),
      description: desc.isNotEmpty
          ? desc
          : (matched?.description ?? 'Connect and talk'),
      targetCategory: name.isNotEmpty
          ? name
          : (matched?.targetCategory ?? 'General'),
      badgeColor: matched?.badgeColor ?? const Color(0xFF7367F0),
      imagePath: image.isNotEmpty ? image : (matched?.imagePath ?? ''),
      listenerStrengths:
          matched?.listenerStrengths ?? const ['Listening', 'Companionship'],
      ageRange: matched?.ageRange ?? '20–50',
      languages: matched?.languages ?? 'English / Hindi',
      profession: matched?.profession ?? 'Professional',
      interests: matched?.interests ?? 'Talk, Stories',
      bubbleEmoji: matched?.bubbleEmoji ?? '💬',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'emoji': emoji,
    'description': description,
    'target_category': targetCategory,
  };
}

/// The 9 Category Options with high-res 3D card image assets
const List<CallerIntent> defaultCallerIntents = [
  CallerIntent(
    id: 'just_talk',
    title: 'Just Talk',
    emoji: '❤️',
    description: 'I need someone to talk to.',
    targetCategory: 'Just Talk',
    listenerStrengths: ['Listening', 'Companionship'],
    badgeColor: Color(0xFFF15B70), // Vibrant Coral Pink
    ageRange: '25–40',
    languages: 'English / Hindi',
    profession: 'Teacher / Writer',
    interests: 'Books, Movies, Music',
    bubbleEmoji: '❤️',
    imagePath: 'assets/images/categories/just_talk.png',
  ),
  CallerIntent(
    id: 'friendly_conversation',
    title: 'Friendly Conversation',
    emoji: '😊',
    description: "Let's have a pleasant conversation.",
    targetCategory: 'Friendly Conversation',
    listenerStrengths: ['Friendly', 'Connection'],
    badgeColor: Color(0xFFFFA726), // Warm Amber Orange
    ageRange: '20–35',
    languages: 'English / Hindi',
    profession: 'Student / Young Pro',
    interests: 'Sports, Gaming, Travel',
    bubbleEmoji: '😊',
    imagePath: 'assets/images/categories/friendly_conversation.png',
  ),
  CallerIntent(
    id: 'advice',
    title: 'Advice',
    emoji: '💡',
    description: "I need another person's perspective.",
    targetCategory: 'Advice',
    listenerStrengths: ['Perspective', 'Guidance'],
    badgeColor: Color(0xFF7367F0), // Royal Periwinkle Purple
    ageRange: '35–60',
    languages: 'English / Hindi',
    profession: 'Professional / Expert',
    interests: 'Business, Finance, Technology',
    bubbleEmoji: '💡',
    imagePath: 'assets/images/categories/advice.png',
  ),
  CallerIntent(
    id: 'career',
    title: 'Career',
    emoji: '💼',
    description: 'Talk to someone experienced in my field.',
    targetCategory: 'Career',
    listenerStrengths: ['Mentorship', 'Experience'],
    badgeColor: Color(0xFF00B894), // Emerald Teal
    ageRange: '25–50',
    languages: 'English / Hindi',
    profession: 'Executive / Mentor',
    interests: 'Business, Tech, Leadership',
    bubbleEmoji: '📈',
    imagePath: 'assets/images/categories/career.png',
  ),
  CallerIntent(
    id: 'travel',
    title: 'Travel',
    emoji: '✈️',
    description: 'Talk to someone who knows this place.',
    targetCategory: 'Travel',
    listenerStrengths: ['Local Insights', 'Exploration'],
    badgeColor: Color(0xFF29B6F6), // Sky Cyan Blue
    ageRange: '20–40',
    languages: 'English / Hindi / Malayalam',
    profession: 'Explorer / Guide',
    interests: 'Travel, Stories, Culture, Life',
    bubbleEmoji: '✈️',
    imagePath: 'assets/images/categories/travel.png',
  ),
  CallerIntent(
    id: 'elder_companion',
    title: 'Elder Companion',
    emoji: '👴',
    description: 'Someone to talk to regularly.',
    targetCategory: 'Elder Companion',
    listenerStrengths: ['Care', 'Regular Check-in'],
    badgeColor: Color(0xFF7CB342), // Warm Olive Leaf Green
    ageRange: '30–65',
    languages: 'English / Malayalam / Hindi',
    profession: 'Homemaker / Companion',
    interests: 'Life, Gardening, Family, Peace',
    bubbleEmoji: '📞',
    imagePath: 'assets/images/categories/elder_companion.png',
  ),
  CallerIntent(
    id: 'student_companion',
    title: 'Student Companion',
    emoji: '🎓',
    description: 'Talk about studies, college and life.',
    targetCategory: 'Student Companion',
    listenerStrengths: ['College Life', 'Academics'],
    badgeColor: Color(0xFF5C6BC0), // Slate Indigo Blue
    ageRange: '18–30',
    languages: 'English / Hindi',
    profession: 'Student / Researcher',
    interests: 'Studies, Tech, Exams, Growth',
    bubbleEmoji: '🎓',
    imagePath: 'assets/images/categories/student_companion.jpg',
  ),
  CallerIntent(
    id: 'language',
    title: 'Language',
    emoji: '🗣️',
    description: 'Practice English / Hindi / Malayalam / etc.',
    targetCategory: 'Language',
    listenerStrengths: ['Practice', 'Fluency'],
    badgeColor: Color(0xFF00ACC1), // Ocean Turquoise Cyan
    ageRange: '20–45',
    languages: 'English / Hindi / Malayalam',
    profession: 'Language Coach / Tutor',
    interests: 'Fluency, Accents, Grammar, Culture',
    bubbleEmoji: '💬',
    imagePath: 'assets/images/categories/language.png',
  ),
  CallerIntent(
    id: 'casual',
    title: 'Casual',
    emoji: '☕',
    description: 'Nothing serious — just chat.',
    targetCategory: 'Casual',
    listenerStrengths: ['Chit-chat', 'Relaxed'],
    badgeColor: Color(0xFFF06292), // Strawberry Rose Pink
    ageRange: '20–50',
    languages: 'English / Hindi',
    profession: 'Any (Friendly)',
    interests: 'Daily life, Hobbies, Fun, Music',
    bubbleEmoji: '☕',
    imagePath: 'assets/images/categories/casual.png',
  ),
];

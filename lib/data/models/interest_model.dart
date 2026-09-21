/// Model representing an interest category with icon, id and name
class InterestItem {
  final int id;
  final String name;
  final String icon;

  const InterestItem({
    required this.id,
    required this.name,
    required this.icon,
  });

  /// Formatted display text, e.g. "🎵 Music"
  String get displayTag => '$icon $name';

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    return InterestItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '✨',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterestItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => displayTag;
}

/// Fallback / Initial list of 16 official interests
const List<InterestItem> defaultInterestsList = [
  InterestItem(id: 1, name: 'Music', icon: '🎵'),
  InterestItem(id: 2, name: 'Movies & TV', icon: '🎬'),
  InterestItem(id: 3, name: 'Gaming', icon: '🎮'),
  InterestItem(id: 4, name: 'Travel & Places', icon: '✈️'),
  InterestItem(id: 5, name: 'Sports & Cricket', icon: '⚽'),
  InterestItem(id: 6, name: 'Food & Cooking', icon: '🍕'),
  InterestItem(id: 7, name: 'Technology & Coding', icon: '💻'),
  InterestItem(id: 8, name: 'Books & Reading', icon: '📚'),
  InterestItem(id: 9, name: 'Fitness & Gym', icon: '🏋️'),
  InterestItem(id: 10, name: 'Art & Design', icon: '🎨'),
  InterestItem(id: 11, name: 'Photography', icon: '📸'),
  InterestItem(id: 12, name: 'Nature & Outdoors', icon: '🌿'),
  InterestItem(id: 13, name: 'Pets & Animals', icon: '🐾'),
  InterestItem(id: 14, name: 'Business & Startups', icon: '💼'),
  InterestItem(id: 15, name: 'Anime & Manga', icon: '🍙'),
  InterestItem(id: 16, name: 'Philosophy & Life', icon: '💭'),
];

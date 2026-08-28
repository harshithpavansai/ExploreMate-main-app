/// User profile model.
/// Ready for Firestore: fromMap / toMap round-trips.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final List<String> badges;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.badges = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? 'Explorer',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      badges: List<String>.from(map['badges'] as List? ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'level': level,
        'xp': xp,
        'badges': badges,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    int? level,
    int? xp,
    List<String>? badges,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      badges: badges ?? this.badges,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'UserModel($uid, $name, lv$level, ${xp}xp)';
}

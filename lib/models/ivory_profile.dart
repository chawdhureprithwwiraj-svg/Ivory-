/// A member's public profile inside Ivory.
///
/// PRIVACY: phone and date of birth are deliberately absent from this
/// model. They live in restricted private signup details, never in the
/// profile data shared with other members.
class IvoryProfile {
  const IvoryProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.avatarPath,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String displayName;
  final String role;

  /// Private Supabase Storage object path for new profile photos.
  final String? avatarPath;

  /// Read-only compatibility for any older profile URL already in the row.
  final String? avatarUrl;
  final String? bio;

  bool get isAdmin => role == 'admin';

  /// Short UUID shown in the UI instead of any personal identifier.
  String get shortId =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  IvoryProfile withAvatarPath(String? value) => IvoryProfile(
        id: id,
        displayName: displayName,
        role: role,
        avatarPath: value,
        bio: bio,
      );

  factory IvoryProfile.fromMap(Map<String, dynamic> map) {
    return IvoryProfile(
      id: map['id'] as String,
      displayName: (map['display_name'] as String?) ?? 'Anonymous Reader',
      role: (map['role'] as String?) ?? 'user',
      avatarPath: map['avatar_path'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'role': role,
      'avatar_path': avatarPath,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }
}

// END OF FILE - lib/models/ivory_profile.dart

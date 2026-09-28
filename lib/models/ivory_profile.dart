/// A user's public profile inside Ivory.
///
/// PRIVACY: there is deliberately no phone number field anywhere in this
/// model or in the database. Users are identified only by their UUID.
class IvoryProfile {
  const IvoryProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.bio,
  });

  final String id;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final String? bio;

  bool get isAdmin => role == 'admin';

  /// Short UUID shown in the UI instead of any personal identifier.
  String get shortId =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  factory IvoryProfile.fromMap(Map<String, dynamic> map) {
    return IvoryProfile(
      id: map['id'] as String,
      displayName: (map['display_name'] as String?) ?? 'Anonymous Reader',
      role: (map['role'] as String?) ?? 'user',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'display_name': displayName,
      'role': role,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }
}

class CallAudioIdentity {
  const CallAudioIdentity({
    required this.displayName,
    required this.isAdmin,
    this.imageUrl,
  });

  final String displayName;
  final String? imageUrl;
  final bool isAdmin;
}

// END OF FILE - lib/models/call_audio_identity.dart

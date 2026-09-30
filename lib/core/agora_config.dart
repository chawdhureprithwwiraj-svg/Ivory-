/// IVORY - Agora settings.
///
/// WHAT IS SAFE TO KEEP HERE
/// The App ID identifies your Agora project. On its own it opens
/// nothing: because the project runs in secured mode, Agora refuses
/// every join that does not also carry a signed token.
///
/// WHAT MUST NEVER COME HERE
/// The App Certificate. It is the key that signs those tokens, and it
/// lives only as a secret on the Supabase Edge Function "agora-token".
/// If it ever shipped inside an APK, anyone could mint their own token
/// and walk into a paid session for free.
class AgoraConfig {
  AgoraConfig._();

  /// Agora Console -> Project "Ivory" -> Basic Settings -> App ID.
  static const String appId = '12fc3ff3816e4a71847be30598cb682d';

  /// The Edge Function that checks entitlement and signs a token.
  static const String tokenFunction = 'agora-token';

  /// Agora's free tier is 10,000 minutes a month. This is only used to
  /// show a friendly warning in the admin console, nothing enforces it.
  static const int freeMinutesPerMonth = 10000;

  static bool get isConfigured => appId.length == 32;
}

// END OF FILE - lib/core/agora_config.dart

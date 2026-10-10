import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ivory_profile.dart';

/// All authentication and profile logic for Ivory lives here, so screens
/// never talk to Supabase directly.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fires whenever the user signs in, signs out or the token refreshes.
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? dateOfBirth,
  }) async {
    final Map<String, dynamic> metadata = <String, dynamic>{
      'display_name': displayName.trim(),
    };
    if (phoneNumber?.trim().isNotEmpty ?? false) {
      metadata['phone_number'] = phoneNumber!.trim();
    }
    if (dateOfBirth?.trim().isNotEmpty ?? false) {
      metadata['date_of_birth'] = dateOfBirth!.trim();
    }
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());

  /// Loads the signed-in user's profile row, including their role.
  /// The last profile we loaded. Lets small widgets - the live
  /// banner, the viewer count - ask whether this is the admin
  /// without another round trip.
  IvoryProfile? cachedProfile;

  bool get isAdminCached => cachedProfile?.isAdmin ?? false;

  Future<IvoryProfile?> loadProfile() async {
    final User? user = currentUser;
    if (user == null) return null;

    final Map<String, dynamic>? row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    final IvoryProfile profile = IvoryProfile.fromMap(row);
    cachedProfile = profile;
    return profile;
  }

  Future<void> updateDisplayName(String displayName) async {
    final User? user = currentUser;
    if (user == null) return;
    await _client
        .from('profiles')
        .update(<String, dynamic>{'display_name': displayName.trim()})
        .eq('id', user.id);
  }

  Future<void> updateAvatarPath(String? path) async {
    final User? user = currentUser;
    if (user == null) throw StateError('Sign in to update your photo.');
    final Map<String, dynamic>? row = await _client
        .from('profiles')
        .update(<String, dynamic>{
          'avatar_path': path,
          'avatar_url': null,
        })
        .eq('id', user.id)
        .select('id')
        .maybeSingle();
    if (row == null) {
      throw StateError('Your profile could not be found. Please sign in again.');
    }
    final IvoryProfile? cached = cachedProfile;
    if (cached?.id == user.id) cachedProfile = cached!.withAvatarPath(path);
  }

  /// Turns raw Supabase errors into wording a reader would understand.
  static String friendlyError(Object error) {
    if (error is AuthException) {
      final String m = error.message.toLowerCase();
      if (m.contains('invalid login')) {
        return 'That email and password do not match. Please try again.';
      }
      if (m.contains('already registered') || m.contains('already exists')) {
        return 'An account with this email already exists. Try signing in.';
      }
      if (m.contains('password')) {
        return 'Your password must be at least 6 characters long.';
      }
      if (m.contains('email')) {
        return 'Please enter a valid email address.';
      }
      return error.message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return 'Something went wrong. Please check your connection and retry.';
  }
}

// END OF FILE - lib/services/auth_service.dart

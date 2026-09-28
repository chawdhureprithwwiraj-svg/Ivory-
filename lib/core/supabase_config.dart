/// IVORY - Supabase connection settings.
///
/// WHERE TO FIND THESE
///   Dashboard -> Project Settings -> API Keys
///   or the green "Connect" button at the top of the dashboard.
///
/// The Project URL is always https://<project-id>.supabase.co
///
/// WHICH KEY?  Either of these works:
///   - Publishable key (new style):  sb_publishable_xxxxxxxx
///   - anon / public key (legacy):   eyJhbGciOiJIUzI1NiIs...
///
/// NEVER paste a key labelled "secret", "sb_secret_..." or
/// "service_role". Those bypass every security rule in the database
/// and must never ship inside an app.
///
/// IS IT SAFE IN A PUBLIC REPO?
/// Yes. Publishable and anon keys are designed to be shipped inside
/// client apps. They grant nothing on their own - every table is
/// protected by the Row Level Security policies in supabase_schema.sql.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://soephrftgddbwkzwjddj.supabase.co';
  static const String anonKey = 'sb_publishable_5b65ct89qKIucONgiOLWhw_QO4DXeQM';

  /// True once both values look like real credentials rather than
  /// the placeholders above.
  static bool get isConfigured {
    final String u = url.trim();
    final String k = anonKey.trim();
    final bool urlOk = u.startsWith('https://') && u.contains('.supabase.');
    final bool keyOk = k.length > 20 &&
        !k.startsWith('PASTE_') &&
        // Reject a service_role / secret key outright - it must never
        // be shipped in the app.
        !k.startsWith('sb_secret_');
    return urlOk && keyOk;
  }
}

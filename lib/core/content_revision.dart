import 'package:flutter/foundation.dart';

/// ============================================================
/// WHEN THE LIBRARY CHANGES, EVERY SHELF MUST HEAR ABOUT IT
/// ============================================================
/// Home and Explore both load their posts once, in `initState`, and
/// `main_shell` keeps every tab alive inside an `IndexedStack` - so
/// moving between tabs never rebuilds them. Without something like
/// this, a post published, edited, hidden or deleted in the Admin
/// studio leaves Home showing the old wording until the app is killed
/// and reopened. Sprint 24p made it obvious (an edited title stayed
/// stale on Home while Explore looked right, because Explore happens
/// to reload when a filter chip is tapped), but the fault was there
/// the whole time and affected publishing too.
///
/// The counter below is bumped by `AdminService` whenever something
/// about the library actually changed. Any screen showing posts
/// listens and reloads itself.
///
/// HOW TO USE IT IN A SCREEN
/// ```
/// @override
/// void initState() {
///   super.initState();
///   _load();
///   contentRevision.addListener(_onContentChanged);
/// }
///
/// @override
/// void dispose() {
///   contentRevision.removeListener(_onContentChanged);
///   super.dispose();
/// }
///
/// void _onContentChanged() {
///   if (mounted) _load();
/// }
/// ```
/// **Always remove the listener in dispose.** A listener left behind
/// calls setState on a dead screen and throws.
///
/// This is deliberately a plain counter and not a stream or a state
/// package: it costs nothing, it has no dependency, and the whole of
/// it is readable in one sitting.
final ValueNotifier<int> contentRevision = ValueNotifier<int>(0);

/// Called from `AdminService` after a change has been written. Safe to
/// call more than once for one action - the editor saves the post and
/// then the price, which bumps twice, and the second reload simply
/// lands on the final truth.
void bumpContentRevision() => contentRevision.value++;

// END OF FILE - lib/core/content_revision.dart

import '../services/live_service.dart';

/// THE CLOCK, AND THE ONE QUESTION IT ASKS THE DATABASE.
///
/// Lifted out of live_screen.dart, which was at the paste
/// ceiling. Keeping it here also means the rule about running
/// out of minutes lives in one place instead of being spelled
/// out inside a one-second timer.
class CallTimeWatch {
  const CallTimeWatch._();

  /// Minutes and seconds, as the member reads them.
  static String elapsedText(Duration total) {
    final int m = total.inMinutes;
    final String s = (total.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Asks whether the booked time has run out.
  ///
  /// The database owns the rule, so nothing here needs to know
  /// how long the session was, nor whether a paid extension has
  /// since made it longer. A true NEVER means stop - it only
  /// means the wording on screen may change, and that Ivory has
  /// been nudged once to offer more time.
  static Future<bool> isOver(int callId, Duration total) {
    return LiveService.instance.callTimeUp(callId, total.inSeconds);
  }
}

// END OF FILE - lib/widgets/call_time_watch.dart

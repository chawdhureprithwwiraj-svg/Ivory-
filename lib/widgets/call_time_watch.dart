import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/live_models.dart';
import '../services/live_service.dart';
import '../core/ivory_errors.dart';
import 'call_extension_prompt.dart';
import 'live_stage_bits.dart';

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

/// ============================================================
/// ONE CLOCK, ONE MOMENT IT COUNTS FROM.
///
/// Every handset used to run its own stopwatch, started the
/// instant that particular phone got into the room. Two people
/// never arrive at the same second, so the two screens drifted
/// apart by exactly the gap between their arrivals - forty
/// seconds, in the owner's test. On a session that is charged
/// by the minute, two different answers is one too many.
///
/// So the clock no longer counts ticks. It remembers a single
/// MOMENT and subtracts. Both handsets are given the same
/// moment, so both must reach the same number:
///
///   a broadcast counts from when the broadcast opened, which
///   the database already stamps and every viewer can read;
///
///   a session counts from when the two of you were actually
///   connected, which is the owner's standing rule - the clock
///   starts at connection, never at the booked time and never
///   while one of you is still waiting alone.
///
/// Waiting alone is therefore free, and it is free by exactly
/// the same amount on both phones.
/// ============================================================
class RoomClock {
  /// The one moment this clock counts from. Null until there is
  /// something true to count.
  DateTime? _from;

  /// Seconds this session had already used on earlier visits,
  /// as the database reported them.
  int prior = 0;

  /// Set the moment. The first answer wins: a signal that drops
  /// and comes back must not restart the clock, and a second
  /// person rejoining must not wind it back to zero.
  void startAt(DateTime? moment) {
    if (moment == null) return;
    _from ??= moment;
  }

  /// Has anything begun that is worth showing?
  bool get running => _from != null;

  /// THE MOMENT THE DATABASE REMEMBERS, NOT THE ONE THIS PHONE
  /// HAPPENS TO KNOW.
  ///
  /// Anchoring on connection fixed two people arriving at
  /// different times, but not somebody LEAVING and coming back.
  /// A returning handset builds a brand new room, and all the
  /// database can tell it is how many seconds were banked at
  /// the moment that person walked out. The one who stayed kept
  /// counting straight through the gap, so the returner comes
  /// back exactly their away-time behind - thirty, forty, fifty
  /// seconds, whatever it was.
  ///
  /// The cure is for neither phone to be counting anything. The
  /// session is stamped once, when the two of you first connect,
  /// and from then on both screens simply subtract from that
  /// stamp. Walking out and back in changes nothing, because
  /// there is nothing on the handset to lose. The banked count
  /// is cleared at the same time, since the stamp already
  /// covers every second from the beginning.
  Future<void> anchorFromDatabase(int callId) async {
    try {
      final CallRequest? row =
          await LiveService.instance.fetchCall(callId);
      final DateTime? began = row?.startedAt;
      if (began == null) return;
      prior = 0;
      startAt(began.toLocal());
    } catch (_) {
      // If the row cannot be read, the room falls back to
      // counting from connection. A clock that is slightly out
      // is better than a room that refuses to open.
    }
  }

  /// This visit, from the shared moment to now. Never negative,
  /// in case a phone's own clock is set a little ahead.
  Duration get visit {
    final DateTime? f = _from;
    if (f == null) return Duration.zero;
    final Duration d = DateTime.now().difference(f);
    return d.isNegative ? Duration.zero : d;
  }

  /// Everything this session has used, earlier visits included.
  /// This is the figure that is reported for charging.
  Duration get total => visit + Duration(seconds: prior);

  /// What goes in the gold pill at the top of the room.
  String get text => CallTimeWatch.elapsedText(total);
}

/// ============================================================
/// THE TWO THINGS A RUNNING SESSION CHECKS ON, AND LEAVING IT.
///
/// Lifted out of live_screen.dart, which was back at the paste
/// ceiling. Neither of these is about what the room looks like,
/// so neither belonged in a screen.
/// ============================================================
class RoomDuties {
  const RoomDuties._();

  /// Once a minute, ask whether the booked time has run out;
  /// every fifteen seconds, see whether Ivory has pushed an
  /// offer of more time onto this screen. Both are quiet: a
  /// true from either NEVER stops the call.
  static void tick({
    required BuildContext context,
    required int tick,
    required int callId,
    required Duration total,
    required Duration visit,
    required bool timeUpKnown,
    required bool offerShown,
    required bool connected,
    required void Function() onTimeUp,
    required void Function() onOfferShown,
  }) {
    if (!timeUpKnown && tick % 60 == 0) {
      CallTimeWatch.isOver(callId, total).then((bool over) {
        if (over) onTimeUp();
      });
    }
    if (!offerShown && connected && tick % 15 == 0) {
      CallExtensionPrompt.tick(context,
          callId: callId, elapsed: visit, onShown: onOfferShown);
    }
  }
}

/// LEAVING IS NOT ENDING.
///
/// A mistap, a lost signal or an incoming phone call must never
/// destroy minutes that were paid for. Closing the engine and
/// reporting the count is all that happens here; the session
/// itself stays open until the owner taps END SESSION.
/// THE MICROPHONE, AND THE CAMERA ONLY WHEN THERE IS ONE.
///
/// An audio session must never ask for the camera; being asked
/// for a lens on a voice call is exactly the kind of thing that
/// makes somebody close an app. Returns null when the room may
/// open, or the sentence to show when it may not.
class RoomEntry {
  const RoomEntry._();

  static Future<String?> permissions({
    required bool publishes,
    required bool video,
  }) async {
    final List<Permission> needed = <Permission>[
      if (publishes) Permission.microphone,
      if (publishes && video) Permission.camera,
    ];
    if (needed.isEmpty) return null;
    final Map<Permission, PermissionStatus> granted =
        await needed.request();
    if (granted.values.every((PermissionStatus s) => s.isGranted)) {
      return null;
    }
    return 'Ivory needs the microphone'
        '${video ? ' and camera' : ''} to take part. '
        'You can allow it in Settings and come back.';
  }

  /// THE TICKET, WITH AN END TO THE WAITING.
  ///
  /// This was the Opening the room hang. The ticket call had
  /// no time limit, so a request that never came back left
  /// that sentence on the screen for ever - no error, no way
  /// out, nothing to tap. On a phone that has wandered
  /// between two bars of signal, that is not rare.
  ///
  /// Twenty seconds is deliberately generous: long enough
  /// that a slow but working connection is never cut off,
  /// short enough that nobody sits staring at a dead screen.
  ///
  /// The message says what to do next, because an error a
  /// member cannot act on is only bad news delivered politely.
  static Future<AgoraTicket> ticket({
    required bool isCall,
    required int id,
  }) async {
    try {
      return await (isCall
              ? LiveService.instance.joinCall(id)
              : LiveService.instance.joinLive(id))
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw Exception(isCall
          ? 'The room did not open. Check your signal and tap '
              'JOIN again - your session and its minutes are '
              'untouched.'
          : 'The room did not open. Check your signal and try '
              'again in a moment.');
    }
  }

  /// BRINGING THE ENGINE UP.
  ///
  /// Creating it, choosing the profile, turning on audio and
  /// only then video, and setting the role. Lifted out of
  /// live_screen.dart whole, because that file sits on the
  /// paste ceiling and shaving comments off it has never once
  /// been the right answer.
  ///
  /// The order matters and is easy to get wrong: audio first
  /// so a call still works when the camera is refused, and
  /// the preview started only for somebody who is actually
  /// publishing video.
  static Future<RtcEngine> engine({
    required String appId,
    required bool isCall,
  }) async {
    final RtcEngine e = createAgoraRtcEngine();
    await e.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: isCall
          ? ChannelProfileType.channelProfileCommunication
          : ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    return e;
  }

  /// Audio, video and role, after the handlers are attached -
  /// so nothing can happen before anyone is listening.
  static Future<void> ready({
    required RtcEngine engine,
    required bool video,
    required bool publishes,
  }) async {
    await engine.enableAudio();
    if (video) await engine.enableVideo();
    if (publishes) {
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      if (video) await engine.startPreview();
    } else {
      await engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
  }

  /// The same guard around the moment of actually connecting.
  /// Agora can accept the request and then never report back.
  static Future<void> connect(Future<void> joining) async {
    try {
      await joining.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw Exception('Could not connect to the room. Check your '
          'signal and try again.');
    }
  }
}

class RoomExit {
  const RoomExit._();

  static Future<void> leaveRoom({
    required RtcEngine? engine,
    required int sessionId,
    required bool watching,
    required bool writeExit,
    required Duration total,
  }) async {
    if (engine != null) {
      try {
        await engine.leaveChannel();
        await engine.release();
      } catch (_) {}
    }
    if (watching) {
      await LiveService.instance.leaveLive(sessionId);
    }
    if (writeExit) {
      await LiveService.instance.callExit(sessionId, total.inSeconds);
    }
  }

  /// END SESSION. The only thing in Ivory that truly closes a
  /// session, so it always asks first. Returns a message to put
  /// on screen if it failed, or null if the room is now shut.
  /// Nothing here navigates; the screen decides that.
  static Future<String?> endSession(
    BuildContext context, {
    required int sessionId,
    required bool Function() claimExit,
    required Duration total,
  }) async {
    final bool sure = await confirmEndSession(context);
    if (!sure) return _kept;
    try {
      if (claimExit()) {
        await LiveService.instance.callExit(sessionId, total.inSeconds);
      }
      await LiveService.instance.callFinish(sessionId);
    } catch (e) {
      return houseMessage(e);
    }
    return null;
  }

  /// Returned when Ivory changed her mind at the dialog, so the
  /// screen knows to leave everything exactly as it was.
  static const String _kept = 'keep';

  static bool keptOpen(String? result) => result == _kept;
}

// END OF FILE - lib/widgets/call_time_watch.dart

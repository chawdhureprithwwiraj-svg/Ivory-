import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Meter values stay separate so either participant's voice can animate the
/// call artwork without rebuilding the portraits on every audio callback.
class AudioCallBeatLevels {
  const AudioCallBeatLevels({this.local = 0, this.remote = 0});

  final double local;
  final double remote;

  double get peak => local > remote ? local : remote;
}

class AudioCallBeatMeter {
  AudioCallBeatMeter._();

  static final AudioCallBeatMeter instance = AudioCallBeatMeter._();

  final ValueNotifier<AudioCallBeatLevels> levels =
      ValueNotifier<AudioCallBeatLevels>(const AudioCallBeatLevels());

  double _local = 0;
  double _remote = 0;

  void reset() {
    _local = 0;
    _remote = 0;
    levels.value = const AudioCallBeatLevels();
  }

  void clearRemote() {
    _remote = 0;
    _publish();
  }

  /// Agora reports the local speaker (uid 0) and remote speaker levels in
  /// separate callbacks. Keep the last value for the other side between them.
  void update(
    List<AudioVolumeInfo> speakers,
    int speakerNumber, {
    required bool localMuted,
  }) {
    bool sawRemote = false;
    double remotePeak = 0;

    for (final AudioVolumeInfo speaker in speakers) {
      if (speaker.uid == 0) {
        _local = localMuted ? 0 : _level(speaker);
      } else if (speaker.uid != null) {
        sawRemote = true;
        final double value = _level(speaker);
        if (value > remotePeak) remotePeak = value;
      }
    }

    if (sawRemote) {
      _remote = remotePeak;
    } else if (speakers.isEmpty && speakerNumber == 0) {
      _remote = 0;
    }
    _publish();
  }

  double _level(AudioVolumeInfo speaker) {
    if (speaker.uid == 0 && speaker.vad == 0) return 0;
    final int volume = speaker.volume ?? 0;
    if (volume < 14) return 0;
    return ((volume - 14) / 96).clamp(0.0, 1.0).toDouble();
  }

  void _publish() {
    final AudioCallBeatLevels old = levels.value;
    if ((_local - old.local).abs() < 0.025 &&
        (_remote - old.remote).abs() < 0.025) {
      return;
    }
    levels.value = AudioCallBeatLevels(local: _local, remote: _remote);
  }
}

// END OF FILE - lib/services/audio_call_beat_meter.dart

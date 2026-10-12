import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings for Ivory's own local-camera beauty controls.
class LiveBeautySettings {
  const LiveBeautySettings({
    this.enabled = true,
    this.smoothness = 0.24,
    this.lightening = 0.0,
    this.redness = 0.0,
  });

  static const LiveBeautySettings defaults = LiveBeautySettings();

  final bool enabled;
  final double smoothness;
  final double lightening;
  final double redness;

  LiveBeautySettings copyWith({
    bool? enabled,
    double? smoothness,
    double? lightening,
    double? redness,
  }) => LiveBeautySettings(
    enabled: enabled ?? this.enabled,
    smoothness: (smoothness ?? this.smoothness).clamp(0.0, 1.0).toDouble(),
    lightening: (lightening ?? this.lightening).clamp(0.0, 1.0).toDouble(),
    redness: (redness ?? this.redness).clamp(0.0, 1.0).toDouble(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': enabled,
    'smoothness': smoothness,
    'lightening': lightening,
    'redness': redness,
  };

  factory LiveBeautySettings.fromJson(Map<String, dynamic> json) =>
      LiveBeautySettings(
        enabled: json['enabled'] as bool? ?? true,
        smoothness: _number(json['smoothness'], 0.24, 1.0),
        lightening: _number(json['lightening'], 0.0, 1.0),
        redness: _number(json['redness'], 0.0, 1.0),
      );

  static double _number(dynamic value, double fallback, double max) {
    if (value is! num) return fallback;
    return value.toDouble().clamp(0.0, max).toDouble();
  }
}

/// Stores the selected look and applies it only to the local camera source.
class LiveBeautyService {
  LiveBeautyService._();

  static final LiveBeautyService instance = LiveBeautyService._();
  static const String _storageKey = 'ivory.live_beauty.v1';

  LiveBeautySettings _settings = LiveBeautySettings.defaults;
  Future<void>? _loading;
  bool _loaded = false;

  LiveBeautySettings get settings => _settings;

  Future<void> load() async {
    if (_loaded) return;
    _loading ??= _read();
    await _loading!;
  }

  Future<void> _read() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null) {
        final dynamic value = jsonDecode(raw);
        if (value is Map<String, dynamic>) {
          // Unsupported legacy face-shape values are intentionally ignored.
          _settings = LiveBeautySettings.fromJson(value);
        }
      }
    } catch (_) {
      _settings = LiveBeautySettings.defaults;
    }
    _loaded = true;
  }

  void update(LiveBeautySettings value) {
    _settings = value;
    _loaded = true;
  }

  Future<void> persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_settings.toJson()));
    } catch (_) {
      // A local preference failure must not interrupt a live room.
    }
  }

  /// Applies Agora's basic smoothing, whole-image lightening and rosiness
  /// to the local primary camera. A failed optional control never blocks the room session.
  Future<String?> apply(RtcEngine engine) async {
    final LiveBeautySettings value = _settings;
    try {
      await engine.setBeautyEffectOptions(
        enabled: value.enabled,
        options: BeautyOptions(
          lighteningContrastLevel:
              LighteningContrastLevel.lighteningContrastLow,
          lighteningLevel: value.enabled ? value.lightening : 0,
          smoothnessLevel: value.enabled ? value.smoothness : 0,
          rednessLevel: value.enabled ? value.redness : 0,
          sharpnessLevel: 0,
        ),
        type: MediaSourceType.primaryCameraSource,
      );
    } catch (_) {
      return 'Beauty controls are unavailable on this device.';
    }
    return null;
  }
}

// END OF FILE - lib/services/live_beauty_service.dart

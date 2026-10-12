import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

import '../services/live_beauty_service.dart';
import '../theme/ivory_theme.dart';

Future<void> showLiveBeautyPanel(BuildContext context, RtcEngine engine) async {
  await LiveBeautyService.instance.load();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LiveBeautyPanel(engine: engine),
  );
}

/// Shared by the owner's private preview and host live broadcast.
class LiveBeautyPanel extends StatefulWidget {
  const LiveBeautyPanel({super.key, required this.engine});

  final RtcEngine engine;

  @override
  State<LiveBeautyPanel> createState() => _LiveBeautyPanelState();
}

class _LiveBeautyPanelState extends State<LiveBeautyPanel> {
  final LiveBeautyService _service = LiveBeautyService.instance;
  late LiveBeautySettings _settings;
  Timer? _applyTimer;
  Timer? _saveTimer;
  bool _applying = false;
  bool _applyAgain = false;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    _settings = _service.settings;
  }

  @override
  void dispose() {
    _applyTimer?.cancel();
    _saveTimer?.cancel();
    unawaited(_service.persist());
    super.dispose();
  }

  void _change(LiveBeautySettings next) {
    setState(() => _settings = next);
    _service.update(next);
    _applyTimer?.cancel();
    _applyTimer = Timer(const Duration(milliseconds: 110), _apply);
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_service.persist()),
    );
  }

  Future<void> _apply() async {
    if (_applying) {
      _applyAgain = true;
      return;
    }
    _applying = true;
    do {
      _applyAgain = false;
      final String? note = await _service.apply(widget.engine);
      if (note != null && !_warned && mounted) {
        _warned = true;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(note)));
      }
    } while (_applyAgain);
    _applying = false;
  }

  void _reset() => _change(LiveBeautySettings.defaults);

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: IvoryColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: IvoryTheme.softShadow(blur: 24, y: -5),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: IvoryColors.gold.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.face_retouching_natural_rounded,
                      color: IvoryColors.burgundy,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'BEAUTY',
                        style: TextStyle(
                          color: IvoryColors.burgundy,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reset'),
                    ),
                    IconButton(
                      tooltip: 'Close beauty controls',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  'Host camera only. Lightening affects the whole camera image.',
                  style: TextStyle(color: IvoryColors.textSoft, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: IvoryColors.gold,
                  value: _settings.enabled,
                  onChanged: (bool value) =>
                      _change(_settings.copyWith(enabled: value)),
                  title: const Text(
                    'Beauty on',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (_settings.enabled) ...<Widget>[
                  _slider(
                    title: 'Skin smoothing',
                    value: _settings.smoothness,
                    max: 1.0,
                    divisions: 40,
                    onChanged: (double value) =>
                        _change(_settings.copyWith(smoothness: value)),
                  ),
                  _slider(
                    title: 'Lightening',
                    value: _settings.lightening,
                    max: 1.0,
                    divisions: 40,
                    onChanged: (double value) =>
                        _change(_settings.copyWith(lightening: value)),
                  ),
                  Text(
                    'Lightening brightens the whole camera image, including '
                    'the background—not just the face. It starts at 0.0. '
                    'Smoothing may soften minor marks but does not remove '
                    'individual pimples.',
                    style: TextStyle(
                      color: IvoryColors.textFaint,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _faceShapeNotice(),
                const SizedBox(height: 8),
                Text(
                  'Colored contacts remain deferred; no iris recoloring is '
                  'applied.',
                  style: TextStyle(
                    color: IvoryColors.textFaint,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _faceShapeNotice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: IvoryColors.gold.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: IvoryColors.gold.withValues(alpha: 0.55)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          Icons.lock_outline_rounded,
          color: IvoryColors.burgundy,
          size: 18,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Face slimming is disabled pending Ivory’s project-specific '
            'Agora entitlement, exact billing implications and approval.',
            style: TextStyle(
              color: IvoryColors.burgundy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _slider({
    required String title,
    required double value,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) => Column(
    children: <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: IvoryColors.burgundy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${(value / max * 100).round()}%',
            style: TextStyle(
              color: IvoryColors.textFaint,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      Slider(
        min: 0,
        max: max,
        divisions: divisions,
        value: value.clamp(0.0, max).toDouble(),
        activeColor: IvoryColors.burgundy,
        inactiveColor: IvoryColors.gold.withValues(alpha: 0.38),
        onChanged: onChanged,
      ),
    ],
  );
}

// END OF FILE - lib/widgets/live_beauty_panel.dart

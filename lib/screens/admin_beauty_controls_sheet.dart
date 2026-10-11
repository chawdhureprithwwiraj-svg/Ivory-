import 'package:flutter/material.dart';

import '../services/admin_beauty_frame_processor.dart';
import '../theme/ivory_theme.dart';

/// Shows the prototype controls without coupling presentation to the camera.
Future<void> showAdminBeautyControlsSheet({
  required BuildContext context,
  required AdminBeautyTuning initialTuning,
  required ValueChanged<AdminBeautyTuning> onChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => _AdminBeautyControlsSheet(
      initialTuning: initialTuning,
      onChanged: onChanged,
    ),
  );
}

class _AdminBeautyControlsSheet extends StatefulWidget {
  const _AdminBeautyControlsSheet({
    required this.initialTuning,
    required this.onChanged,
  });

  final AdminBeautyTuning initialTuning;
  final ValueChanged<AdminBeautyTuning> onChanged;

  @override
  State<_AdminBeautyControlsSheet> createState() =>
      _AdminBeautyControlsSheetState();
}

class _AdminBeautyControlsSheetState extends State<_AdminBeautyControlsSheet> {
  late AdminBeautyTuning _tuning = widget.initialTuning;

  void _change(AdminBeautyTuning value) {
    setState(() => _tuning = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'ON-DEVICE FACE CONTROLS',
                          style: TextStyle(
                            color: IvoryColors.burgundy,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _change(const AdminBeautyTuning(
                          smoothing: 0,
                          brightening: 0,
                          slimming: 0,
                        )),
                        child: const Text('Reset'),
                      ),
                      IconButton(
                        tooltip: 'Close controls',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Experimental preview only. Skin softening is not targeted '
                    'pimple removal; face slimming is a subtle mesh-bounded warp.',
                    style: TextStyle(
                      color: IvoryColors.textSoft,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _TuningSlider(
                    title: 'Skin softening',
                    value: _tuning.smoothing,
                    onChanged: (double value) =>
                        _change(_tuning.copyWith(smoothing: value)),
                  ),
                  _TuningSlider(
                    title: 'Face-only brightening',
                    value: _tuning.brightening,
                    onChanged: (double value) =>
                        _change(_tuning.copyWith(brightening: value)),
                  ),
                  _TuningSlider(
                    title: 'Experimental face slimming',
                    value: _tuning.slimming,
                    onChanged: (double value) =>
                        _change(_tuning.copyWith(slimming: value)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _TuningSlider extends StatelessWidget {
  const _TuningSlider({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text('${(value * 100).round()}%'),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            activeColor: IvoryColors.burgundy,
            onChanged: onChanged,
          ),
        ],
      );
}

// END OF FILE - lib/screens/admin_beauty_controls_sheet.dart

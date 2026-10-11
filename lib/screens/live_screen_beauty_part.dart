part of 'live_screen.dart';

extension _LiveScreenBeauty on _LiveScreenState {
  bool get _showLiveBeauty =>
      (widget.mode == LiveMode.host || widget.mode == LiveMode.call) &&
      _isOwner &&
      widget.videoEnabled &&
      _camOn &&
      _joined &&
      _error == null &&
      !_ended &&
      _engine != null;

  Future<void> _applyLiveBeauty(RtcEngine engine) async {
    final bool cameraMode =
        widget.mode == LiveMode.host || widget.mode == LiveMode.call;
    if (!cameraMode || !_isOwner || !widget.videoEnabled) return;
    await LiveBeautyService.instance.load();
    final String? note = await LiveBeautyService.instance.apply(engine);
    if (note != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(note)),
        );
      });
    }
  }

  Future<void> _openLiveBeautyPanel() async {
    if (!_showLiveBeauty) return;
    final RtcEngine? engine = _engine;
    if (engine == null) return;
    await showLiveBeautyPanel(context, engine);
  }
}

// END OF FILE - lib/screens/live_screen_beauty_part.dart

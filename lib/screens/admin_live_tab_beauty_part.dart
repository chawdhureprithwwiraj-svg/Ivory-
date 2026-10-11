part of 'admin_live_tab.dart';

mixin _AdminLiveBeautyMixin on State<AdminLiveTab> {
  Future<void> _openBeautyPreview() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AdminLiveBeautyPreview(),
      ),
    );
  }
}

// END OF FILE - lib/screens/admin_live_tab_beauty_part.dart

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_photo_service.dart';
import '../theme/ivory_theme.dart';
import 'member_avatar.dart';

class ProfilePhotoEditor extends StatefulWidget {
  const ProfilePhotoEditor({
    super.key,
    required this.displayName,
    required this.isActivePaidMember,
    required this.onPathChanged,
    this.avatarPath,
    this.legacyAvatarUrl,
    this.size = 70,
  });

  final String displayName;
  final String? avatarPath;
  final String? legacyAvatarUrl;
  final bool isActivePaidMember;
  final ValueChanged<String?> onPathChanged;
  final double size;

  @override
  State<ProfilePhotoEditor> createState() => _ProfilePhotoEditorState();
}

class _ProfilePhotoEditorState extends State<ProfilePhotoEditor> {
  String? _imageUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProfilePhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath ||
        oldWidget.legacyAvatarUrl != widget.legacyAvatarUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final String? path = widget.avatarPath;
    final String? legacy = widget.legacyAvatarUrl;
    final String? url = path == null
        ? legacy
        : await ProfilePhotoService.instance.signedAvatarUrl(path);
    if (!mounted || path != widget.avatarPath || legacy != widget.legacyAvatarUrl) {
      return;
    }
    setState(() => _imageUrl = url);
  }

  bool get _canRemove =>
      (widget.avatarPath?.isNotEmpty ?? false) ||
      (widget.legacyAvatarUrl?.isNotEmpty ?? false);

  Future<void> _actions() async {
    if (_busy) return;
    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: IvoryColors.surface,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.isActivePaidMember)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: IvoryColors.plum),
                title: const Text('Choose a profile photo'),
                subtitle: const Text(
                  'It appears on your Profile and beside your live-chat messages.',
                ),
                onTap: () => Navigator.pop(sheetContext, 'choose'),
              ),
            if (_canRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: IvoryColors.danger),
                title: const Text('Remove profile photo'),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'choose') await _choose();
    if (action == 'remove') await _remove();
  }

  Future<void> _choose() async {
    if (!widget.isActivePaidMember || _busy) return;
    setState(() => _busy = true);
    String? uploadedPath;
    try {
      uploadedPath = await ProfilePhotoService.instance.pickAndUpload();
      if (uploadedPath == null) return;
      await AuthService.instance.updateAvatarPath(uploadedPath);
      final String? oldPath = widget.avatarPath;
      if (oldPath != null) {
        try {
          await ProfilePhotoService.instance.deleteOwnPhoto(oldPath);
        } catch (_) {
          // A cleanup failure must not undo a photo already saved to profile.
        }
      }
      final String? url = await ProfilePhotoService.instance
          .signedAvatarUrl(uploadedPath, refresh: true);
      widget.onPathChanged(uploadedPath);
      if (mounted) setState(() => _imageUrl = url);
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await ProfilePhotoService.instance.deleteOwnPhoto(uploadedPath);
        } catch (_) {}
      }
      _notice(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    if (_busy || !_canRemove) return;
    setState(() => _busy = true);
    final String? oldPath = widget.avatarPath;
    try {
      await AuthService.instance.updateAvatarPath(null);
      widget.onPathChanged(null);
      if (oldPath != null) {
        await ProfilePhotoService.instance.deleteOwnPhoto(oldPath);
      }
      if (mounted) setState(() => _imageUrl = null);
    } catch (error) {
      _notice(_errorText(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(Object error) {
    if (error is StateError) return error.message.toString();
    return AuthService.friendlyError(error);
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canTap = !_busy &&
        (widget.isActivePaidMember || _canRemove);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        InkWell(
          onTap: canTap ? _actions : null,
          customBorder: const CircleBorder(),
          child: MemberAvatar(
            displayName: widget.displayName,
            imageUrl: _imageUrl,
            size: widget.size,
            premiumFrame: widget.isActivePaidMember,
          ),
        ),
        if (canTap)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: IvoryColors.burgundy,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: IvoryColors.gold, width: 1.2),
                ),
              ),
              child: Icon(
                widget.isActivePaidMember
                    ? Icons.photo_camera_outlined
                    : Icons.delete_outline,
                size: 13,
                color: IvoryColors.gold,
              ),
            ),
          ),
        if (_busy)
          Positioned.fill(
            child: ClipOval(
              child: Container(
                color: IvoryColors.burgundy.withValues(alpha: 0.5),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: IvoryColors.gold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// END OF FILE - lib/widgets/profile_photo_editor.dart

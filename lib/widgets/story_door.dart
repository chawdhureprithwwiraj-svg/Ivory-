import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/ivory_theme.dart';

/// ============================================================
/// IVORY - THE STORY DOOR
///
/// The house's strongest loop: members leave stories at the
/// door, free forever; the ones that move her are produced in
/// her voice with the member's name stamped on them. The band
/// lives on the home screen; the counter of produced stories
/// is the bait.
/// ============================================================

class StoryDoorBand extends StatefulWidget {
  const StoryDoorBand({super.key});

  @override
  State<StoryDoorBand> createState() => _StoryDoorBandState();
}

class _StoryDoorBandState extends State<StoryDoorBand> {
  int _tally = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dynamic n =
          await Supabase.instance.client.rpc('door_tally');
      if (!mounted) return;
      setState(() => _tally = (n as num?)?.toInt() ?? 0);
    } catch (_) {
      // The band still stands without its counter.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[IvoryColors.surfaceWarm, IvoryColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IvoryColors.hairlineStrong, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🪶', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'THE DOOR FOR YOUR STORY',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: IvoryTheme.displayFont,
                fontStyle: FontStyle.italic,
                fontSize: 13.8,
                height: 1.55,
                color: IvoryColors.textSoft,
              ),
              children: <TextSpan>[
                const TextSpan(
                  text: 'Drop your story here. If it moves me, I produce '
                      'it - in my own voice, my own writing, and ',
                ),
                TextSpan(
                  text: 'your name',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' stamped on it '),
                TextSpan(
                  text: 'forever',
                  style: TextStyle(
                    color: IvoryColors.burgundy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: ', for every member to see.',
                ),
              ],
            ),
          ),
          if (_tally > 0) ...<Widget>[
            const SizedBox(height: 7),
            Text(
              _tally == 1
                  ? '1 story has already become Ivory’s voice'
                  : '$_tally stories have already become Ivory’s voice',
              style: TextStyle(
                fontSize: 11.5,
                color: IvoryColors.textFaint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: IvoryColors.hairlineStrong, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openSheet(context),
              child: const Text('I READ EVERYTHING'),
            ),
          ),
        ],
      ),
    );
  }
}

void _openSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DoorSheet(),
  );
}

class _DoorSheet extends StatefulWidget {
  const _DoorSheet();

  @override
  State<_DoorSheet> createState() => _DoorSheetState();
}

class _DoorSheetState extends State<_DoorSheet> {
  final TextEditingController _body = TextEditingController();
  final TextEditingController _credit = TextEditingController();
  bool _busy = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    _credit.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _body.text.trim();
    if (text.length < 20) {
      setState(() => _error =
          'A few more lines - I need enough to feel the story.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('story_submissions').insert(
        <String, dynamic>{
          'member_id': Supabase.instance.client.auth.currentUser?.id,
          'body': text,
          'credit_name':
              _credit.text.trim().isEmpty ? null : _credit.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: IvoryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IvoryColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_done) ...<Widget>[
                const Center(
                    child: Text('🪶', style: TextStyle(fontSize: 44))),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'It is through the door.',
                    style: TextStyle(
                      fontFamily: IvoryTheme.displayFont,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: IvoryColors.burgundy,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'I read everything.',
                    style:
                        TextStyle(fontSize: 13, color: IvoryColors.textSoft),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE'),
                ),
              ] else ...<Widget>[
                Text('The door is open.',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Yours, or one you carry. Free, always.',
                  style: TextStyle(fontSize: 13, color: IvoryColors.textSoft),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _body,
                  maxLength: 1200,
                  maxLines: 7,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                  decoration: const InputDecoration(
                    labelText: 'Your story',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _credit,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Name to stamp on it (optional)',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anonymous is fine - I will write "from the door".',
                  style:
                      TextStyle(fontSize: 11.5, color: IvoryColors.textFaint),
                ),
                const SizedBox(height: 14),
                if (_error != null) ...<Widget>[
                  Text(_error!,
                      style: TextStyle(
                          fontSize: 12.5, color: IvoryColors.danger)),
                  const SizedBox(height: 8),
                ],
                IvoryGradientButton(
                  label: 'LEAVE IT AT THE DOOR',
                  icon: Icons.door_front_door_outlined,
                  busy: _busy,
                  onPressed: _busy ? null : _send,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// END OF FILE - lib/widgets/story_door.dart

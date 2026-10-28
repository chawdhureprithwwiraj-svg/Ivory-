/// The browser hand of film prime: a hidden, muted video element asks
/// for the film at idle; the browser keeps the bytes in its media
/// cache, and the real opening later finds them already at home.
library;

import 'dart:html' as h; // ignore: avoid_web_libraries_in_flutter

Future<void> filmPrime(String key) async {
  if (key.isEmpty) return;
  try {
    final h.VideoElement v = h.VideoElement()
      ..src = key
      ..preload = 'auto'
      ..muted = true;
    v.load();
  } catch (_) {}
}

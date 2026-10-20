import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// ============================================================
/// IVORY - THE PREMIUM ASSET FINDER
///
/// The owner's own pictures and sounds live in `assets/premium/`.
/// This finds one by a word in its file name, so a small change in a
/// file name or a sub-folder never breaks the app. If a file is not
/// there, the answer is simply null and the caller keeps its painted
/// look (or stays silent). Nothing here can throw.
/// ============================================================
class PremiumAssets {
  PremiumAssets._();

  static Future<List<String>>? _all;
  static final Map<String, Future<String?>> _paths = <String, Future<String?>>{};
  static final Map<String, Future<ui.Image?>> _images =
      <String, Future<ui.Image?>>{};

  static Future<List<String>> _list() => _all ??= _scan();

  static Future<List<String>> _scan() async {
    try {
      final AssetManifest m = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      );
      return m.listAssets().toList();
    } catch (_) {
      return <String>[];
    }
  }

  /// The asset path whose FILE NAME contains every word in [words]
  /// and ends with one of [exts]; null if there is none.
  static Future<String?> find(String id, List<String> words, List<String> exts) {
    return _paths[id] ??= _find(words, exts);
  }

  static Future<String?> _find(List<String> words, List<String> exts) async {
    final List<String> all = await _list();
    for (final String a in all) {
      final String l = a.toLowerCase();
      final String name = l.substring(l.lastIndexOf('/') + 1);
      bool ext = false;
      for (final String e in exts) {
        if (name.endsWith(e)) ext = true;
      }
      if (!ext) continue;
      bool hit = true;
      for (final String w in words) {
        if (!name.contains(w)) hit = false;
      }
      if (hit) return a;
    }
    return null;
  }

  /// A picture, decoded once at about [width] pixels wide.
  static Future<ui.Image?> image(
    String id,
    List<String> words, {
    int width = 640,
  }) {
    return _images[id] ??= _image(id, words, width);
  }

  static Future<ui.Image?> _image(
    String id,
    List<String> words,
    int width,
  ) async {
    try {
      final String? p = await find(id, words, const <String>['.png', '.webp']);
      if (p == null) return null;
      final ByteData d = await rootBundle.load(p);
      final ui.Codec codec = await ui.instantiateImageCodec(
        d.buffer.asUint8List(),
        targetWidth: width,
      );
      final ui.FrameInfo f = await codec.getNextFrame();
      return f.image;
    } catch (_) {
      return null;
    }
  }
}

// END OF FILE - lib/widgets/premium_assets.dart

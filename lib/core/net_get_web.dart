import 'dart:html' as html;
import 'dart:typed_data';

/// The browser's hands for the wire.
Future<String> netGet(String url) async {
  final html.HttpRequest req =
      await html.HttpRequest.request(url, method: 'GET');
  return req.responseText ?? '';
}

Future<int> netPut(String url, Uint8List bytes, String contentType) async {
  final html.HttpRequest req = await html.HttpRequest.request(
    url,
    method: 'PUT',
    requestHeaders: <String, String>{'Content-Type': contentType},
    sendData: bytes,
  );
  final int code = req.status ?? 0;
  return code;
}

Future<Uint8List> sourceBytes(String? path, Uint8List? held) async {
  if (held != null) return held;
  throw StateError(
      'The web holds picked bytes in memory; nothing was held.');
}

Future<int> netPutStream(String url, Uint8List bytes, String contentType,
    void Function(double progress) onProgress) async {
  final html.HttpRequest req = html.HttpRequest();
  req.open('PUT', url);
  req.setRequestHeader('Content-Type', contentType);
  req.upload.onProgress.listen((html.ProgressEvent e) {
    final int? total = e.total;
    final int? loaded = e.loaded;
    if (total != null && total > 0 && loaded != null) {
      onProgress(loaded / total);
    }
  });
  final Future<html.ProgressEvent> done = req.onLoad.first;
  req.send(bytes);
  await done;
  onProgress(1);
  final int code = req.status ?? 0;
  return code;
}

// END OF FILE - lib/core/net_get_web.dart

/// CC.242: a JSON POST for the house's own doors, same origin, so the
/// browser never has to preflight anything.
Future<String> netPostJson(
  String url,
  String body,
  Map<String, String> headers,
) async {
  final html.HttpRequest req = await html.HttpRequest.request(
    url,
    method: 'POST',
    requestHeaders: <String, String>{
      'Content-Type': 'application/json',
      ...headers,
    },
    sendData: body,
  );
  return req.responseText ?? '';
}

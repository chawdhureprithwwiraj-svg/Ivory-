import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The phone's hands for the wire.
Future<String> netGet(String url) async {
  final HttpClient client = HttpClient();
  try {
    client.connectionTimeout = const Duration(seconds: 20);
    final HttpClientRequest req = await client.getUrl(Uri.parse(url));
    req.headers.set('User-Agent', 'ivory-house');
    final HttpClientResponse res = await req.close();
    return await res.transform(const SystemEncoding().decoder).join();
  } finally {
    client.close(force: true);
  }
}

Future<int> netPut(String url, Uint8List bytes, String contentType) async {
  final HttpClient hc = HttpClient();
  hc.connectionTimeout = const Duration(seconds: 30);
  try {
    final HttpClientRequest req = await hc.openUrl('PUT', Uri.parse(url));
    req.headers.set('Content-Type', contentType);
    req.contentLength = bytes.length;
    req.persistentConnection = false;
    req.add(bytes);
    final HttpClientResponse res = await req.close();
    await res.drain<void>();
    return res.statusCode;
  } finally {
    hc.close(force: true);
  }
}

Future<Uint8List> sourceBytes(String? path, Uint8List? held) async {
  if (held != null) return held;
  if (path == null) {
    throw StateError('The phone has already cleared that pick.');
  }
  return File(path).readAsBytes();
}

Future<int> netPutStream(String url, Uint8List bytes, String contentType,
    void Function(double progress) onProgress) async {
  final HttpClient hc = HttpClient();
  hc.connectionTimeout = const Duration(seconds: 30);
  try {
    final HttpClientRequest req = await hc.openUrl('PUT', Uri.parse(url));
    req.headers.set('Content-Type', contentType);
    req.contentLength = bytes.length;
    req.persistentConnection = false;
    const int slice = 256 * 1024;
    int sent = 0;
    double last = 0;
    while (sent < bytes.length) {
      final int end =
          (sent + slice) > bytes.length ? bytes.length : sent + slice;
      req.add(bytes.sublist(sent, end));
      sent = end;
      final double p = bytes.isEmpty ? 1 : sent / bytes.length;
      if (p - last >= 0.04 || sent == bytes.length) {
        last = p;
        onProgress(p);
      }
    }
    final HttpClientResponse res = await req.close();
    final int code = res.statusCode;
    await res.drain<void>();
    return code;
  } finally {
    hc.close(force: true);
  }
}

// END OF FILE - lib/core/net_get_io.dart

/// CC.242: a JSON POST for the house's own doors. Used in the browser
/// to reach /api/r2-vault on the same origin, where no CORS check can
/// stand between the admin and the Vault.
Future<String> netPostJson(
  String url,
  String body,
  Map<String, String> headers,
) async {
  final HttpClient hc = HttpClient();
  hc.connectionTimeout = const Duration(seconds: 30);
  try {
    final HttpClientRequest req = await hc.postUrl(Uri.parse(url));
    req.headers.set('Content-Type', 'application/json');
    headers.forEach(req.headers.set);
    final List<int> bytes = utf8.encode(body);
    req.contentLength = bytes.length;
    req.add(bytes);
    final HttpClientResponse res = await req.close();
    return await res.transform(utf8.decoder).join();
  } finally {
    hc.close(force: true);
  }
}

/// The twin's two hands for the wire: fetch a body, PUT a body, and
/// read bytes from a picked path. The phone uses dart:io; the browser
/// uses its own HttpRequest. Neither world sees the other's hands.
export 'net_get_io.dart' if (dart.library.html) 'net_get_web.dart';

// The four hands of the wire - netGet, netPut, netPutStream and
// sourceBytes - live in the two world files this facade exports.
// A facade declares nothing; it only opens the right door.

// END OF FILE - lib/core/net_get.dart

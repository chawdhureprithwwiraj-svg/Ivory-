/// CC.241: the house warms its films before a member asks for them.
/// On the phone this hand rests (the APK ships films inside itself);
/// in the browser it lets a hidden video element pull each film into
/// the media cache at idle, so the first opening never waits on wire.
library;

export 'film_prime_io.dart' if (dart.library.html) 'film_prime_web.dart';

// END OF FILE - lib/core/film_prime.dart

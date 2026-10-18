/// ============================================================
/// THE LANGUAGES IVORY CAN SPEAK (built in, works offline)
///
/// Each language has its name in its own script, plus the two lines the
/// language screen needs before any word pack can be downloaded: the
/// heading ("Choose your language") and the Continue button.
///
/// Which of these are switched ON for members is decided in the database
/// (Admin, TRANSLATE). This list only says how to show them.
/// English is the default and the fallback for every missing word.
/// ============================================================
class LangInfo {
  const LangInfo(
    this.code,
    this.native,
    this.english,
    this.heading,
    this.go, {
    this.rtl = false,
    this.defaultOn = false,
  });

  /// `en`, `hi`, `bn`, `hi-Latn` (Hinglish), `bn-Latn` (Banglish) ...
  final String code;
  final String native;
  final String english;
  final String heading;
  final String go;
  final bool rtl;
  final bool defaultOn;
}

const List<LangInfo> kLangs = <LangInfo>[
  LangInfo('en', 'English', 'English', 'Choose your language', 'Continue',
      defaultOn: true),
  LangInfo('hi', 'हिन्दी', 'Hindi', 'अपनी भाषा चुनें', 'आगे बढ़ें',
      defaultOn: true),
  LangInfo('hi-Latn', 'Hinglish', 'Hindi in English letters',
      'Apni bhasha chunein', 'Aage badhein',
      defaultOn: true),
  LangInfo('bn', 'বাংলা', 'Bengali', 'আপনার ভাষা বেছে নিন', 'এগিয়ে যান',
      defaultOn: true),
  LangInfo('bn-Latn', 'Banglish', 'Bengali in English letters',
      'Apnar bhasha bachun', 'Egiye jan',
      defaultOn: true),
  LangInfo('ta', 'தமிழ்', 'Tamil', 'உங்கள் மொழியைத் தேர்ந்தெடுங்கள்', 'தொடரவும்'),
  LangInfo('te', 'తెలుగు', 'Telugu', 'మీ భాషను ఎంచుకోండి', 'కొనసాగించండి'),
  LangInfo('mr', 'मराठी', 'Marathi', 'तुमची भाषा निवडा', 'पुढे जा'),
  LangInfo('gu', 'ગુજરાતી', 'Gujarati', 'તમારી ભાષા પસંદ કરો', 'આગળ વધો'),
  LangInfo('kn', 'ಕನ್ನಡ', 'Kannada', 'ನಿಮ್ಮ ಭಾಷೆಯನ್ನು ಆರಿಸಿ', 'ಮುಂದುವರಿಸಿ'),
  LangInfo('ml', 'മലയാളം', 'Malayalam', 'നിങ്ങളുടെ ഭാഷ തിരഞ്ഞെടുക്കുക', 'തുടരുക'),
  LangInfo('pa', 'ਪੰਜਾਬੀ', 'Punjabi', 'ਆਪਣੀ ਭਾਸ਼ਾ ਚੁਣੋ', 'ਅੱਗੇ ਵਧੋ'),
  LangInfo('or', 'ଓଡ଼ିଆ', 'Odia', 'ଆପଣଙ୍କ ଭାଷା ବାଛନ୍ତୁ', 'ଆଗକୁ ଯାଆନ୍ତୁ'),
  LangInfo('as', 'অসমীয়া', 'Assamese', 'আপোনাৰ ভাষা বাছক', 'আগবাঢ়ক'),
  LangInfo('ur', 'اردو', 'Urdu', 'اپنی زبان منتخب کریں', 'جاری رکھیں',
      rtl: true),
];

LangInfo langByCode(String code) {
  for (final LangInfo l in kLangs) {
    if (l.code == code) return l;
  }
  return kLangs.first;
}

bool isKnownLang(String code) {
  for (final LangInfo l in kLangs) {
    if (l.code == code) return true;
  }
  return false;
}

// END OF FILE - lib/l10n/l10n_langs.dart

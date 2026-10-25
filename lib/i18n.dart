/// Tiny two-language helper. The active language lives in [appLang] and is
/// set by the store; widgets rebuild when the store notifies.
String appLang = 'ar';

bool get isAr => appLang != 'en';

String tr(String ar, String en) => isAr ? ar : en;

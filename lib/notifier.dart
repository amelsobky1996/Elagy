import 'dart:js_interop';

// Thin bridge to the helpers defined in web/index.html.

@JS('elagyNotify')
external void _notify(JSString title, JSString body, JSString tag);

@JS('elagyPermission')
external JSString _permission();

@JS('elagyRequestPermission')
external JSPromise<JSString> _requestPermission();

@JS('elagyBeep')
external void _beep();

@JS('elagyIsStandalone')
external JSBoolean _isStandalone();

class WebNotifier {
  static String permission() {
    try {
      return _permission().toDart;
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<String> request() async {
    try {
      final r = await _requestPermission().toDart;
      return r.toDart;
    } catch (_) {
      return 'unsupported';
    }
  }

  static void show(String title, String body, String tag) {
    try {
      _notify(title.toJS, body.toJS, tag.toJS);
    } catch (_) {}
  }

  static void beep() {
    try {
      _beep();
    } catch (_) {}
  }

  static bool isStandalone() {
    try {
      return _isStandalone().toDart;
    } catch (_) {
      return false;
    }
  }
}

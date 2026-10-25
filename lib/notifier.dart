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

@JS('elagyIsIos')
external JSBoolean _isIos();

@JS('elagyPickImage')
external JSPromise<JSString> _pickImage(JSBoolean camera);

@JS('elagyPickText')
external JSPromise<JSString> _pickText();

@JS('elagyDownload')
external void _download(JSString name, JSString text);

@JS('elagyCanInstall')
external JSBoolean _canInstall();

@JS('elagyInstall')
external JSPromise<JSBoolean> _install();

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

  static bool isIos() {
    try {
      return _isIos().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Opens the gallery (or camera) and returns a small square JPEG data URL,
  /// or an empty string when cancelled.
  static Future<String> pickImage({bool camera = false}) async {
    try {
      final r = await _pickImage(camera.toJS).toDart;
      return r.toDart;
    } catch (_) {
      return '';
    }
  }

  /// Opens a file picker for a backup file and returns its text ('' = cancelled).
  static Future<String> pickText() async {
    try {
      final r = await _pickText().toDart;
      return r.toDart;
    } catch (_) {
      return '';
    }
  }

  static void download(String name, String text) {
    try {
      _download(name.toJS, text.toJS);
    } catch (_) {}
  }

  static bool canInstall() {
    try {
      return _canInstall().toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> install() async {
    try {
      final r = await _install().toDart;
      return r.toDart;
    } catch (_) {
      return false;
    }
  }
}

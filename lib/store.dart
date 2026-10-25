import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fmt.dart';
import 'i18n.dart';
import 'models.dart';
import 'notifier.dart';

/// Holds people + medicines, persists them and fires reminders.
class AppStore extends ChangeNotifier {
  static const _kPeople = 'elagy.people';
  static const _kMeds = 'elagy.meds';
  static const _kLang = 'elagy.lang';
  static const _kTheme = 'elagy.theme';
  static const _kSound = 'elagy.sound';

  /// 'ar' or 'en'
  String lang = 'ar';

  /// 'system', 'light' or 'dark'
  String themeMode = 'system';

  bool sound = true;

  /// UI state kept across theme/language rebuilds.
  bool splashShown = false;
  int homeTab = 0;

  final List<Person> people = [];
  final List<Medicine> meds = [];
  bool loaded = false;
  String permission = 'default';

  /// Dose that just became due while the app is open (shown as an in-app banner).
  Dose? alert;

  Timer? _ticker;
  SharedPreferences? _prefs;
  final _rand = Random();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!.getString(_kPeople);
    final m = _prefs!.getString(_kMeds);
    lang = _prefs!.getString(_kLang) ?? 'ar';
    appLang = lang;
    themeMode = _prefs!.getString(_kTheme) ?? 'system';
    sound = _prefs!.getBool(_kSound) ?? true;
    if (p != null) {
      people.addAll((jsonDecode(p) as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>)));
    }
    if (m != null) {
      meds.addAll((jsonDecode(m) as List)
          .map((e) => Medicine.fromJson(e as Map<String, dynamic>)));
    }
    permission = WebNotifier.permission();
    loaded = true;
    check();
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => check());
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    await _prefs?.setString(
        _kPeople, jsonEncode(people.map((e) => e.toJson()).toList()));
    await _prefs?.setString(
        _kMeds, jsonEncode(meds.map((e) => e.toJson()).toList()));
  }

  String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(1 << 20).toRadixString(36)}';

  // ---------- People ----------
  Person? personById(String id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Person addPerson(String name, int color, {String? photo}) {
    final p = Person(
        id: newId(), name: name.trim(), colorIndex: color, photo: photo);
    people.add(p);
    _save();
    notifyListeners();
    return p;
  }

  void updatePerson(Person p, String name, int color, {String? photo}) {
    p.name = name.trim();
    p.colorIndex = color;
    p.photo = (photo == null || photo.isEmpty) ? null : photo;
    _save();
    notifyListeners();
  }

  void deletePerson(Person p) {
    people.removeWhere((e) => e.id == p.id);
    meds.removeWhere((m) => m.personId == p.id);
    _save();
    notifyListeners();
  }

  int nextColor() => people.length % personPalette.length;

  // ---------- Medicines ----------
  void saveMed(Medicine m) {
    final i = meds.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      meds[i] = m;
    } else {
      meds.add(m);
    }
    // Doses that were already in the past when added should not ping.
    final now = DateTime.now();
    for (final d in m.doses) {
      if (d.at.isBefore(now.subtract(const Duration(minutes: 2)))) {
        m.notified.add(d.key);
      }
    }
    _save();
    notifyListeners();
    check();
  }

  void deleteMed(Medicine m) {
    meds.removeWhere((e) => e.id == m.id);
    _save();
    notifyListeners();
  }

  void toggleTaken(Dose d) {
    if (d.med.taken.contains(d.key)) {
      d.med.taken.remove(d.key);
    } else {
      d.med.taken.add(d.key);
      d.med.notified.add(d.key);
      if (alert?.key == d.key) alert = null;
    }
    _save();
    notifyListeners();
  }

  void dismissAlert() {
    alert = null;
    notifyListeners();
  }

  List<Medicine> medsFor(String? personId) => personId == null
      ? meds
      : meds.where((m) => m.personId == personId).toList();

  List<Dose> dosesOn(DateTime day, {String? personId}) {
    final list = <Dose>[];
    for (final m in medsFor(personId)) {
      for (final d in m.doses) {
        if (sameDay(d.at, day)) list.add(d);
      }
    }
    list.sort((a, b) => a.at.compareTo(b.at));
    return list;
  }

  Dose? nextDose({String? personId}) {
    final now = DateTime.now();
    Dose? best;
    for (final m in medsFor(personId)) {
      for (final d in m.doses) {
        if (d.isTaken) continue;
        if (d.at.isBefore(now.subtract(const Duration(minutes: 90)))) continue;
        if (best == null || d.at.isBefore(best.at)) best = d;
      }
    }
    return best;
  }

  // ---------- Settings ----------
  void setLang(String v) {
    lang = v;
    appLang = v;
    _prefs?.setString(_kLang, v);
    notifyListeners();
  }

  void setThemeMode(String v) {
    themeMode = v;
    _prefs?.setString(_kTheme, v);
    notifyListeners();
  }

  void setSound(bool v) {
    sound = v;
    _prefs?.setBool(_kSound, v);
    notifyListeners();
  }

  // ---------- Data ----------
  int get activeCourses =>
      meds.where((m) => !m.isFinished(DateTime.now())).length;

  int get totalTaken => meds.fold(0, (a, m) => a + m.takenCount());

  /// Adherence over all doses that are already due (taken / due).
  double? get adherence {
    final now = DateTime.now();
    var due = 0, taken = 0;
    for (final m in meds) {
      for (final d in m.doses) {
        if (d.at.isAfter(now)) break;
        due++;
        if (d.isTaken) taken++;
      }
    }
    return due == 0 ? null : taken / due;
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'elagy',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'people': people.map((e) => e.toJson()).toList(),
        'meds': meds.map((e) => e.toJson()).toList(),
      });

  /// Replaces all data with a backup. Returns false if the file is invalid.
  bool importJson(String text) {
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (j['app'] != 'elagy') return false;
      final ps = (j['people'] as List)
          .map((e) => Person.fromJson(e as Map<String, dynamic>))
          .toList();
      final ms = (j['meds'] as List)
          .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
          .toList();
      people
        ..clear()
        ..addAll(ps);
      meds
        ..clear()
        ..addAll(ms);
      alert = null;
      _save();
      notifyListeners();
      check();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Wipes every person, medicine and reminder (settings are kept).
  Future<void> deleteAll() async {
    people.clear();
    meds.clear();
    alert = null;
    await _prefs?.remove(_kPeople);
    await _prefs?.remove(_kMeds);
    notifyListeners();
  }

  // ---------- Permissions ----------
  Future<void> requestPermission() async {
    permission = await WebNotifier.request();
    notifyListeners();
    if (permission == 'granted') {
      WebNotifier.show(
          tr('علاجي 💊', 'Elagy 💊'),
          tr('تمام! هنفكّرك بكل جرعة في ميعادها.',
              "All set! We'll remind you of every dose on time."),
          'elagy-welcome');
    }
  }

  // ---------- Reminder engine ----------
  /// Fires a notification for every dose whose time has come and that
  /// hasn't been announced yet. Doses of finished courses never fire, so
  /// notifications stop by themselves once the days are over.
  void check() {
    if (!loaded) return;
    final now = DateTime.now();
    var changed = false;
    for (final m in meds) {
      if (m.isFinished(now)) continue;
      final person = personById(m.personId);
      for (final d in m.doses) {
        if (d.at.isAfter(now)) break;
        if (m.notified.contains(d.key) || d.isTaken) continue;
        m.notified.add(d.key);
        changed = true;
        // Too old (app was closed) -> don't spam, it shows as missed.
        if (now.difference(d.at).inMinutes > 90) continue;
        _announce(d, person);
      }
    }
    if (changed) _save();
    notifyListeners();
  }

  void _announce(Dose d, Person? person) {
    final who = person?.name ?? '';
    final title = d.isLast
        ? tr('⚠️ آخر جرعة — ${d.med.name}', '⚠️ Last dose — ${d.med.name}')
        : tr('💊 ميعاد علاج${who.isEmpty ? '' : ' $who'}',
            '💊 Medicine time${who.isEmpty ? '' : ' for $who'}');
    final prefix = who.isEmpty ? '' : '$who: ';
    final body = d.isLast
        ? tr(
            '${prefix}دي آخر جرعة من ${d.med.name} (${d.med.dose}). بعدها الكورس خلص ومش هنبعت تذكيرات تاني. ألف سلامة 🌿',
            "${prefix}This is the LAST dose of ${d.med.name} (${d.med.dose}). The course is complete and reminders will stop. Get well soon 🌿")
        : tr('${d.med.name} — ${d.med.dose} • جرعة ${d.index} من ${d.total}',
            '${d.med.name} — ${d.med.dose} • dose ${d.index} of ${d.total}');
    WebNotifier.show(title, body, d.key);
    if (sound) WebNotifier.beep();
    alert = d;
  }

  /// Sends a sample notification so the user can verify everything works.
  void testNotification() {
    WebNotifier.show(tr('علاجي 💊', 'Elagy 💊'),
        tr('كده الإشعارات شغالة تمام ✅', 'Notifications are working ✅'),
        'elagy-test');
    if (sound) WebNotifier.beep();
  }
}

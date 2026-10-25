import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fmt.dart';
import 'models.dart';
import 'notifier.dart';

/// Holds people + medicines, persists them and fires reminders.
class AppStore extends ChangeNotifier {
  static const _kPeople = 'elagy.people';
  static const _kMeds = 'elagy.meds';

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

  Person addPerson(String name, int color) {
    final p = Person(id: newId(), name: name.trim(), colorIndex: color);
    people.add(p);
    _save();
    notifyListeners();
    return p;
  }

  void updatePerson(Person p, String name, int color) {
    p.name = name.trim();
    p.colorIndex = color;
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

  // ---------- Permissions ----------
  Future<void> requestPermission() async {
    permission = await WebNotifier.request();
    notifyListeners();
    if (permission == 'granted') {
      WebNotifier.show('علاجي 💊', 'تمام! هنفكّرك بكل جرعة في ميعادها.',
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
        ? '⚠️ آخر جرعة — ${d.med.name}'
        : '💊 ميعاد علاج${who.isEmpty ? '' : ' $who'}';
    final body = d.isLast
        ? '${who.isEmpty ? '' : '$who: '}دي آخر جرعة من ${d.med.name} (${d.med.dose}). بعدها الكورس خلص ومش هنبعت تذكيرات تاني. ألف سلامة 🌿'
        : '${d.med.name} — ${d.med.dose} • جرعة ${d.index} من ${d.total}';
    WebNotifier.show(title, body, d.key);
    WebNotifier.beep();
    alert = d;
  }

  /// Sends a sample notification so the user can verify everything works.
  void testNotification() {
    WebNotifier.show('علاجي 💊', 'كده الإشعارات شغالة تمام ✅', 'elagy-test');
    WebNotifier.beep();
  }
}

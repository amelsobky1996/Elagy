import 'package:flutter/material.dart';

/// Colors used for people avatars.
const personPalette = <Color>[
  Color(0xFF4FA8D8),
  Color(0xFF6CC070),
  Color(0xFFF2A14A),
  Color(0xFFB37FE0),
  Color(0xFFEF6F8C),
  Color(0xFF3DBFB0),
  Color(0xFF7C8CF8),
  Color(0xFFE5C04A),
];

class Person {
  final String id;
  String name;
  int colorIndex;
  String emoji;

  Person({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    this.emoji = '',
  });

  Color get color => personPalette[colorIndex % personPalette.length];

  String get initial {
    final t = name.trim();
    return t.isEmpty ? '؟' : t.characters.first;
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'color': colorIndex, 'emoji': emoji};

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        colorIndex: (j['color'] as num?)?.toInt() ?? 0,
        emoji: j['emoji'] as String? ?? '',
      );
}

enum MedForm { pill, syrup, injection, drops, cream, other }

extension MedFormX on MedForm {
  String get label {
    switch (this) {
      case MedForm.pill:
        return 'أقراص';
      case MedForm.syrup:
        return 'شراب';
      case MedForm.injection:
        return 'حقن';
      case MedForm.drops:
        return 'نقط';
      case MedForm.cream:
        return 'كريم';
      case MedForm.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case MedForm.pill:
        return Icons.medication_rounded;
      case MedForm.syrup:
        return Icons.local_drink_rounded;
      case MedForm.injection:
        return Icons.vaccines_rounded;
      case MedForm.drops:
        return Icons.water_drop_rounded;
      case MedForm.cream:
        return Icons.spa_rounded;
      case MedForm.other:
        return Icons.medical_services_rounded;
    }
  }
}

class Medicine {
  final String id;
  String personId;
  String name;
  String dose;
  MedForm form;
  List<String> times; // "HH:mm", sorted
  DateTime startDate; // date only
  int days;
  String note;
  final DateTime createdAt;
  Set<String> taken; // dose keys
  Set<String> notified; // dose keys

  Medicine({
    required this.id,
    required this.personId,
    required this.name,
    required this.dose,
    required this.form,
    required this.times,
    required this.startDate,
    required this.days,
    required this.createdAt,
    this.note = '',
    Set<String>? taken,
    Set<String>? notified,
  })  : taken = taken ?? <String>{},
        notified = notified ?? <String>{};

  Map<String, dynamic> toJson() => {
        'id': id,
        'personId': personId,
        'name': name,
        'dose': dose,
        'form': form.name,
        'times': times,
        'start': startDate.toIso8601String(),
        'days': days,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'taken': taken.toList(),
        'notified': notified.toList(),
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: j['id'] as String,
        personId: j['personId'] as String,
        name: j['name'] as String? ?? '',
        dose: j['dose'] as String? ?? '',
        form: MedForm.values.firstWhere(
          (f) => f.name == j['form'],
          orElse: () => MedForm.pill,
        ),
        times: (j['times'] as List).map((e) => e as String).toList(),
        startDate: DateTime.parse(j['start'] as String),
        days: (j['days'] as num).toInt(),
        note: j['note'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        taken: ((j['taken'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        notified: ((j['notified'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
      );

  int get totalDoses => days * times.length;

  /// All doses of the course, in chronological order.
  List<Dose> get doses {
    final sorted = [...times]..sort();
    final list = <Dose>[];
    var index = 0;
    final total = days * sorted.length;
    for (var d = 0; d < days; d++) {
      final day = DateTime(startDate.year, startDate.month, startDate.day + d);
      for (final t in sorted) {
        final parts = t.split(':');
        final at = DateTime(day.year, day.month, day.day,
            int.parse(parts[0]), int.parse(parts[1]));
        index++;
        list.add(Dose(
          med: this,
          at: at,
          index: index,
          total: total,
          dayNumber: d + 1,
        ));
      }
    }
    return list;
  }

  DateTime get endAt => doses.isEmpty ? startDate : doses.last.at;

  bool isFinished(DateTime now) => now.isAfter(endAt.add(const Duration(hours: 1)));

  int takenCount() => doses.where((d) => taken.contains(d.key)).length;

  /// The day number (1-based) of the course for [now], clamped.
  int currentDay(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(startDate).inDays + 1;
    return diff.clamp(0, days);
  }
}

class Dose {
  final Medicine med;
  final DateTime at;
  final int index; // 1-based
  final int total;
  final int dayNumber;

  Dose({
    required this.med,
    required this.at,
    required this.index,
    required this.total,
    required this.dayNumber,
  });

  String get key => '${med.id}@${at.toIso8601String()}';
  bool get isLast => index == total;
  bool get isTaken => med.taken.contains(key);
}

enum DoseState { taken, due, missed, upcoming }

DoseState doseState(Dose d, DateTime now) {
  if (d.isTaken) return DoseState.taken;
  if (now.isBefore(d.at)) return DoseState.upcoming;
  if (now.difference(d.at).inMinutes <= 90) return DoseState.due;
  return DoseState.missed;
}

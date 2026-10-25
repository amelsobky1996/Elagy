import 'package:flutter/material.dart';

import '../fmt.dart';
import '../i18n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'people_tab.dart';

class MedFormScreen extends StatefulWidget {
  final Medicine? existing;
  const MedFormScreen({super.key, this.existing});

  @override
  State<MedFormScreen> createState() => _MedFormScreenState();
}

class _MedFormScreenState extends State<MedFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _note;
  String? _personId;
  MedForm _form = MedForm.pill;
  List<String> _times = [];
  int _days = 7;
  DateTime _start = dateOnly(DateTime.now());
  bool _tried = false;

  static const _doseSuggestionsAr = {
    MedForm.pill: ['قرص واحد', 'نص قرص', 'قرصين', 'كبسولة'],
    MedForm.syrup: ['5 مل', '7.5 مل', '10 مل', 'معلقة صغيرة'],
    MedForm.injection: ['حقنة واحدة', 'نص أمبول', 'أمبول'],
    MedForm.drops: ['نقطة', 'نقطتين', '3 نقط', '5 نقط'],
    MedForm.cream: ['دهان خفيف', 'مرتين دهان'],
    MedForm.other: ['جرعة واحدة', 'بخة', 'بختين', 'كيس'],
  };
  static const _doseSuggestionsEn = {
    MedForm.pill: ['1 tablet', '½ tablet', '2 tablets', '1 capsule'],
    MedForm.syrup: ['5 ml', '7.5 ml', '10 ml', '1 teaspoon'],
    MedForm.injection: ['1 injection', '½ ampoule', '1 ampoule'],
    MedForm.drops: ['1 drop', '2 drops', '3 drops', '5 drops'],
    MedForm.cream: ['Thin layer', 'Apply twice'],
    MedForm.other: ['1 dose', '1 puff', '2 puffs', '1 sachet'],
  };
  Map<MedForm, List<String>> get _doseSuggestions =>
      isAr ? _doseSuggestionsAr : _doseSuggestionsEn;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _dose = TextEditingController(text: e?.dose ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _personId = e.personId;
      _form = e.form;
      _times = [...e.times]..sort();
      _days = e.days;
      _start = e.startDate;
    } else {
      final now = DateTime.now();
      // Sensible default: next round hour.
      final h = (now.hour + 1) % 24;
      _times = [hm(h, 0)];
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.read(context);
    if (_personId == null && store.people.isNotEmpty) {
      _personId = store.people.first.id;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _addTime({int? replaceIndex}) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (replaceIndex != null) {
      final p = _times[replaceIndex].split(':');
      initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } else if (_times.isNotEmpty) {
      final p = _times.last.split(':');
      initial = TimeOfDay(hour: (int.parse(p[0]) + 6) % 24, minute: int.parse(p[1]));
    }
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: tr('اختار ميعاد الجرعة', 'Pick dose time'),
      cancelText: tr('إلغاء', 'Cancel'),
      confirmText: tr('تمام', 'OK'),
    );
    if (t == null) return;
    final v = hm(t.hour, t.minute);
    setState(() {
      if (replaceIndex != null) _times.removeAt(replaceIndex);
      if (!_times.contains(v)) _times.add(v);
      _times.sort();
    });
  }

  void _applyEvery(int hours) {
    var base = const TimeOfDay(hour: 8, minute: 0);
    if (_times.isNotEmpty) {
      final p = _times.first.split(':');
      base = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    final n = 24 ~/ hours;
    setState(() {
      _times = [
        for (var i = 0; i < n; i++) hm((base.hour + i * hours) % 24, base.minute)
      ]..sort();
    });
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: tr('تاريخ البداية', 'Start date'),
      cancelText: tr('إلغاء', 'Cancel'),
      confirmText: tr('تمام', 'OK'),
    );
    if (d != null) setState(() => _start = dateOnly(d));
  }

  Future<void> _addPerson() async {
    final p = await showPersonSheet(context);
    if (p != null) setState(() => _personId = p.id);
  }

  void _save() {
    setState(() => _tried = true);
    final store = StoreScope.read(context);
    if (_personId == null) {
      _snack(tr('اختار الشخص الأول', 'Choose a person first'));
      return;
    }
    if (_name.text.trim().isEmpty) {
      _snack(tr('اكتب اسم الدوا', 'Enter the medicine name'));
      return;
    }
    if (_dose.text.trim().isEmpty) {
      _snack(tr('اكتب الجرعة', 'Enter the dose'));
      return;
    }
    if (_times.isEmpty) {
      _snack(tr('ضيف ميعاد واحد على الأقل', 'Add at least one time'));
      return;
    }
    final e = widget.existing;
    final m = Medicine(
      id: e?.id ?? store.newId(),
      personId: _personId!,
      name: _name.text.trim(),
      dose: _dose.text.trim(),
      form: _form,
      times: [..._times]..sort(),
      startDate: _start,
      days: _days,
      note: _note.text.trim(),
      createdAt: e?.createdAt ?? DateTime.now(),
      taken: e?.taken,
      notified: e == null ? null : {...e.notified},
    );
    store.saveMed(m);
    final p = store.personById(_personId!);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e == null
          ? tr('تم! هنفكّر ${p?.name ?? ''} بـ ${m.name} لمدة ${daysLabel(m.days)} ✅',
              "Done! We'll remind ${p?.name ?? ''} to take ${m.name} for ${daysLabel(m.days)} ✅")
          : tr('تم حفظ التعديلات ✅', 'Changes saved ✅')),
    ));
    Navigator.pop(context, true);
  }

  void _snack(String s) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();

    // Preview of the course
    Medicine? preview;
    if (_times.isNotEmpty) {
      preview = Medicine(
        id: 'p',
        personId: '',
        name: '',
        dose: '',
        form: _form,
        times: _times,
        startDate: _start,
        days: _days,
        createdAt: now,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? tr('دوا جديد', 'New medicine') : tr('تعديل الدوا', 'Edit medicine'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        children: [
          _Card(
            icon: Icons.person_rounded,
            title: tr('لمين الدوا؟', 'For whom?'),
            child: SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in store.people)
                    _PersonOption(
                      person: p,
                      selected: _personId == p.id,
                      onTap: () => setState(() => _personId = p.id),
                    ),
                  _PersonOption(
                    person: null,
                    selected: false,
                    onTap: _addPerson,
                  ),
                ],
              ),
            ),
          ),
          _Card(
            icon: Icons.medication_rounded,
            title: tr('الدوا', 'Medicine'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: tr('اسم الدوا (مثلًا: بانادول)', 'Medicine name (e.g. Panadol)'),
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    errorText: _tried && _name.text.trim().isEmpty
                        ? tr('مطلوب', 'Required')
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                Text(tr('النوع', 'Type'),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in MedForm.values)
                      _ChoiceChip(
                        label: f.label,
                        icon: f.icon,
                        selected: _form == f,
                        onTap: () => setState(() => _form = f),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _Card(
            icon: Icons.science_rounded,
            title: tr('الجرعة', 'Dose'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _dose,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: tr('مثلًا: قرص واحد بعد الأكل', 'e.g. 1 tablet after meals'),
                    prefixIcon: const Icon(Icons.local_pharmacy_rounded),
                    errorText: _tried && _dose.text.trim().isEmpty
                        ? tr('مطلوب', 'Required')
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _doseSuggestions[_form]!)
                      _ChoiceChip(
                        label: s,
                        selected: _dose.text == s,
                        onTap: () => setState(() => _dose.text = s),
                      ),
                  ],
                ),
              ],
            ),
          ),
          _Card(
            icon: Icons.alarm_rounded,
            title: tr('المواعيد', 'Times'),
            subtitle: timesPerDayLabel(_times.length),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in [
                      (tr('مرة يوميًا', 'Once daily'), 24),
                      (tr('كل 12 ساعة', 'Every 12h'), 12),
                      (tr('كل 8 ساعات', 'Every 8h'), 8),
                      (tr('كل 6 ساعات', 'Every 6h'), 6),
                    ])
                      _ChoiceChip(
                        label: e.$1,
                        selected: _times.length == 24 ~/ e.$2,
                        onTap: () => _applyEvery(e.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _times.length; i++)
                      _TimeChip(
                        label: fmtHm(_times[i]),
                        onTap: () => _addTime(replaceIndex: i),
                        onRemove: () => setState(() => _times.removeAt(i)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded,
                          color: AppColors.sky, size: 20),
                      label: Text(tr('ميعاد', 'Time'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.sky),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      onPressed: _addTime,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tr('دوس على أي ميعاد عشان تغيّره', 'Tap a time to change it'),
                    style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          _Card(
            icon: Icons.date_range_rounded,
            title: tr('المدة', 'Duration'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _RoundBtn(
                      icon: Icons.remove_rounded,
                      onTap: _days > 1 ? () => setState(() => _days--) : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('$_days',
                              style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1)),
                          Text(dayUnit(_days),
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    _RoundBtn(
                      icon: Icons.add_rounded,
                      onTap: _days < 365 ? () => setState(() => _days++) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in [3, 5, 7, 10, 14, 30])
                      _ChoiceChip(
                        label: daysLabel(d),
                        selected: _days == d,
                        onTap: () => setState(() => _days = d),
                      ),
                  ],
                ),
                Divider(height: 28, color: AppColors.line),
                Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        color: AppColors.muted),
                    const SizedBox(width: 8),
                    Text(tr('يبدأ', 'Starts'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    _ChoiceChip(
                      label: tr('النهارده', 'Today'),
                      selected: sameDay(_start, now),
                      onTap: () => setState(() => _start = dateOnly(now)),
                    ),
                    const SizedBox(width: 6),
                    _ChoiceChip(
                      label: tr('بكره', 'Tomorrow'),
                      selected: sameDay(_start, now.add(const Duration(days: 1))),
                      onTap: () => setState(() => _start =
                          dateOnly(now.add(const Duration(days: 1)))),
                    ),
                    IconButton(
                      onPressed: _pickStart,
                      icon: const Icon(Icons.calendar_month_rounded,
                          color: AppColors.sky),
                    ),
                  ],
                ),
                if (!sameDay(_start, now) &&
                    !sameDay(_start, now.add(const Duration(days: 1))))
                  Text(tr('من ${fullDate(_start)}', 'From ${fullDate(_start)}'),
                      style: TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          _Card(
            icon: Icons.sticky_note_2_rounded,
            title: tr('ملاحظة (اختياري)', 'Note (optional)'),
            child: TextField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                  hintText: tr('مثلًا: بعد الأكل، مع كوباية مية',
                      'e.g. after meals, with a glass of water')),
            ),
          ),
          if (preview != null) _Summary(preview: preview, now: now),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(widget.existing == null ? tr('حفظ التذكير', 'Save reminder') : tr('حفظ التعديلات', 'Save changes')),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final Medicine preview;
  final DateTime now;
  const _Summary({required this.preview, required this.now});

  @override
  Widget build(BuildContext context) {
    final doses = preview.doses;
    final upcoming = doses.where((d) => d.at.isAfter(now)).length;
    final last = doses.last;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr(
                  'هيتبعت $upcoming تذكير (${doses.length} جرعة على ${daysLabel(preview.days)}). '
                      'آخر جرعة ${relativeDay(last.at, now)} الساعة ${fmtDateTime(last.at)} '
                      'وهنقولك إنها آخر جرعة، وبعدها التذكيرات هتقف لوحدها.',
                  '$upcoming reminders will be sent (${doses.length} doses over ${daysLabel(preview.days)}). '
                      'The last dose is ${relativeDay(last.at, now).toLowerCase()} at ${fmtDateTime(last.at)}; '
                      "we'll tell you it's the last one, then reminders stop automatically."),
              style: const TextStyle(height: 1.7, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.skyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.sky),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class _PersonOption extends StatelessWidget {
  final Person? person;
  final bool selected;
  final VoidCallback onTap;
  const _PersonOption(
      {required this.person, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        margin: const EdgeInsetsDirectional.only(end: 8),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? (person?.color ?? AppColors.sky)
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: person == null
                  ? Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.skyLight,
                        border: Border.all(color: AppColors.sky),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.sky),
                    )
                  : PersonAvatar(person: person, size: 50),
            ),
            const SizedBox(height: 4),
            Text(
              person?.name ?? tr('جديد', 'New'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.ink : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 17,
                    color: selected ? Colors.white : AppColors.sky),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.ink,
                  )),
            ],
          ),
        ),
      );
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _TimeChip(
      {required this.label, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4FA8D8), Color(0xFF2E7DB5)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 6, 8),
                child: Row(
                  children: [
                    const Icon(Icons.alarm_rounded,
                        color: Colors.white, size: 17),
                    const SizedBox(width: 5),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(2, 8, 10, 8),
                child:
                    Icon(Icons.close_rounded, color: Colors.white70, size: 17),
              ),
            ),
          ],
        ),
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: onTap == null ? AppColors.line : AppColors.skyLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: AppColors.ink),
          ),
        ),
      );
}

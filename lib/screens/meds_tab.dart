import 'package:flutter/material.dart';

import '../fmt.dart';
import '../i18n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';
import 'med_form.dart';

class MedsTab extends StatefulWidget {
  final VoidCallback onAdd;
  const MedsTab({super.key, required this.onAdd});

  @override
  State<MedsTab> createState() => _MedsTabState();
}

class _MedsTabState extends State<MedsTab> {
  String? _person;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    if (_person != null && store.personById(_person!) == null) _person = null;
    final all = store.medsFor(_person);
    final active = all.where((m) => !m.isFinished(now)).toList()
      ..sort((a, b) => a.endAt.compareTo(b.endAt));
    final done = all.where((m) => m.isFinished(now)).toList()
      ..sort((a, b) => b.endAt.compareTo(a.endAt));

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        TabHeader(
          subtitle: tr('${active.length} كورس شغال', '${active.length} active courses'),
          title: tr('الأدوية', 'Medicines'),
          trailing: logoBadge(),
        ),
        PersonFilterBar(
          people: store.people,
          selected: _person,
          onChanged: (p) => setState(() => _person = p),
        ),
        const SizedBox(height: 8),
        if (all.isEmpty)
          EmptyState(
            icon: Icons.medication_liquid_rounded,
            title: tr('مفيش أدوية هنا', 'No medicines here'),
            subtitle: tr('ضيف دوا وحدد مواعيده وعدد الأيام.', 'Add a medicine with its times and number of days.'),
            action: tr('إضافة دوا', 'Add medicine'),
            onAction: widget.onAdd,
          ),
        if (active.isNotEmpty) ...[
          _Section(tr('شغالة دلوقتي', 'Active now')),
          for (final m in active) _MedCard(med: m, finished: false),
        ],
        if (done.isNotEmpty) ...[
          _Section(tr('كورسات خلصت ✅', 'Completed courses ✅')),
          for (final m in done) _MedCard(med: m, finished: true),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.muted,
                fontSize: 14)),
      );
}

class _MedCard extends StatelessWidget {
  final Medicine med;
  final bool finished;
  const _MedCard({required this.med, required this.finished});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final person = store.personById(med.personId);
    final now = DateTime.now();
    final total = med.totalDoses;
    final taken = med.takenCount();
    final remaining =
        med.doses.where((d) => d.at.isAfter(now) && !d.isTaken).length;
    final day = med.currentDay(now);
    final notStarted = now.isBefore(med.doses.isEmpty ? now : med.doses.first.at);
    final progress = finished
        ? 1.0
        : (med.days == 0 ? 0.0 : (day / med.days).clamp(0.0, 1.0));
    final color = person?.color ?? AppColors.sky;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: cardDeco(),
      child: Opacity(
        opacity: finished ? 0.7 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(med.form.icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            PersonAvatar(person: person, size: 20),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${person?.name ?? ''} • ${med.dose}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: AppColors.muted),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => MedFormScreen(existing: med)));
                      } else if (v == 'delete') {
                        final ok = await confirmDialog(
                          context,
                          title: tr('حذف ${med.name}؟', 'Delete ${med.name}?'),
                          message: tr('هيتمسح الدوا وكل تذكيراته.',
                              'The medicine and all its reminders will be removed.'),
                        );
                        if (ok) store.deleteMed(med);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          const Icon(Icons.edit_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(tr('تعديل', 'Edit')),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.red),
                          const SizedBox(width: 10),
                          Text(tr('حذف', 'Delete'),
                              style: const TextStyle(color: AppColors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in ([...med.times]..sort()))
                    Pill(
                      text: fmtHm(t),
                      color: AppColors.ink,
                      bg: AppColors.skyLight,
                      icon: Icons.alarm_rounded,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    finished
                        ? tr('الكورس خلص • ${shortDate(med.endAt)}', 'Completed • ${shortDate(med.endAt)}')
                        : notStarted
                            ? tr('يبدأ ${relativeDay(med.startDate, now)}', 'Starts ${relativeDay(med.startDate, now)}')
                            : tr('يوم $day من ${med.days}', 'Day $day of ${med.days}'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    finished
                        ? tr('اتاخد $taken من $total', '$taken of $total taken')
                        : tr('فاضل $remaining جرعة', '$remaining doses left'),
                    style:
                        TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation(
                      finished ? AppColors.green : color),
                ),
              ),
              if (!finished) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 15, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      tr('آخر جرعة: ', 'Last dose: ') + '${relativeDay(med.endAt, now)} ${fmtDateTime(med.endAt)}',
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (med.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('📝 ${med.note}',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 13, height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fmt.dart';
import '../i18n.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

class TodayTab extends StatefulWidget {
  final VoidCallback onAdd;
  const TodayTab({super.key, required this.onAdd});

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  String? _person;
  DateTime _day = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    if (_person != null && store.personById(_person!) == null) _person = null;
    final doses = store.dosesOn(_day, personId: _person);
    final isToday = sameDay(_day, now);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TabHeader(
            subtitle: greeting(now),
            title: isToday ? tr('جرعات النهارده', "Today's doses") : relativeDay(_day, now),
            trailing: logoBadge(),
          ),
        ),
        if (store.meds.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.alarm_add_rounded,
              title: tr('لسه مفيش أدوية', 'No medicines yet'),
              subtitle: tr(
                  'ضيف أول دوا لنفسك أو لحد من أهلك، وعلاجي هيفكّرك بكل جرعة في ميعادها لحد ما الكورس يخلص.',
                  "Add a medicine for yourself or a family member and Elagy will remind you of every dose until the course ends."),
              action: tr('ضيف أول دوا', 'Add first medicine'),
              onAction: widget.onAdd,
            ),
          )
        else ...[
          SliverToBoxAdapter(
            child: _SummaryCard(
              doses: doses,
              isToday: isToday,
              personId: _person,
            ),
          ),
          SliverToBoxAdapter(
            child: _WeekStrip(
              selected: _day,
              onSelect: (d) => setState(() => _day = d),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PersonFilterBar(
                people: store.people,
                selected: _person,
                onChanged: (p) => setState(() => _person = p),
              ),
            ),
          ),
          if (doses.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.event_available_rounded,
                title: tr('مفيش جرعات في اليوم ده', 'No doses on this day'),
                subtitle: tr('استريح 😌 مفيش أي دوا متسجل في اليوم ده.',
                    'Relax 😌 nothing is scheduled for this day.'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: SliverList.builder(
                itemCount: doses.length,
                itemBuilder: (c, i) => _DoseTile(
                  dose: doses[i],
                  first: i == 0,
                  last: i == doses.length - 1,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Dose> doses;
  final bool isToday;
  final String? personId;
  const _SummaryCard({
    required this.doses,
    required this.isToday,
    required this.personId,
  });

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final taken = doses.where((d) => d.isTaken).length;
    final total = doses.length;
    final progress = total == 0 ? 0.0 : taken / total;
    final next = store.nextDose(personId: personId);
    final now = DateTime.now();
    final nextPerson = next == null ? null : store.personById(next.med.personId);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF1B3358), Color(0xFF2E5C8A), Color(0xFF4FA8D8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => CustomPaint(
                painter: _RingPainter(v),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$taken/$total',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                      Text(tr('جرعة', 'doses'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? tr('مفيش جرعات', 'No doses')
                      : taken == total
                          ? tr('برافو! خلصت كل الجرعات 🎉', 'Great! All doses taken 🎉')
                          : isToday
                              ? tr('فاضل ${total - taken} من $total النهارده',
                                  '${total - taken} of $total left today')
                              : tr('فاضل ${total - taken} من $total',
                                  '${total - taken} of $total left'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (next != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('الجرعة الجاية: ${next.med.name}', 'Next: ${next.med.name}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                              Text(
                                '${nextPerson?.name ?? ''} • ${fmtDateTime(next.at)} • ${next.at.isAfter(now) ? countdown(next.at.difference(now)) : tr('دلوقتي', 'now')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(tr('مفيش جرعات جاية 👌', 'No upcoming doses 👌'),
                      style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = 9.0;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        Paint()
          ..shader = const SweepGradient(
            colors: [Color(0xFF9BE39E), Color(0xFF6CC070)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

class _WeekStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  const _WeekStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final days =
        List.generate(14, (i) => DateTime(today.year, today.month, today.day + i - 2));
    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        controller: ScrollController(initialScrollOffset: 0),
        itemBuilder: (c, i) {
          final d = days[i];
          final active = sameDay(d, selected);
          final isToday = sameDay(d, today);
          return GestureDetector(
            onTap: () => onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 54,
              margin: const EdgeInsetsDirectional.only(end: 8, bottom: 10),
              decoration: active
                  ? BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: isToday ? AppColors.sky : AppColors.line),
                    ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayShort(d),
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white70 : AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoseTile extends StatelessWidget {
  final Dose dose;
  final bool first;
  final bool last;
  const _DoseTile({required this.dose, required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final person = store.personById(dose.med.personId);
    final state = doseState(dose, DateTime.now());

    Color accent;
    Color accentBg;
    String stateText;
    IconData stateIcon;
    switch (state) {
      case DoseState.taken:
        accent = AppColors.green;
        accentBg = AppColors.greenLight;
        stateText = tr('اتاخدت', 'Taken');
        stateIcon = Icons.check_circle_rounded;
        break;
      case DoseState.due:
        accent = AppColors.orange;
        accentBg = AppColors.orangeLight;
        stateText = tr('ميعادها دلوقتي', 'Due now');
        stateIcon = Icons.notifications_active_rounded;
        break;
      case DoseState.missed:
        accent = AppColors.red;
        accentBg = AppColors.redLight;
        stateText = tr('فاتت', 'Missed');
        stateIcon = Icons.error_outline_rounded;
        break;
      case DoseState.upcoming:
        accent = AppColors.sky;
        accentBg = AppColors.skyLight;
        stateText = tr('جاية', 'Upcoming');
        stateIcon = Icons.schedule_rounded;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // time + timeline
          SizedBox(
            width: 62,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Text(
                  clockOf(dose.at.hour, dose.at.minute),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, height: 1),
                ),
                Text(
                  dose.at.hour < 12 ? tr('صباحًا', 'AM') : tr('مساءً', 'PM'),
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : AppColors.line,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: cardDeco(),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => store.toggleTaken(dose),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (person?.color ?? AppColors.sky)
                                .withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(dose.med.form.icon,
                              color: person?.color ?? AppColors.sky, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      dose.med.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        decoration: dose.isTaken
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                  if (dose.isLast) ...[
                                    const SizedBox(width: 6),
                                    Pill(
                                      text: tr('آخر جرعة', 'Last dose'),
                                      color: Colors.white,
                                      bg: AppColors.orange,
                                      icon: Icons.flag_rounded,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dose.med.dose} • ${person?.name ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Pill(
                                    text: stateText,
                                    color: accent,
                                    bg: accentBg,
                                    icon: stateIcon,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('يوم ${dose.dayNumber} من ${dose.med.days}',
                                        'Day ${dose.dayNumber}/${dose.med.days}'),
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _CheckButton(
                          checked: dose.isTaken,
                          color: accent,
                          onTap: () => store.toggleTaken(dose),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool checked;
  final Color color;
  final VoidCallback onTap;
  const _CheckButton(
      {required this.checked, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? AppColors.green : Colors.transparent,
          border: Border.all(
            color: checked ? AppColors.green : color.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: checked ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: const Icon(Icons.check_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

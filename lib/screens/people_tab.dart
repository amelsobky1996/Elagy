import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

class PeopleTab extends StatelessWidget {
  const PeopleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        TabHeader(
          subtitle: 'العيلة',
          title: 'الأشخاص',
          trailing: logoBadge(),
        ),
        if (store.people.isEmpty)
          EmptyState(
            icon: Icons.family_restroom_rounded,
            title: 'ضيف أفراد العيلة',
            subtitle: 'كل شخص ليه أدويته وتذكيراته الخاصة.',
            action: 'إضافة شخص',
            onAction: () => showPersonSheet(context),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                for (final p in store.people)
                  _PersonCard(
                    person: p,
                    active: store
                        .medsFor(p.id)
                        .where((m) => !m.isFinished(now))
                        .length,
                    today: store
                        .dosesOn(now, personId: p.id)
                        .where((d) => !d.isTaken)
                        .length,
                  ),
                _AddCard(onTap: () => showPersonSheet(context)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Person person;
  final int active;
  final int today;
  const _PersonCard(
      {required this.person, required this.active, required this.today});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.read(context);
    return Container(
      decoration: cardDeco(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => showPersonSheet(context, existing: person),
          child: Stack(
            children: [
              PositionedDirectional(
                top: 2,
                end: 2,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.muted, size: 20),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'حذف ${person.name}؟',
                      message: 'هتتمسح كل أدوية ${person.name} وتذكيراتها.',
                    );
                    if (ok) store.deletePerson(person);
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PersonAvatar(person: person, size: 64),
                    const SizedBox(height: 10),
                    Text(person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      active == 0 ? 'مفيش أدوية شغالة' : '$active دوا شغال',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    if (today > 0)
                      Pill(
                        text: 'فاضل $today جرعة النهارده',
                        color: AppColors.orange,
                        bg: AppColors.orangeLight,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.sky, width: 1.6),
            color: AppColors.skyLight.withValues(alpha: 0.5),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                  size: 36, color: AppColors.sky),
              SizedBox(height: 8),
              Text('إضافة شخص',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
        ),
      );
}

/// Bottom sheet to add/edit a person. Returns the saved person.
Future<Person?> showPersonSheet(BuildContext context, {Person? existing}) {
  final store = StoreScope.read(context);
  final ctrl = TextEditingController(text: existing?.name ?? '');
  var color = existing?.colorIndex ?? store.nextColor();
  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(
      builder: (c, setS) {
        void save() {
          final name = ctrl.text.trim();
          if (name.isEmpty) return;
          Person p;
          if (existing != null) {
            store.updatePerson(existing, name, color);
            p = existing;
          } else {
            p = store.addPerson(name, color);
          }
          Navigator.pop(c, p);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(c).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  PersonAvatar(
                    person: Person(
                        id: '',
                        name: ctrl.text.isEmpty ? '؟' : ctrl.text,
                        colorIndex: color),
                    size: 52,
                  ),
                  const SizedBox(width: 12),
                  Text(existing == null ? 'شخص جديد' : 'تعديل البيانات',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: ctrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setS(() {}),
                onSubmitted: (_) => save(),
                decoration: const InputDecoration(
                  hintText: 'الاسم (مثلًا: ماما، بابا، يوسف)',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اللون',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < personPalette.length; i++)
                    GestureDetector(
                      onTap: () => setS(() => color = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: personPalette[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == i
                                ? AppColors.navy
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: color == i
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: ctrl.text.trim().isEmpty ? null : save,
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

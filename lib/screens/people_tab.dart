import 'package:flutter/material.dart';

import '../i18n.dart';
import '../models.dart';
import '../notifier.dart';
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
          subtitle: tr('العيلة', 'Family'),
          title: tr('الأشخاص', 'People'),
          trailing: logoBadge(),
        ),
        if (store.people.isEmpty)
          EmptyState(
            icon: Icons.family_restroom_rounded,
            title: tr('ضيف أفراد العيلة', 'Add family members'),
            subtitle: tr('كل شخص ليه صورته وأدويته وتذكيراته الخاصة.',
                'Each person has their own photo, medicines and reminders.'),
            action: tr('إضافة شخص', 'Add person'),
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
              childAspectRatio: 0.88,
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
              // colored band on top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    color: person.color.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: AppColors.muted, size: 20),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: tr('حذف ${person.name}؟', 'Delete ${person.name}?'),
                      message: tr(
                          'هتتمسح كل أدوية ${person.name} وتذكيراتها.',
                          "All of ${person.name}'s medicines and reminders will be removed."),
                    );
                    if (ok) store.deletePerson(person);
                  },
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      PersonAvatar(person: person, size: 72, ring: true),
                      const SizedBox(height: 10),
                      Text(person.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        active == 0
                            ? tr('مفيش أدوية شغالة', 'No active medicines')
                            : tr('$active دوا شغال', '$active active'),
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      if (today > 0)
                        Pill(
                          text: tr('فاضل $today جرعة النهارده',
                              '$today left today'),
                          color: AppColors.orange,
                          bg: AppColors.orangeLight,
                        )
                      else if (active > 0)
                        Pill(
                          text: tr('خلص جرعات النهارده ✓', 'Done for today ✓'),
                          color: AppColors.green,
                          bg: AppColors.greenLight,
                        ),
                    ],
                  ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_alt_1_rounded,
                  size: 36, color: AppColors.sky),
              const SizedBox(height: 8),
              Text(tr('إضافة شخص', 'Add person'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
        ),
      );
}

/// Bottom sheet to add/edit a person (name, photo, color).
Future<Person?> showPersonSheet(BuildContext context, {Person? existing}) {
  final store = StoreScope.read(context);
  final ctrl = TextEditingController(text: existing?.name ?? '');
  var color = existing?.colorIndex ?? store.nextColor();
  String? photo = existing?.photo;
  var picking = false;

  return showModalBottomSheet<Person>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (c) => StatefulBuilder(
      builder: (c, setS) {
        void save() {
          final name = ctrl.text.trim();
          if (name.isEmpty) return;
          Person p;
          if (existing != null) {
            store.updatePerson(existing, name, color, photo: photo ?? '');
            p = existing;
          } else {
            p = store.addPerson(name, color, photo: photo);
          }
          Navigator.pop(c, p);
        }

        Future<void> pick(bool camera) async {
          setS(() => picking = true);
          final r = await WebNotifier.pickImage(camera: camera);
          setS(() {
            picking = false;
            if (r.isNotEmpty) photo = r;
          });
        }

        void photoMenu() {
          showModalBottomSheet<void>(
            context: c,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (m) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_rounded,
                          color: AppColors.sky),
                      title: Text(tr('اختار من الصور', 'Choose from gallery')),
                      onTap: () {
                        Navigator.pop(m);
                        pick(false);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_camera_rounded,
                          color: AppColors.green),
                      title: Text(tr('صوّر بالكاميرا', 'Take a photo')),
                      onTap: () {
                        Navigator.pop(m);
                        pick(true);
                      },
                    ),
                    if (photo != null && photo!.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.red),
                        title: Text(tr('شيل الصورة', 'Remove photo'),
                            style: const TextStyle(color: AppColors.red)),
                        onTap: () {
                          Navigator.pop(m);
                          setS(() => photo = null);
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        final preview = Person(
          id: '',
          name: ctrl.text.isEmpty ? '؟' : ctrl.text,
          colorIndex: color,
          photo: photo,
        );

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
              const SizedBox(height: 12),
              Center(
                child: Text(
                    existing == null
                        ? tr('شخص جديد', 'New person')
                        : tr('تعديل البيانات', 'Edit person'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 14),
              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: picking ? null : photoMenu,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PersonAvatar(person: preview, size: 104, ring: true),
                      if (picking)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 3),
                            ),
                          ),
                        ),
                      PositionedDirectional(
                        bottom: -2,
                        end: -2,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.sky,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.card, width: 3),
                          ),
                          child: const Icon(Icons.photo_camera_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: picking ? null : photoMenu,
                  child: Text(
                    photo == null
                        ? tr('إضافة صورة', 'Add photo')
                        : tr('تغيير الصورة', 'Change photo'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setS(() {}),
                onSubmitted: (_) => save(),
                decoration: InputDecoration(
                  hintText: tr('الاسم (مثلًا: ماما، بابا، يوسف)',
                      'Name (e.g. Mom, Dad, Youssef)'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Text(tr('اللون', 'Color'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
                                ? AppColors.ink
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
                onPressed: ctrl.text.trim().isEmpty || picking ? null : save,
                child: Text(tr('حفظ', 'Save')),
              ),
            ],
          ),
        );
      },
    ),
  );
}

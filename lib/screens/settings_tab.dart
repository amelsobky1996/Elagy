import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n.dart';
import '../notifier.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

const appVersion = '1.1.0';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final adherence = store.adherence;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        TabHeader(
          subtitle: tr('خصّص التطبيق', 'Make it yours'),
          title: tr('الإعدادات', 'Settings'),
          trailing: logoBadge(),
        ),

        // ---------- Stats ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: Row(
            children: [
              _Stat(
                icon: Icons.people_rounded,
                color: AppColors.sky,
                value: '${store.people.length}',
                label: tr('أشخاص', 'People'),
              ),
              const SizedBox(width: 10),
              _Stat(
                icon: Icons.medication_rounded,
                color: AppColors.orange,
                value: '${store.activeCourses}',
                label: tr('كورس شغال', 'Active'),
              ),
              const SizedBox(width: 10),
              _Stat(
                icon: Icons.verified_rounded,
                color: AppColors.green,
                value: adherence == null
                    ? '—'
                    : '${(adherence * 100).round()}%',
                label: tr('الالتزام', 'Adherence'),
              ),
            ],
          ),
        ),

        // ---------- Appearance ----------
        _SectionTitle(tr('الشكل واللغة', 'Look & language')),
        _Group(children: [
          _Row(
            icon: Icons.translate_rounded,
            color: AppColors.sky,
            title: tr('اللغة', 'Language'),
            below: _Segmented(
              value: store.lang,
              onChanged: store.setLang,
              options: const [
                ('ar', 'العربية', null),
                ('en', 'English', null),
              ],
            ),
          ),
          _Row(
            icon: Icons.palette_rounded,
            color: const Color(0xFFB37FE0),
            title: tr('الثيم', 'Theme'),
            below: _Segmented(
              value: store.themeMode,
              onChanged: store.setThemeMode,
              options: [
                ('system', tr('تلقائي', 'Auto'), Icons.brightness_auto_rounded),
                ('light', tr('فاتح', 'Light'), Icons.light_mode_rounded),
                ('dark', tr('غامق', 'Dark'), Icons.dark_mode_rounded),
              ],
            ),
          ),
        ]),

        // ---------- Notifications ----------
        _SectionTitle(tr('الإشعارات', 'Notifications')),
        _Group(children: [
          _Row(
            icon: Icons.notifications_active_rounded,
            color: AppColors.orange,
            title: tr('حالة الإشعارات', 'Notification status'),
            subtitle: _permissionText(store.permission),
            trailing: store.permission == 'default'
                ? FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(80, 40)),
                    onPressed: store.requestPermission,
                    child: Text(tr('تفعيل', 'Enable')),
                  )
                : Icon(
                    store.permission == 'granted'
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: store.permission == 'granted'
                        ? AppColors.green
                        : AppColors.red,
                  ),
          ),
          _Row(
            icon: Icons.volume_up_rounded,
            color: AppColors.green,
            title: tr('صوت التنبيه', 'Alert sound'),
            subtitle: tr('نغمة قصيرة مع كل جرعة والتطبيق مفتوح',
                'A short chime with each dose while the app is open'),
            trailing: Switch.adaptive(
              value: store.sound,
              activeTrackColor: AppColors.green,
              onChanged: store.setSound,
            ),
          ),
          _Row(
            icon: Icons.send_rounded,
            color: AppColors.sky,
            title: tr('جرّب إشعار', 'Send a test notification'),
            subtitle: tr('اتأكد إن التذكيرات بتوصلك',
                'Make sure reminders reach you'),
            onTap: () async {
              if (store.permission == 'default') {
                await store.requestPermission();
              }
              store.testNotification();
              if (!context.mounted) return;
              if (store.permission != 'granted') {
                snack(
                    context,
                    tr('لازم تفعّل الإشعارات الأول',
                        'Enable notifications first'));
              }
            },
          ),
        ]),

        // ---------- Install ----------
        _SectionTitle(tr('التطبيق', 'App')),
        _Group(children: [
          _installRow(context),
        ]),

        // ---------- Data ----------
        _SectionTitle(tr('البيانات', 'Data')),
        _Group(children: [
          _Row(
            icon: Icons.download_rounded,
            color: AppColors.sky,
            title: tr('نسخة احتياطية', 'Back up data'),
            subtitle: tr('نزّل ملف فيه كل الأشخاص والأدوية',
                'Download a file with all people and medicines'),
            onTap: () {
              final d = DateTime.now();
              final name =
                  'elagy-backup-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.json';
              WebNotifier.download(name, store.exportJson());
              snack(context, tr('تم تنزيل النسخة ✅', 'Backup downloaded ✅'));
            },
          ),
          _Row(
            icon: Icons.upload_file_rounded,
            color: AppColors.green,
            title: tr('استرجاع نسخة', 'Restore backup'),
            subtitle: tr('رجّع بياناتك من ملف نسخة احتياطية',
                'Restore your data from a backup file'),
            onTap: () async {
              final text = await WebNotifier.pickText();
              if (text.isEmpty || !context.mounted) return;
              final ok = await confirmDialog(
                context,
                title: tr('استرجاع النسخة؟', 'Restore backup?'),
                message: tr(
                    'البيانات الحالية هتتبدّل بالبيانات اللي في الملف.',
                    'Your current data will be replaced with the backup.'),
                ok: tr('استرجاع', 'Restore'),
                icon: Icons.restore_rounded,
              );
              if (!ok || !context.mounted) return;
              final done = store.importJson(text);
              snack(
                context,
                done
                    ? tr('تم استرجاع البيانات ✅', 'Data restored ✅')
                    : tr('الملف ده مش نسخة احتياطية من علاجي',
                        "This file isn't an Elagy backup"),
              );
            },
          ),
          _Row(
            icon: Icons.delete_forever_rounded,
            color: AppColors.red,
            title: tr('حذف كل البيانات', 'Delete all data'),
            titleColor: AppColors.red,
            subtitle: tr('الأشخاص والأدوية والتذكيرات',
                'People, medicines and reminders'),
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: tr('حذف كل البيانات؟', 'Delete all data?'),
                message: tr(
                    'هيتمسح كل الأشخاص والأدوية والتذكيرات نهائيًا ومش هينفع ترجّعهم إلا من نسخة احتياطية.',
                    'All people, medicines and reminders will be permanently deleted. You can only recover them from a backup.'),
                ok: tr('احذف الكل', 'Delete all'),
                icon: Icons.delete_forever_rounded,
              );
              if (!ok) return;
              await store.deleteAll();
              if (!context.mounted) return;
              snack(context, tr('تم حذف كل البيانات', 'All data deleted'));
            },
          ),
        ]),

        // ---------- About ----------
        _SectionTitle(tr('عن التطبيق', 'About')),
        _Group(children: [
          _Row(
            icon: Icons.lock_rounded,
            color: const Color(0xFF3DBFB0),
            title: tr('خصوصيتك', 'Your privacy'),
            subtitle: tr(
                'كل البيانات والصور محفوظة على جهازك بس، ومش بتترفع على أي سيرفر.',
                'All data and photos stay on this device only and are never uploaded.'),
          ),
          _Row(
            icon: Icons.medical_information_rounded,
            color: AppColors.orange,
            title: tr('تنبيه', 'Note'),
            subtitle: tr(
                'علاجي بيفكّرك بس، ومش بديل عن استشارة الدكتور أو الصيدلي.',
                "Elagy is a reminder only and doesn't replace advice from your doctor or pharmacist."),
          ),
        ]),

        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Image.asset('assets/logo_icon.png', width: 56),
              const SizedBox(height: 6),
              Text('${tr('علاجي', 'Elagy')} • v$appVersion',
                  style: TextStyle(
                      color: AppColors.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Powered By ',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.muted)),
                    Text('Sobky',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _permissionText(String p) {
    switch (p) {
      case 'granted':
        return tr('شغالة ✓', 'On ✓');
      case 'denied':
        return tr('مقفولة — افتحها من إعدادات المتصفح',
            'Blocked — allow them in browser settings');
      case 'unsupported':
        return WebNotifier.isIos() && !WebNotifier.isStandalone()
            ? tr('على الآيفون ضيف التطبيق للشاشة الرئيسية الأول',
                'On iPhone, add the app to your Home Screen first')
            : tr('المتصفح مش بيدعمها', 'Not supported by this browser');
      default:
        return tr('لسه متفعّلتش', 'Not enabled yet');
    }
  }

  Widget _installRow(BuildContext context) {
    if (WebNotifier.isStandalone()) {
      return _Row(
        icon: Icons.install_mobile_rounded,
        color: AppColors.green,
        title: tr('التطبيق متثبّت ✓', 'App installed ✓'),
        subtitle: tr('بتستخدم علاجي كتطبيق على الموبايل',
            "You're using Elagy as an installed app"),
      );
    }
    if (WebNotifier.isIos()) {
      return _Row(
        icon: Icons.ios_share_rounded,
        color: AppColors.sky,
        title: tr('ثبّت على الآيفون', 'Install on iPhone'),
        subtitle: tr(
            'من Safari: دوس Share ثم Add to Home Screen',
            'In Safari: tap Share, then Add to Home Screen'),
      );
    }
    return _Row(
      icon: Icons.install_mobile_rounded,
      color: AppColors.sky,
      title: tr('ثبّت التطبيق على الموبايل', 'Install the app'),
      subtitle: WebNotifier.canInstall()
          ? tr('يشتغل زي أي تطبيق ومن غير متصفح',
              'Runs like a normal app, without the browser')
          : tr('من قائمة المتصفح ⋮ اختار "Install app" أو "Add to Home screen"',
              'From the browser menu ⋮ choose "Install app" or "Add to Home screen"'),
      trailing: WebNotifier.canInstall()
          ? FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(80, 40)),
              onPressed: () async {
                await WebNotifier.install();
                if (mounted) setState(() {});
              },
              child: Text(tr('تثبيت', 'Install')),
            )
          : null,
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: cardDeco(radius: 20),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
              Text(label,
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        child: Text(text,
            style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      );
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: cardDeco(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: AppColors.line),
              children[i],
            ],
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: titleColor ?? AppColors.ink)),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  height: 1.5)),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (onTap != null)
                    Icon(
                      isAr
                          ? Icons.chevron_left_rounded
                          : Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                ],
              ),
              if (below != null) ...[
                const SizedBox(height: 12),
                below!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final List<(String, String, IconData?)> options;
  const _Segmented({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == o.$1 ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (o.$3 != null) ...[
                        Icon(o.$3,
                            size: 18,
                            color: value == o.$1
                                ? Colors.white
                                : AppColors.muted),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        o.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              value == o.$1 ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

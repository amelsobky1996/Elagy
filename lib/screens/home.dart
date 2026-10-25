import 'package:flutter/material.dart';

import '../fmt.dart';
import '../i18n.dart';
import '../models.dart';
import '../notifier.dart';
import '../theme.dart';
import 'med_form.dart';
import 'meds_tab.dart';
import 'people_tab.dart';
import 'settings_tab.dart';
import 'today_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _setTab(int i) {
    StoreScope.read(context).homeTab = i;
    setState(() {});
  }

  Future<void> _addMed() async {
    final store = StoreScope.read(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MedFormScreen()),
    );
    if (saved == true && mounted) {
      _setTab(0);
      if (store.permission == 'default') {
        await store.requestPermission();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tab = store.homeTab;
    final tabs = [
      TodayTab(onAdd: _addMed),
      MedsTab(onAdd: _addMed),
      const PeopleTab(),
      const SettingsTab(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (store.alert != null) _AlertBanner(dose: store.alert!),
            if (tab != 3 &&
                store.loaded &&
                store.meds.isNotEmpty &&
                store.permission != 'granted')
              const PermissionBanner(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(tab), child: tabs[tab]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: tab >= 2
          ? null
          : FloatingActionButton.extended(
              onPressed: _addMed,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('دوا جديد', 'New medicine'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        height: 70,
        onDestinationSelected: _setTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today_rounded, color: AppColors.ink),
            label: tr('اليوم', 'Today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon:
                Icon(Icons.medication_rounded, color: AppColors.ink),
            label: tr('الأدوية', 'Medicines'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.ink),
            label: tr('الأشخاص', 'People'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.ink),
            label: tr('الإعدادات', 'Settings'),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Dose dose;
  const _AlertBanner({required this.dose});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final person = store.personById(dose.med.personId);
    final last = dose.isLast;
    final who = person?.name ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: last
              ? const [Color(0xFFF2A14A), Color(0xFFE5616F)]
              : const [Color(0xFF4FA8D8), Color(0xFF1B3358)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (last ? AppColors.orange : AppColors.sky)
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  last
                      ? tr('دي آخر جرعة! $who', 'Last dose! $who')
                      : tr('ميعاد الدوا — $who', 'Medicine time — $who'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                ),
                Text(
                  '${dose.med.name} • ${dose.med.dose}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => store.toggleTaken(dose),
            child: Text(tr('خدتها ✓', 'Taken ✓'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            onPressed: store.dismissAlert,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final denied = store.permission == 'denied';
    final unsupported = store.permission == 'unsupported';
    String msg;
    if (unsupported) {
      msg = WebNotifier.isIos() && !WebNotifier.isStandalone()
          ? tr('عشان الإشعارات تشتغل على الآيفون: Share ← Add to Home Screen وافتح علاجي من الأيقونة.',
              'For notifications on iPhone: Share → Add to Home Screen, then open Elagy from the icon.')
          : tr('المتصفح ده مش بيدعم الإشعارات. جرّب Chrome.',
              "This browser doesn't support notifications. Try Chrome.");
    } else if (denied) {
      msg = tr('الإشعارات مقفولة. افتحها من إعدادات المتصفح للموقع ده.',
          'Notifications are blocked. Allow them in the browser settings for this site.');
    } else {
      msg = tr('فعّل الإشعارات عشان نفكّرك بكل جرعة في ميعادها.',
          'Turn on notifications so we can remind you of every dose.');
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_rounded, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, fontWeight: FontWeight.w600)),
          ),
          if (!denied && !unsupported)
            TextButton(
              onPressed: store.requestPermission,
              child: Text(tr('تفعيل', 'Enable'),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

/// Shared header used by the tabs.
class TabHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const TabHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600)),
                Text(title,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, height: 1.3)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

String greeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return tr('صباح الخير ☀️', 'Good morning ☀️');
  if (h < 18) return tr('مساء النور 🌤️', 'Good afternoon 🌤️');
  return tr('مساء الخير 🌙', 'Good evening 🌙');
}

String todayLabel(DateTime now) => fullDate(now);

Widget logoBadge() => Container(
      width: 46,
      height: 46,
      padding: const EdgeInsets.all(5),
      decoration: cardDeco(radius: 16, color: Colors.white),
      child: Image.asset('assets/logo_icon.png'),
    );

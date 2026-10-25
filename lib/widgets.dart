import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

class PersonAvatar extends StatelessWidget {
  final Person? person;
  final double size;
  const PersonAvatar({super.key, required this.person, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = person?.color ?? AppColors.muted;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.75), color],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        person?.initial ?? '؟',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Horizontal "الكل / person / person" selector.
class PersonFilterBar extends StatelessWidget {
  final List<Person> people;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const PersonFilterBar({
    super.key,
    required this.people,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (people.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _chip(
            label: 'الكل',
            active: selected == null,
            color: AppColors.navy,
            onTap: () => onChanged(null),
            leading: const Icon(Icons.groups_rounded, size: 18),
          ),
          for (final p in people)
            _chip(
              label: p.name,
              active: selected == p.id,
              color: p.color,
              onTap: () => onChanged(p.id),
              leading: PersonAvatar(person: p, size: 24),
            ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    required Widget leading,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 14, 4),
          decoration: BoxDecoration(
            color: active ? color : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active ? color : AppColors.line),
          ),
          child: Row(
            children: [
              IconTheme(
                data: IconThemeData(
                    color: active ? Colors.white : AppColors.navy),
                child: leading,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.skyLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 46, color: AppColors.sky),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.6)),
          if (action != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(action!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  final IconData? icon;
  const Pill({
    super.key,
    required this.text,
    required this.color,
    required this.bg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(text,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String ok = 'حذف',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message, style: const TextStyle(height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            minimumSize: const Size(90, 44),
          ),
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

import 'i18n.dart';

const _weekdaysAr = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _weekdaysEn = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _weekdaysShortAr = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
const _weekdaysShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthsAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];
const _monthsEn = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String weekday(DateTime d) =>
    (isAr ? _weekdaysAr : _weekdaysEn)[d.weekday - 1];
String weekdayShort(DateTime d) =>
    (isAr ? _weekdaysShortAr : _weekdaysShortEn)[d.weekday - 1];
String monthName(DateTime d) => (isAr ? _monthsAr : _monthsEn)[d.month - 1];

String fullDate(DateTime d) => isAr
    ? '${weekday(d)} ${d.day} ${monthName(d)}'
    : '${weekday(d)}, ${monthName(d)} ${d.day}';
String shortDate(DateTime d) =>
    isAr ? '${d.day} ${monthName(d)}' : '${monthName(d)} ${d.day}';

/// "HH:mm" -> "8:30 م" / "8:30 PM"
String fmtHm(String hm) {
  final p = hm.split(':');
  return fmtTime(int.parse(p[0]), int.parse(p[1]));
}

String periodOf(int h) => h < 12 ? tr('ص', 'AM') : tr('م', 'PM');

String clockOf(int h, int m) {
  var hh = h % 12;
  if (hh == 0) hh = 12;
  return '$hh:${m.toString().padLeft(2, '0')}';
}

String fmtTime(int h, int m) => '${clockOf(h, m)} ${periodOf(h)}';

String fmtDateTime(DateTime d) => fmtTime(d.hour, d.minute);

String hm(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String relativeDay(DateTime d, DateTime now) {
  final diff = dateOnly(d).difference(dateOnly(now)).inDays;
  if (diff == 0) return tr('النهارده', 'Today');
  if (diff == 1) return tr('بكره', 'Tomorrow');
  if (diff == -1) return tr('امبارح', 'Yesterday');
  return fullDate(d);
}

/// Human countdown: "بعد ساعتين و 10 دقايق" / "in 2h 10m"
String countdown(Duration d) {
  if (d.isNegative) return tr('دلوقتي', 'now');
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0 && m == 0) return tr('خلال دقيقة', 'in a minute');
  if (!isAr) {
    if (h == 0) return 'in ${m}m';
    if (m == 0) return 'in ${h}h';
    return 'in ${h}h ${m}m';
  }
  String hs;
  if (h == 0) {
    hs = '';
  } else if (h == 1) {
    hs = 'ساعة';
  } else if (h == 2) {
    hs = 'ساعتين';
  } else if (h <= 10) {
    hs = '$h ساعات';
  } else {
    hs = '$h ساعة';
  }
  String ms;
  if (m == 0) {
    ms = '';
  } else if (m == 1) {
    ms = 'دقيقة';
  } else if (m == 2) {
    ms = 'دقيقتين';
  } else if (m <= 10) {
    ms = '$m دقايق';
  } else {
    ms = '$m دقيقة';
  }
  if (hs.isEmpty) return 'بعد $ms';
  if (ms.isEmpty) return 'بعد $hs';
  return 'بعد $hs و $ms';
}

String daysLabel(int n) {
  if (!isAr) return n == 1 ? '1 day' : '$n days';
  if (n == 1) return 'يوم واحد';
  if (n == 2) return 'يومين';
  if (n <= 10) return '$n أيام';
  return '$n يوم';
}

String dayUnit(int n) {
  if (!isAr) return n == 1 ? 'day' : 'days';
  if (n == 1) return 'يوم';
  if (n <= 10) return 'أيام';
  return 'يوم';
}

String timesPerDayLabel(int n) {
  if (!isAr) return n == 1 ? 'once a day' : '$n times a day';
  if (n == 1) return 'مرة في اليوم';
  if (n == 2) return 'مرتين في اليوم';
  if (n <= 10) return '$n مرات في اليوم';
  return '$n مرة في اليوم';
}

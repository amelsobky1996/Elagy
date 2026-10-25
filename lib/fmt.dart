const _weekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];
const _weekdaysShort = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
const _months = [
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

String weekday(DateTime d) => _weekdays[d.weekday - 1];
String weekdayShort(DateTime d) => _weekdaysShort[d.weekday - 1];
String monthName(DateTime d) => _months[d.month - 1];

String fullDate(DateTime d) => '${weekday(d)} ${d.day} ${monthName(d)}';
String shortDate(DateTime d) => '${d.day} ${monthName(d)}';

/// "HH:mm" -> "8:30 م"
String fmtHm(String hm) {
  final p = hm.split(':');
  return fmtTime(int.parse(p[0]), int.parse(p[1]));
}

String fmtTime(int h, int m) {
  final period = h < 12 ? 'ص' : 'م';
  var hh = h % 12;
  if (hh == 0) hh = 12;
  return '$hh:${m.toString().padLeft(2, '0')} $period';
}

String fmtDateTime(DateTime d) => fmtTime(d.hour, d.minute);

String hm(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String relativeDay(DateTime d, DateTime now) {
  final diff = dateOnly(d).difference(dateOnly(now)).inDays;
  if (diff == 0) return 'النهارده';
  if (diff == 1) return 'بكره';
  if (diff == -1) return 'امبارح';
  return fullDate(d);
}

/// Human countdown: "بعد ساعتين و 10 دقايق"
String countdown(Duration d) {
  if (d.isNegative) return 'دلوقتي';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0 && m == 0) return 'خلال دقيقة';
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
  if (n == 1) return 'يوم واحد';
  if (n == 2) return 'يومين';
  if (n <= 10) return '$n أيام';
  return '$n يوم';
}

String timesPerDayLabel(int n) {
  if (n == 1) return 'مرة في اليوم';
  if (n == 2) return 'مرتين في اليوم';
  if (n <= 10) return '$n مرات في اليوم';
  return '$n مرة في اليوم';
}

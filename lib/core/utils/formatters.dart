import 'package:intl/intl.dart';

abstract final class Formatters {
  static final _count = NumberFormat.decimalPattern();

  static String count(int n) => _count.format(n);

  /// "1 photo", "2,140 photos".
  static String plural(int n, String one, [String? many]) =>
      '${count(n)} ${n == 1 ? one : (many ?? '${one}s')}';

  /// Compact media duration: 0:07, 3:45, 1:02:10.
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
    return '$m:$s';
  }

  static String bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes / 1024;
    var i = 0;
    while (value >= 1024 && i < units.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[i]}';
  }

  static String megapixels(int w, int h) {
    final mp = w * h / 1000000;
    if (mp < 0.1) return '';
    return '${mp.toStringAsFixed(mp >= 10 ? 0 : 1)} MP';
  }

  static String fullDate(DateTime d) => DateFormat('EEEE, d MMMM y').format(d);
  static String time(DateTime d) => DateFormat.jm().format(d);
  static String shortDate(DateTime d) => DateFormat('d MMM y').format(d);
  static String month(DateTime d) => DateFormat('MMMM y').format(d);
  static String monthName(int month) =>
      DateFormat('MMMM').format(DateTime(2000, month));

  /// Section header label: "Today", "Yesterday", "Monday", "12 March 2024".
  static String dayHeader(DateTime d, DateTime now) {
    final day = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(d);
    if (d.year == now.year) return DateFormat('EEE, d MMM').format(d);
    return DateFormat('EEE, d MMM y').format(d);
  }

  static String monthHeader(DateTime d, DateTime now) => d.year == now.year
      ? DateFormat('MMMM').format(d)
      : DateFormat('MMMM y').format(d);

  static String coordinate(double lat, double lng) {
    String f(double v, String pos, String neg) =>
        '${v.abs().toStringAsFixed(4)}° ${v >= 0 ? pos : neg}';
    return '${f(lat, 'N', 'S')}, ${f(lng, 'E', 'W')}';
  }
}

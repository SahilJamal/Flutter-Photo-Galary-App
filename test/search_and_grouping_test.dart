import 'package:flutter_test/flutter_test.dart';
import 'package:photo_gallery/core/utils/formatters.dart';
import 'package:photo_gallery/features/search/search_controller.dart';

void main() {
  final now = DateTime(2026, 10, 29, 12);

  group('parseDateQuery', () {
    test('year', () {
      final m = parseDateQuery('2024', now: now)!;
      expect(m.from, DateTime(2024));
      expect(m.to, DateTime(2025));
    });

    test('month without year picks the most recent occurrence', () {
      expect(parseDateQuery('march', now: now)!.from, DateTime(2026, 3));
      expect(parseDateQuery('dec', now: now)!.from, DateTime(2025, 12));
    });

    test('month with year', () {
      final m = parseDateQuery('Feb 2022', now: now)!;
      expect(m.from, DateTime(2022, 2));
      expect(m.to, DateTime(2022, 3));
    });

    test('today and yesterday', () {
      expect(parseDateQuery('today', now: now)!.from, DateTime(2026, 10, 29));
      expect(
        parseDateQuery('yesterday', now: now)!.from,
        DateTime(2026, 10, 28),
      );
    });

    test('non-dates are ignored', () {
      expect(parseDateQuery('camera', now: now), isNull);
      expect(parseDateQuery('ma', now: now), isNull);
      expect(parseDateQuery('', now: now), isNull);
    });
  });

  group('Formatters', () {
    test('duration', () {
      expect(Formatters.duration(const Duration(seconds: 7)), '0:07');
      expect(
        Formatters.duration(const Duration(minutes: 3, seconds: 45)),
        '3:45',
      );
      expect(
        Formatters.duration(const Duration(hours: 1, minutes: 2, seconds: 10)),
        '1:02:10',
      );
    });

    test('bytes', () {
      expect(Formatters.bytes(512), '512 B');
      expect(Formatters.bytes(1536), '1.5 KB');
      expect(Formatters.bytes(3 * 1024 * 1024), '3.0 MB');
    });

    test('day header', () {
      expect(Formatters.dayHeader(DateTime(2026, 10, 29, 8), now), 'Today');
      expect(Formatters.dayHeader(DateTime(2026, 10, 28), now), 'Yesterday');
    });
  });
}

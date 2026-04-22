import 'package:clockly_mobile/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils.formatDuration', () {
    test('returns 0h 0m for zero or negative seconds', () {
      expect(AppDateUtils.formatDuration(0), '0h 0m');
      expect(AppDateUtils.formatDuration(-1), '0h 0m');
    });

    test('returns only minutes when under one hour', () {
      expect(AppDateUtils.formatDuration(60), '1m');
      expect(AppDateUtils.formatDuration(1800), '30m');
      expect(AppDateUtils.formatDuration(3599), '59m');
    });

    test('returns only hours when minutes are zero', () {
      expect(AppDateUtils.formatDuration(3600), '1h');
      expect(AppDateUtils.formatDuration(7200), '2h');
    });

    test('returns hours and minutes for mixed values', () {
      expect(AppDateUtils.formatDuration(3660), '1h 1m');
      expect(AppDateUtils.formatDuration(5400), '1h 30m');
      expect(AppDateUtils.formatDuration(28800), '8h');
      expect(AppDateUtils.formatDuration(28860), '8h 1m');
    });
  });

  group('AppDateUtils.formatDurationVerbose', () {
    test('zero-pads all components', () {
      expect(AppDateUtils.formatDurationVerbose(0), '00:00:00');
      expect(AppDateUtils.formatDurationVerbose(61), '00:01:01');
      expect(AppDateUtils.formatDurationVerbose(3661), '01:01:01');
    });

    test('handles full workday', () {
      expect(AppDateUtils.formatDurationVerbose(28800), '08:00:00');
    });
  });

  group('AppDateUtils.formatDate', () {
    test('formats as dd/MM/yyyy', () {
      final dt = DateTime(2026, 4, 1);
      expect(AppDateUtils.formatDate(dt), '01/04/2026');
    });
  });

  group('AppDateUtils.formatTime', () {
    test('formats as HH:mm', () {
      expect(AppDateUtils.formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
      expect(AppDateUtils.formatTime(DateTime(2026, 1, 1, 14, 30)), '14:30');
    });
  });

  group('AppDateUtils.isSameDay', () {
    test('returns true for same calendar day', () {
      final a = DateTime(2026, 4, 20, 8, 0);
      final b = DateTime(2026, 4, 20, 23, 59);
      expect(AppDateUtils.isSameDay(a, b), isTrue);
    });

    test('returns false for different days', () {
      final a = DateTime(2026, 4, 20);
      final b = DateTime(2026, 4, 21);
      expect(AppDateUtils.isSameDay(a, b), isFalse);
    });
  });

  group('AppDateUtils.startOfWeek', () {
    test('returns Monday for a Wednesday', () {
      final wednesday = DateTime(2026, 4, 22); // Wednesday
      final start = AppDateUtils.startOfWeek(wednesday);
      expect(start, DateTime(2026, 4, 20)); // Monday
    });

    test('returns self when already Monday', () {
      final monday = DateTime(2026, 4, 20);
      expect(AppDateUtils.startOfWeek(monday), DateTime(2026, 4, 20));
    });
  });

  group('AppDateUtils.startOfDay / endOfDay', () {
    test('startOfDay has midnight time', () {
      final dt = DateTime(2026, 4, 20, 15, 30, 45);
      expect(AppDateUtils.startOfDay(dt), DateTime(2026, 4, 20, 0, 0, 0));
    });

    test('endOfDay has 23:59:59', () {
      final dt = DateTime(2026, 4, 20, 0, 0);
      expect(AppDateUtils.endOfDay(dt), DateTime(2026, 4, 20, 23, 59, 59));
    });
  });
}

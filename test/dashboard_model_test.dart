import 'package:clockly_mobile/data/models/dashboard/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fullPayload() => {
      'total_employees': 20,
      'total_clocked_in': 12,
      'total_clocked_out': 8,
      'pending_tickets': 3,
      'kpis': {
        'total_hours_today': 45.5,
        'total_hours_week': 220.0,
        'total_hours_month': 880.75,
      },
    };

void main() {
  group('DashboardMetricsModel.fromJson', () {
    test('parses all top-level fields correctly', () {
      final model = DashboardMetricsModel.fromJson(_fullPayload());

      expect(model.totalEmployees, 20);
      expect(model.activeSessions, 12);
      expect(model.presentToday, 12);
      expect(model.absentsToday, 8);
      expect(model.pendingTickets, 3);
    });

    test('parses nested kpis correctly', () {
      final model = DashboardMetricsModel.fromJson(_fullPayload());

      expect(model.hoursToday, closeTo(45.5, 0.001));
      expect(model.hoursWeek, closeTo(220.0, 0.001));
      expect(model.hoursMonth, closeTo(880.75, 0.001));
    });

    test('defaults all fields to zero when payload is empty', () {
      final model = DashboardMetricsModel.fromJson({});

      expect(model.hoursToday, 0.0);
      expect(model.hoursWeek, 0.0);
      expect(model.hoursMonth, 0.0);
      expect(model.activeSessions, 0);
      expect(model.totalEmployees, 0);
      expect(model.presentToday, 0);
      expect(model.absentsToday, 0);
      expect(model.pendingTickets, 0);
    });

    test('tolerates missing kpis block', () {
      final model = DashboardMetricsModel.fromJson({'total_employees': 5});
      expect(model.hoursToday, 0.0);
      expect(model.totalEmployees, 5);
    });

    test('toEntity converts correctly', () {
      final entity = DashboardMetricsModel.fromJson(_fullPayload()).toEntity();

      expect(entity.totalEmployees, 20);
      expect(entity.hoursToday, closeTo(45.5, 0.001));
      expect(entity.pendingTickets, 3);
    });
  });

  group('EmployeeHoursSummaryModel.fromJson', () {
    test('parses all fields', () {
      final model = EmployeeHoursSummaryModel.fromJson({
        'user_id': 7,
        'full_name': 'Grace Hopper',
        'hours_month': 160.5,
        'hours_week': 40.0,
        'is_clocked_in': true,
      });

      expect(model.userId, 7);
      expect(model.fullName, 'Grace Hopper');
      expect(model.hoursThisMonth, closeTo(160.5, 0.001));
      expect(model.hoursThisWeek, closeTo(40.0, 0.001));
      expect(model.isClockedIn, isTrue);
    });

    test('accepts "name" as alternative to "full_name"', () {
      final model = EmployeeHoursSummaryModel.fromJson({'user_id': 1, 'name': 'Ada'});
      expect(model.fullName, 'Ada');
    });

    test('defaults numeric fields to zero and bool to false', () {
      final model = EmployeeHoursSummaryModel.fromJson({'user_id': 1});
      expect(model.hoursThisMonth, 0.0);
      expect(model.hoursThisWeek, 0.0);
      expect(model.isClockedIn, isFalse);
    });
  });
}

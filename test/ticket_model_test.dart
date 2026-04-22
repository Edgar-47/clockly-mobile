import 'package:clockly_mobile/data/models/ticket/ticket_model.dart';
import 'package:clockly_mobile/domain/entities/ticket_entity.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _minimalTicket({
  String status = 'pending',
  String category = 'other',
}) =>
    {
      'id': 1,
      'business_id': 'biz-1',
      'user_id': 7,
      'title': 'Hotel Barcelona',
      'amount': 149.99,
      'category': category,
      'status': status,
      'date': '2026-04-01T00:00:00Z',
      'created_at': '2026-04-01T10:30:00Z',
    };

void main() {
  group('TicketModel.fromJson', () {
    test('parses canonical fields', () {
      final model = TicketModel.fromJson(_minimalTicket());

      expect(model.id, 1);
      expect(model.businessId, 'biz-1');
      expect(model.userId, 7);
      expect(model.title, 'Hotel Barcelona');
      expect(model.amount, closeTo(149.99, 0.001));
    });

    test('parses date and createdAt as DateTime', () {
      final model = TicketModel.fromJson(_minimalTicket());

      expect(model.date, DateTime.utc(2026, 4, 1));
      expect(model.createdAt, DateTime.utc(2026, 4, 1, 10, 30));
    });

    test('accepts "name" as alternative to "title"', () {
      final json = _minimalTicket()..remove('title');
      json['name'] = 'Tren AVE';
      final model = TicketModel.fromJson(json);
      expect(model.title, 'Tren AVE');
    });

    test('parses optional fields', () {
      final json = {
        ..._minimalTicket(),
        'description': 'Overnight hotel',
        'media_url': 'https://s3.example.com/receipt.jpg',
        'media_type': 'image/jpeg',
        'reviewed_by_admin_id': 3,
        'reviewed_at': '2026-04-02T09:00:00Z',
        'review_note': 'Approved',
        'employee_name': 'Ada Lovelace',
      };
      final model = TicketModel.fromJson(json);

      expect(model.description, 'Overnight hotel');
      expect(model.mediaUrl, 'https://s3.example.com/receipt.jpg');
      expect(model.reviewedByAdminId, 3);
      expect(model.reviewedAt, DateTime.utc(2026, 4, 2, 9, 0));
      expect(model.reviewNote, 'Approved');
      expect(model.employeeName, 'Ada Lovelace');
    });

    test('accepts null reviewed_at without crashing', () {
      final model = TicketModel.fromJson({..._minimalTicket(), 'reviewed_at': null});
      expect(model.reviewedAt, isNull);
    });
  });

  group('TicketModel status mapping', () {
    final cases = {
      'pending': TicketStatus.pending,
      'approved': TicketStatus.approved,
      'rejected': TicketStatus.rejected,
      'reimbursed': TicketStatus.reimbursed,
      'unknown_future': TicketStatus.pending,
    };

    for (final entry in cases.entries) {
      test('maps "${entry.key}" → ${entry.value}', () {
        final entity = TicketModel.fromJson(_minimalTicket(status: entry.key)).toEntity();
        expect(entity.status, entry.value);
      });
    }
  });

  group('TicketModel category mapping', () {
    final cases = {
      'expense': TicketCategory.expense,
      'purchase': TicketCategory.purchase,
      'travel': TicketCategory.travel,
      'other': TicketCategory.other,
      'mystery': TicketCategory.other,
    };

    for (final entry in cases.entries) {
      test('maps "${entry.key}" → ${entry.value}', () {
        final entity = TicketModel.fromJson(_minimalTicket(category: entry.key)).toEntity();
        expect(entity.category, entry.value);
      });
    }
  });
}

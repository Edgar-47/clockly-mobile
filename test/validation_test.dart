import 'package:flutter_test/flutter_test.dart';

import 'package:clockly_mobile/core/errors/app_exceptions.dart';
import 'package:clockly_mobile/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ValidationException field errors', () {
    test('ApiClient extracts field errors from backend error format', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => http.Response(
              '{"error":{"code":"VALIDATION_ERROR","message":"Datos incorrectos.",'
              '"details":{"errors":[{"loc":["body","title"],"msg":"Campo obligatorio."},'
              '{"loc":["body","amount"],"msg":"Debe ser mayor que 0."}]}}}',
              400,
            )),
      );

      try {
        await client.post('/tickets');
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.fieldErrors['title'], contains('Campo obligatorio.'));
        expect(e.fieldErrors['amount'], contains('Debe ser mayor que 0.'));
      }
    });

    test('ValidationException.fieldErrors is empty for generic 400', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => http.Response(
              '{"error":{"message":"Error genérico."}}',
              400,
            )),
      );

      try {
        await client.post('/any');
        fail('Expected ValidationException');
      } on ValidationException catch (e) {
        expect(e.message, equals('Error genérico.'));
        expect(e.fieldErrors, isEmpty);
      }
    });
  });

  group('Ticket amount parsing', () {
    double? parseAmount(String input) {
      final normalized = input.replaceAll(',', '.');
      final val = double.tryParse(normalized);
      if (val == null || val <= 0) return null;
      return val;
    }

    test('parses integer amount', () => expect(parseAmount('42'), equals(42.0)));

    test('parses decimal with dot', () => expect(parseAmount('12.50'), equals(12.50)));

    test('parses decimal with comma (Spanish locale)', () =>
        expect(parseAmount('12,50'), equals(12.50)));

    test('rejects zero', () => expect(parseAmount('0'), isNull));

    test('rejects negative', () => expect(parseAmount('-5'), isNull));

    test('rejects non-numeric', () => expect(parseAmount('abc'), isNull));

    test('rejects empty string', () => expect(parseAmount(''), isNull));
  });

  group('Router role guard logic', () {
    const managerRoutes = {'/dashboard', '/employees'};

    bool isAllowed(String location, bool isManagerOrAbove) {
      if (managerRoutes.any((r) => location.startsWith(r))) {
        return isManagerOrAbove;
      }
      return true;
    }

    test('employee blocked from /dashboard', () {
      expect(isAllowed('/dashboard', false), isFalse);
    });

    test('employee blocked from /employees', () {
      expect(isAllowed('/employees', false), isFalse);
    });

    test('manager allowed in /dashboard', () {
      expect(isAllowed('/dashboard', true), isTrue);
    });

    test('employee allowed in /attendance', () {
      expect(isAllowed('/attendance', false), isTrue);
    });

    test('employee allowed in /tickets', () {
      expect(isAllowed('/tickets', false), isTrue);
    });
  });
}

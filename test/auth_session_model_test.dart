import 'package:clockly_mobile/data/models/auth/auth_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseSession({
  String? activeBusiness,
  List<Map<String, dynamic>>? businesses,
  List<String>? permissions,
}) =>
    {
      'access_token': 'tok_abc123',
      'user': {
        'id': 1,
        'full_name': 'Test User',
        'identifier': 'test',
        'global_role': 'admin',
      },
      'businesses': businesses ??
          [
            {'id': 'biz-1', 'name': 'Empresa A', 'slug': 'empresa-a'},
            {'id': 'biz-2', 'name': 'Empresa B', 'slug': 'empresa-b'},
          ],
      'permissions': permissions ?? ['view_dashboard', 'manage_employees'],
      if (activeBusiness != null) 'active_business_id': activeBusiness,
    };

void main() {
  group('AuthSessionModel.fromJson', () {
    test('parses access_token', () {
      final model = AuthSessionModel.fromJson(_baseSession());
      expect(model.accessToken, 'tok_abc123');
    });

    test('accepts "access" and "token" as alternative token keys', () {
      final byAccess = AuthSessionModel.fromJson({
        ..._baseSession(),
        'access_token': null,
        'access': 'tok_access',
      });
      final byToken = AuthSessionModel.fromJson({
        ..._baseSession(),
        'access_token': null,
        'token': 'tok_token',
      });
      expect(byAccess.accessToken, 'tok_access');
      expect(byToken.accessToken, 'tok_token');
    });

    test('parses businesses list', () {
      final model = AuthSessionModel.fromJson(_baseSession());
      expect(model.businesses.length, 2);
      expect(model.businesses.first.id, 'biz-1');
    });

    test('parses permissions list', () {
      final model = AuthSessionModel.fromJson(_baseSession());
      expect(model.permissions, containsAll(['view_dashboard', 'manage_employees']));
    });

    test('handles empty businesses and permissions gracefully', () {
      final model = AuthSessionModel.fromJson(_baseSession(businesses: [], permissions: []));
      expect(model.businesses, isEmpty);
      expect(model.permissions, isEmpty);
    });

    test('hasPermission returns true for granted permissions', () {
      final model = AuthSessionModel.fromJson(_baseSession());
      expect(model.hasPermission('view_dashboard'), isTrue);
      expect(model.hasPermission('delete_business'), isFalse);
    });
  });

  group('AuthSessionModel.activeBusiness', () {
    test('returns matching business when active_business_id is set', () {
      final model = AuthSessionModel.fromJson(_baseSession(activeBusiness: 'biz-2'));
      expect(model.activeBusiness?.id, 'biz-2');
      expect(model.activeBusiness?.name, 'Empresa B');
    });

    test('falls back to first business when active_business_id is absent', () {
      final model = AuthSessionModel.fromJson(_baseSession());
      expect(model.activeBusiness?.id, 'biz-1');
    });

    test('returns null when businesses list is empty', () {
      final model = AuthSessionModel.fromJson(_baseSession(businesses: []));
      expect(model.activeBusiness, isNull);
    });
  });
}

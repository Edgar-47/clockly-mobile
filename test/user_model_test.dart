import 'package:clockly_mobile/data/models/auth/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses canonical backend fields', () {
      final model = UserModel.fromJson({
        'id': 42,
        'full_name': 'Ada Lovelace',
        'identifier': 'ada.lovelace',
        'global_role': 'admin',
        'email': 'ada@clockly.io',
        'avatar_url': 'https://example.com/avatar.png',
      });

      expect(model.id, 42);
      expect(model.fullName, 'Ada Lovelace');
      expect(model.identifier, 'ada.lovelace');
      expect(model.globalRole, 'admin');
      expect(model.email, 'ada@clockly.io');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
    });

    test('accepts alternative field names for fullName', () {
      final byFullName = UserModel.fromJson({'id': 1, 'full_name': 'A', 'identifier': '', 'global_role': ''});
      final byName = UserModel.fromJson({'id': 1, 'name': 'B', 'identifier': '', 'global_role': ''});
      expect(byFullName.fullName, 'A');
      expect(byName.fullName, 'B');
    });

    test('accepts alternative field names for identifier', () {
      final byDni = UserModel.fromJson({'id': 1, 'full_name': '', 'dni': 'X1234Y', 'global_role': ''});
      final byUsername = UserModel.fromJson({'id': 1, 'full_name': '', 'username': 'johnd', 'global_role': ''});
      expect(byDni.identifier, 'X1234Y');
      expect(byUsername.identifier, 'johnd');
    });

    test('defaults global_role to employee when absent', () {
      final model = UserModel.fromJson({'id': 1, 'full_name': 'Bob', 'identifier': 'bob'});
      expect(model.globalRole, 'employee');
    });

    test('toEntity round-trips all fields', () {
      final model = UserModel.fromJson({
        'id': 7,
        'full_name': 'Grace Hopper',
        'identifier': 'grace',
        'global_role': 'manager',
        'email': 'grace@navy.mil',
        'avatar_url': null,
      });
      final entity = model.toEntity();

      expect(entity.id, 7);
      expect(entity.fullName, 'Grace Hopper');
      expect(entity.identifier, 'grace');
      expect(entity.globalRole, 'manager');
      expect(entity.email, 'grace@navy.mil');
      expect(entity.avatarUrl, isNull);
    });
  });
}

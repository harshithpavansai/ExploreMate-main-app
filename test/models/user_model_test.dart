import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/user_model.dart';

void main() {
  group('UserModel', () {
    // ── fromMap ──────────────────────────────────────────────────────────────
    group('fromMap', () {
      test('parses all fields correctly', () {
        final map = {
          'name': 'Arjun Kumar',
          'email': 'arjun@example.com',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'level': 4,
          'xp': 1240,
          'badges': ['Gem Hunter', 'Foodie'],
          'createdAt': '2024-01-15T00:00:00.000',
        };

        final user = UserModel.fromMap('uid-001', map);

        expect(user.uid, 'uid-001');
        expect(user.name, 'Arjun Kumar');
        expect(user.email, 'arjun@example.com');
        expect(user.avatarUrl, 'https://example.com/avatar.jpg');
        expect(user.level, 4);
        expect(user.xp, 1240);
        expect(user.badges, ['Gem Hunter', 'Foodie']);
        expect(user.createdAt, DateTime(2024, 1, 15));
      });

      test('applies defaults for missing optional fields', () {
        final map = {
          'name': 'Test',
          'email': 'test@example.com',
          'createdAt': '2024-01-01T00:00:00.000',
        };

        final user = UserModel.fromMap('uid-002', map);

        expect(user.avatarUrl, isNull);
        expect(user.level, 1);
        expect(user.xp, 0);
        expect(user.badges, isEmpty);
      });

      test('uses default name "Explorer" when name is missing', () {
        final map = {'email': 'x@y.com', 'createdAt': '2024-01-01T00:00:00.000'};
        final user = UserModel.fromMap('uid-003', map);
        expect(user.name, 'Explorer');
      });

      test('handles null badges list gracefully', () {
        final map = {
          'name': 'Test',
          'email': 'test@example.com',
          'badges': null,
          'createdAt': '2024-01-01T00:00:00.000',
        };
        final user = UserModel.fromMap('uid-004', map);
        expect(user.badges, isEmpty);
      });

      test('handles invalid createdAt by using DateTime.now()', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final map = {
          'name': 'Test',
          'email': 'test@example.com',
          'createdAt': 'not-a-date',
        };
        final user = UserModel.fromMap('uid-005', map);
        expect(user.createdAt.isAfter(before), isTrue);
      });
    });

    // ── toMap ────────────────────────────────────────────────────────────────
    group('toMap', () {
      test('serializes all fields', () {
        final user = UserModel(
          uid: 'uid-001',
          name: 'Arjun',
          email: 'arjun@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
          level: 3,
          xp: 900,
          badges: const ['Foodie'],
          createdAt: DateTime(2024, 6, 1),
        );

        final map = user.toMap();

        expect(map['name'], 'Arjun');
        expect(map['email'], 'arjun@example.com');
        expect(map['avatarUrl'], 'https://example.com/avatar.jpg');
        expect(map['level'], 3);
        expect(map['xp'], 900);
        expect(map['badges'], ['Foodie']);
        expect(map['createdAt'], '2024-06-01T00:00:00.000');
      });

      test('omits avatarUrl when null', () {
        final user = UserModel(
          uid: 'uid-002',
          name: 'Test',
          email: 'test@test.com',
          createdAt: DateTime.now(),
        );
        final map = user.toMap();
        expect(map.containsKey('avatarUrl'), isFalse);
      });
    });

    // ── fromMap → toMap round-trip ────────────────────────────────────────────
    test('fromMap → toMap round-trips correctly', () {
      final original = {
        'name': 'Priya',
        'email': 'priya@example.com',
        'level': 6,
        'xp': 2850,
        'badges': ['Wanderlust', 'Linguist'],
        'createdAt': '2023-11-20T00:00:00.000',
      };

      final user = UserModel.fromMap('uid-priya', original);
      final restored = user.toMap();

      expect(restored['name'], original['name']);
      expect(restored['email'], original['email']);
      expect(restored['level'], original['level']);
      expect(restored['xp'], original['xp']);
      expect(restored['badges'], original['badges']);
    });

    // ── copyWith ─────────────────────────────────────────────────────────────
    group('copyWith', () {
      final base = UserModel(
        uid: 'uid-001',
        name: 'Base',
        email: 'base@test.com',
        level: 1,
        xp: 0,
        createdAt: DateTime(2024),
      );

      test('creates new instance with updated xp', () {
        final updated = base.copyWith(xp: 500, level: 2);
        expect(updated.xp, 500);
        expect(updated.level, 2);
        expect(updated.uid, base.uid); // uid is immutable
        expect(updated.email, base.email);
      });

      test('leaves unspecified fields unchanged', () {
        final updated = base.copyWith(name: 'NewName');
        expect(updated.name, 'NewName');
        expect(updated.xp, base.xp);
        expect(updated.level, base.level);
      });
    });

    // ── toString ─────────────────────────────────────────────────────────────
    test('toString includes uid, name, level and xp', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Ravi',
        email: 'r@r.com',
        level: 3,
        xp: 650,
        createdAt: DateTime.now(),
      );
      expect(user.toString(), contains('u1'));
      expect(user.toString(), contains('Ravi'));
      expect(user.toString(), contains('lv3'));
      expect(user.toString(), contains('650xp'));
    });
  });
}

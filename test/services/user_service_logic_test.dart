import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/user_model.dart';
import 'package:exploremate/services/user_service.dart';

/// Tests for the pure business-logic methods of [UserService].
/// These tests do NOT require a real Firestore connection — they exercise
/// the static helper methods that can be called without any Firebase context.
void main() {
  group('UserService — pure business logic', () {
    // ── calculateLevel ────────────────────────────────────────────────────────
    group('calculateLevel(xp)', () {
      test('0 XP → level 1', () {
        expect(UserService.calculateLevel(0), 1);
      });

      test('499 XP → still level 1 (threshold is 500)', () {
        expect(UserService.calculateLevel(499), 1);
      });

      test('500 XP → level 2', () {
        expect(UserService.calculateLevel(500), 2);
      });

      test('999 XP → still level 2 (threshold is 1000)', () {
        expect(UserService.calculateLevel(999), 2);
      });

      test('1000 XP → level 3', () {
        expect(UserService.calculateLevel(1000), 3);
      });

      test('1499 XP → still level 3 (threshold is 1500)', () {
        expect(UserService.calculateLevel(1499), 3);
      });

      test('1500 XP → level 4', () {
        expect(UserService.calculateLevel(1500), 4);
      });

      test('2850 XP → level 6', () {
        // Level thresholds: L1=0, L2=500, L3=1000, L4=1500, L5=2000, L6=2500
        expect(UserService.calculateLevel(2850), 6);
      });

      test('level is monotonically non-decreasing with XP', () {
        int prevLevel = 1;
        for (int xp = 0; xp <= 5000; xp += 100) {
          final level = UserService.calculateLevel(xp);
          expect(level, greaterThanOrEqualTo(prevLevel));
          prevLevel = level;
        }
      });
    });

    // ── calculateLevelProgress ────────────────────────────────────────────────
    group('calculateLevelProgress(user)', () {
      UserModel buildUser({required int xp, required int level}) => UserModel(
            uid: 'u',
            name: 'Test',
            email: 't@t.com',
            xp: xp,
            level: level,
            createdAt: DateTime.now(),
          );

      test('0% progress at start of level (xp == lower bound)', () {
        // Level 1: lower=0, upper=500
        final progress = UserService.calculateLevelProgress(buildUser(xp: 0, level: 1));
        expect(progress, closeTo(0.0, 0.001));
      });

      test('50% progress at midpoint', () {
        // Level 1: 0..500, midpoint = 250
        final progress =
            UserService.calculateLevelProgress(buildUser(xp: 250, level: 1));
        expect(progress, closeTo(0.5, 0.001));
      });

      test('100% progress at upper bound', () {
        // Level 1: 0..500, top = 499 (still level 1)
        final progress =
            UserService.calculateLevelProgress(buildUser(xp: 499, level: 1));
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThan(0.99));
      });

      test('result is always clamped to [0, 1]', () {
        // Overflow scenario
        final progress =
            UserService.calculateLevelProgress(buildUser(xp: 10000, level: 1));
        expect(progress, lessThanOrEqualTo(1.0));
        expect(progress, greaterThanOrEqualTo(0.0));
      });

      test('progress is monotonically increasing within a level band', () {
        double prev = -1;
        for (int xp = 0; xp < 500; xp += 50) {
          final p =
              UserService.calculateLevelProgress(buildUser(xp: xp, level: 1));
          expect(p, greaterThanOrEqualTo(prev));
          prev = p;
        }
      });
    });

    // ── XP + Level integration ────────────────────────────────────────────────
    group('XP & Level integration', () {
      test('levelling up from 490 xp + 20 delta → level 2', () {
        const startXp = 490;
        const delta = 20;
        const newXp = startXp + delta; // 510
        final newLevel = UserService.calculateLevel(newXp);
        expect(newLevel, 2);
      });

      test('no level-up when XP stays below threshold', () {
        const startXp = 100;
        const delta = 50;
        const newXp = startXp + delta;
        final newLevel = UserService.calculateLevel(newXp);
        expect(newLevel, 1);
      });

      test('multiple level jumps are handled correctly', () {
        // Jump straight from 0 to 3000 XP
        expect(UserService.calculateLevel(3000), 7);
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:exploremate/models/user_model.dart';
import 'package:exploremate/services/user_service.dart';

void main() {
  group('UserService XP & Level Logic', () {
    test('calculateLevel returns correct level for given XP', () {
      expect(UserService.calculateLevel(0), 1);
      expect(UserService.calculateLevel(499), 1);
      expect(UserService.calculateLevel(500), 2);
      expect(UserService.calculateLevel(1000), 3);
      expect(UserService.calculateLevel(1500), 4);
    });

    test('calculateLevelProgress returns correct progress fraction', () {
      final userLevel1Start = UserModel(uid: '1', name: 'Test', email: 'test@test.com', xp: 0, level: 1, createdAt: DateTime.now());
      expect(UserService.calculateLevelProgress(userLevel1Start), 0.0);

      final userLevel1Mid = UserModel(uid: '1', name: 'Test', email: 'test@test.com', xp: 250, level: 1, createdAt: DateTime.now());
      expect(UserService.calculateLevelProgress(userLevel1Mid), 0.5);

      final userLevel2Start = UserModel(uid: '1', name: 'Test', email: 'test@test.com', xp: 500, level: 2, createdAt: DateTime.now());
      expect(UserService.calculateLevelProgress(userLevel2Start), 0.0);

      final userLevel2Mid = UserModel(uid: '1', name: 'Test', email: 'test@test.com', xp: 750, level: 2, createdAt: DateTime.now());
      expect(UserService.calculateLevelProgress(userLevel2Mid), 0.5);
      
      final userLevel2Max = UserModel(uid: '1', name: 'Test', email: 'test@test.com', xp: 1000, level: 2, createdAt: DateTime.now());
      expect(UserService.calculateLevelProgress(userLevel2Max), 1.0);
    });
  });
}

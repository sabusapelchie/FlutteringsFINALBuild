import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//so eto, handles both levels and sub-levels. User unlocked levels specifically. 
class LevelService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadLevels() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final userMeta = await supabase
          .from('users_meta')
          .select('unlocked_levels')
          .eq('user_id', user.id)
          .maybeSingle();

      final unlockedLevels =
          (userMeta?['unlocked_levels'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [];

      final allLevels = await supabase
          .from('levels')
          .select()
          .order('id', ascending: true);

      return allLevels.map<Map<String, dynamic>>((level) {
        final levelId = level['id'] as int;

        return {
          ...level,
          'is_unlocked':
              unlockedLevels.contains(levelId) || level['is_default'] == true,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadLevels ERROR: $e\n$st');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> loadSubLevels(int levelId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final subLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', levelId)
          .order('id', ascending: true);

      final userLevels = await supabase
          .from('user_levels')
          .select()
          .eq('user_id', user.id);

      final Map<int, Map<String, dynamic>> userLevelMap = {
        for (var row in userLevels) row['sub_level_id'] as int: row
      };

      return subLevels.map<Map<String, dynamic>>((s) {
        final id = s['id'] as int;
        final userRow = userLevelMap[id];

        final isUnlocked = userRow != null
            ? (userRow['is_unlocked'] == true ||
                userRow['is_completed'] == true)
            : s['is_default'] == true;

        return {
          ...s,
          'is_unlocked': isUnlocked,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('loadSubLevels ERROR: $e\n$st');
      return [];
    }
  }

  Future<void> completeSubLevel(String userId, int subLevelId) async {
    try {
      await supabase.from('user_levels').upsert({
        'user_id': userId,
        'sub_level_id': subLevelId,
        'is_completed': true,
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      final current = await supabase
          .from('sub_levels')
          .select()
          .eq('id', subLevelId)
          .maybeSingle();

      if (current == null) return;

      final levelId = current['level_id'] as int;

      final subLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', levelId)
          .order('id', ascending: true);

      Map<String, dynamic>? nextSubLevel;
      for (var s in subLevels) {
        final subId = s['id'] as int;

        if (subId == subLevelId) continue;

        final userSub = await supabase
            .from('user_levels')
            .select()
            .eq('user_id', userId)
            .eq('sub_level_id', subId)
            .maybeSingle();

        if (userSub == null || userSub['is_completed'] != true) {
          nextSubLevel = s;
          break;
        }
      }

      if (nextSubLevel != null) {
        await supabase.from('user_levels').upsert({
          'user_id': userId,
          'sub_level_id': nextSubLevel['id'],
          'is_unlocked': true,
        }, onConflict: 'user_id,sub_level_id');
        return;
      }

      final nextLevel = await supabase
          .from('levels')
          .select()
          .gt('id', levelId)
          .order('id', ascending: true)
          .limit(1)
          .maybeSingle();

      if (nextLevel == null) return;

      final nextLevelSubLevels = await supabase
          .from('sub_levels')
          .select()
          .eq('level_id', nextLevel['id'])
          .order('id', ascending: true);

      if (nextLevelSubLevels.isEmpty) return;

      await supabase.from('user_levels').upsert({
        'user_id': userId,
        'sub_level_id': nextLevelSubLevels.first['id'],
        'is_unlocked': true,
      }, onConflict: 'user_id,sub_level_id');

      final userMeta = await supabase
          .from('users_meta')
          .select('unlocked_levels')
          .eq('user_id', userId)
          .maybeSingle();

      List<int> unlockedLevels =
          List<int>.from(userMeta?['unlocked_levels'] ?? []);

      if (!unlockedLevels.contains(nextLevel['id'])) {
        unlockedLevels.add(nextLevel['id']);
        await supabase
            .from('users_meta')
            .update({'unlocked_levels': unlockedLevels})
            .eq('user_id', userId);
      }
    } catch (e, st) {
      debugPrint('completeSubLevel ERROR: $e\n$st');
    }
  }
}

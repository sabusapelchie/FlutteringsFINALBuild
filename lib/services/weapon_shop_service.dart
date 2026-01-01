import 'package:supabase_flutter/supabase_flutter.dart';

//Un self explanatory. Dito ka bibili ng mga wepaons. Prices ng weapons, user weapons
class WeaponShopService {
  final supabase = Supabase.instance.client;
  Future<List<Map<String, dynamic>>> loadWeapons() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('weapons')
        .select('*, user_weapons!left(is_unlocked, user_id)');

    return res.map<Map<String, dynamic>>((w) {
      final bool isDefault = w['is_default'] == true;

      final userWeapon = (w['user_weapons'] as List)
          .where((uw) => uw['user_id'] == userId)
          .toList();

      final bool isUnlocked = isDefault ||
          (userWeapon.isNotEmpty && userWeapon.first['is_unlocked'] == true);

      return {
        ...w,
        'is_unlocked': isUnlocked,
      };
    }).toList();
  }

  Future<int> getCoins() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('users_meta')
        .select('coins')
        .eq('user_id', userId)
        .single();

    return res['coins'];
  }

  Future<int?> getSelectedWeaponId() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('users_meta')
        .select('selected_weapon_id')
        .eq('user_id', userId)
        .single();

    return res['selected_weapon_id'];
  }

  Future<bool> buyWeapon(int weaponId, int price) async {
    final userId = supabase.auth.currentUser!.id;

    final coins = await getCoins();
    if (coins < price) return false;

    await supabase.from('users_meta').update({
      'coins': coins - price,
    }).eq('user_id', userId);

    await supabase.from('user_weapons').upsert({
      'user_id': userId,
      'weapon_id': weaponId,
      'is_unlocked': true,
    });

    return true;
  }

  Future<void> selectWeapon(int weaponId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('users_meta')
        .update({'selected_weapon_id': weaponId})
        .eq('user_id', userId);
  }
}

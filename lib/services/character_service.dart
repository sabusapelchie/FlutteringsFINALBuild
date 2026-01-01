import 'package:supabase_flutter/supabase_flutter.dart';

//Basically, ung service na to is naghahandle sa user owned characters, characters, buying characters.
class CharacterService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> loadCharacters() async {
    final userId = supabase.auth.currentUser!.id;

    final res = await supabase
        .from('characters')
        .select('*, user_characters!left(is_unlocked, user_id)')
        .order('id');

    final List<Map<String, dynamic>> sorted =
        List<Map<String, dynamic>>.from(res)
          ..sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    return sorted.map<Map<String, dynamic>>((c) {
      final bool isDefault = c['is_default'] == true;

      final List userChars = (c['user_characters'] as List)
          .where((uc) => uc['user_id'] == userId)
          .toList();

      final bool isUnlocked =
          isDefault || (userChars.isNotEmpty && userChars.first['is_unlocked'] == true);

      return {
        ...c,
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

    return res['coins'] as int;
  }

  Future<bool> buyCharacter(int characterId, int price) async {
    final userId = supabase.auth.currentUser!.id;

    final coins = await getCoins();
    if (coins < price) return false;

    await supabase
        .from('users_meta')
        .update({'coins': coins - price})
        .eq('user_id', userId);

    await supabase.from('user_characters').upsert({
      'user_id': userId,
      'character_id': characterId,
      'is_unlocked': true,
    });

    return true;
  }

  Future<void> selectCharacter(int characterId) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase
        .from('users_meta')
        .update({'selected_character_id': characterId})
        .eq('user_id', userId);
  }
}

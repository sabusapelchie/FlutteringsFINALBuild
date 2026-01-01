import 'package:supabase_flutter/supabase_flutter.dart';

//Naghahandle ng leaderboard system, paramihan sila ng coins, kills, ranking.
class LeaderboardService {
  final supabase = Supabase.instance.client;
  static const int pageSize = 20;

  Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String type, // 'coins' or 'enemy_kills'
    required int page,
    String? search,
  }) async {
    final res = await supabase.rpc(
      'fetch_leaderboard',
      params: {
        'p_type': type,
        'p_limit': pageSize,
        'p_offset': page * pageSize,
        'p_search': search,
      },
    );

    return List<Map<String, dynamic>>.from(res);
  }

  Future<int?> getUserRank(String type, String username) async {
    final res = await supabase.rpc(
      'get_user_rank',
      params: {
        'p_type': type,
        'p_username': username,
      },
    );

    return res as int?;
  }
}

import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';
import '../widgets/neon_card.dart';

//Yan, dito ung competitive side ng game niyo. Leaderboards. dinidisplay dito ung total of kills, coins, and mga batak mag Flutterings na players.
//December 31, 2025, 9:04 PM ko to tinatype before new year, nalaglag ung cake ko
class LeaderboardPage extends StatefulWidget {
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final service = LeaderboardService();

  int page = 0;
  String search = '';
  bool loading = false;

  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        page = 0;
        load();
      });
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    data = await service.fetchLeaderboard(
      type: _tabController.index == 0 ? 'enemy_kills' : 'coins',
      page: page,
      search: search,
    );
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboards"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Kills"),
            Tab(text: "Coins"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search username",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                search = v;
                page = 0;
                load();
              },
            ),
          ),
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final row = data[i];
                      final rank = row['rank'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: NeonCard(
                          child: Row(
                            children: [
                              Text(
                                "#$rank",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E5FF),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  row['username'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Text(
                                _tabController.index == 0
                                    ? "${row['enemy_kills']} kills"
                                    : "🪙 ${row['coins']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB388FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: page > 0
                    ? () {
                        page--;
                        load();
                      }
                    : null,
                child: Text("Prev"),
              ),
              TextButton(
                onPressed: data.length == LeaderboardService.pageSize
                    ? () {
                        page++;
                        load();
                      }
                    : null,
                child: Text("Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

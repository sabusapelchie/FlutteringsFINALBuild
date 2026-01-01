import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/character_service.dart';
import 'level_selection_page.dart';

//Screen or page na kung saan ka namimili ng characters. Bale 4 lang yan. Pwede mo iedit or expand through supabase.
class CharacterSelectionPage extends StatefulWidget {
  @override
  State<CharacterSelectionPage> createState() => _CharacterSelectionPageState();
}

class _CharacterSelectionPageState extends State<CharacterSelectionPage>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController(viewportFraction: 0.6);
  final CharacterService _characterService = CharacterService();

  late final Ticker _coinTicker;

  int currentPage = 0;
  int coins = 0;
  List<Map<String, dynamic>> characters = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCharacters();

    _coinTicker = Ticker((_) async {
      final c = await _characterService.getCoins();
      if (mounted && c != coins) {
        setState(() => coins = c);
      }
    })..start();
  }

  Future<void> loadCharacters() async {
    final data = await _characterService.loadCharacters();
    final c = await _characterService.getCoins();

    setState(() {
      characters = data;
      coins = c;
      loading = false;
    });
  }

  @override
  void dispose() {
    _coinTicker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final c = characters[currentPage];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Characters"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.lightBlueAccent,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  coins.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 380,
            child: PageView.builder(
              controller: _controller,
              itemCount: characters.length,
              onPageChanged: (i) => setState(() => currentPage = i),
              itemBuilder: (context, index) {
                final char = characters[index];
                final angle = (index - currentPage) * 0.3;

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: Opacity(
                    opacity: char['is_unlocked'] ? 1 : 0.5,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: char['is_unlocked']
                              ? Colors.white
                              : Colors.redAccent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            char['name'],
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Image.asset(
                              "assets/character sprites/${char['sprite_path']}",
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              gaplessPlayback: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          Text(
            c['is_unlocked']
                ? "This character is unlocked."
                : "Locked. Buy to unlock.",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (c['is_unlocked']) {
                  await _characterService.selectCharacter(c['id']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelSelectionPage(),
                    ),
                  );
                } else {
                  final success = await _characterService.buyCharacter(
                    c['id'],
                    c['price'],
                  );

                  if (success) {
                    await loadCharacters();
                  }
                }
              },
              child: Text(
                c['is_unlocked']
                    ? "Select"
                    : "Buy (${c['price']} coins)",
              ),
            ),
          ),
        ],
      ),
    );
  }
}

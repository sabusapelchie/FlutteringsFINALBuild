import 'package:flutter/material.dart';
import '../services/level_service.dart';
import '../services/background_music_service.dart';
import 'game_page.dart';
import '../widgets/neon_card.dart';

class SubLevelSelectionPage extends StatefulWidget {
  final Map<String, dynamic> level;
  const SubLevelSelectionPage({required this.level});

  @override
  State<SubLevelSelectionPage> createState() =>
      _SubLevelSelectionPageState();
}

class _SubLevelSelectionPageState extends State<SubLevelSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.6);
  final LevelService _levelService = LevelService();
  final BackgroundMusicService _music = BackgroundMusicService();

  int currentPage = 0;
  List<Map<String, dynamic>> subLevels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();

    final musicAsset = widget.level['music_asset'];
    if (musicAsset != null && musicAsset.toString().isNotEmpty) {
      _music.playLevelMusic(musicAsset);
    }

    _loadSubLevels();
  }

  @override
  void dispose() {
    _music.playDefault();
    super.dispose();
  }

  Future<void> _loadSubLevels() async {
    setState(() => loading = true);
    final data = await _levelService.loadSubLevels(widget.level['id']);
    setState(() {
      subLevels = data;
      loading = false;
    });
  }

  void _openGamePage(Map<String, dynamic> subLevel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          level: widget.level,
          subLevel: subLevel,
          onLevelComplete: () async {
            await _loadSubLevels();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Sub-Level")),
      body: Center(
        child: SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _controller,
            itemCount: subLevels.length,
            onPageChanged: (i) => setState(() => currentPage = i),
            itemBuilder: (context, index) {
              final sub = subLevels[index];
              final unlocked = sub['is_unlocked'] == true;

              return AnimatedScale(
                scale: currentPage == index ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: Opacity(
                  opacity: unlocked ? 1 : 0.4,
                  child: NeonCard(
                    onTap: unlocked ? () => _openGamePage(sub) : null,
                    child: Center(
                      child: Text(
                        sub['name'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

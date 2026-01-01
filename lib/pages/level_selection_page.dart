import 'package:flutter/material.dart';
import '../services/level_service.dart';
import 'sub_level_selection_page.dart';
import '../widgets/neon_card.dart';

//Oops wait wait. Wag malilito sa levels and sub-levels. Ang levels, parang container yan. Sub-levels is areas na papasukan niyo.
//Dito makikita mga levels, same as teh character selection, meron din siya carousel effect.
class LevelSelectionPage extends StatefulWidget {
  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  final PageController _controller = PageController(viewportFraction: 0.7);
  final LevelService _levelService = LevelService();

  int currentPage = 0;
  List<Map<String, dynamic>> levels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    final data = await _levelService.loadLevels();
    setState(() {
      levels = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Biome")),
      body: Center(
        child: SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: levels.length,
            onPageChanged: (i) => setState(() => currentPage = i),
            itemBuilder: (context, index) {
              final level = levels[index];
              final unlocked = level['is_unlocked'] == true;

              return AnimatedScale(
                scale: currentPage == index ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                child: Opacity(
                  opacity: unlocked ? 1 : 0.4,
                  child: NeonCard(
                    onTap: unlocked
                        ? () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SubLevelSelectionPage(level: level),
                              ),
                            );
                            _loadLevels();
                          }
                        : null,
                    child: Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: AssetImage(
                            "assets/images/background/${level['background_image']}",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          level['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
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

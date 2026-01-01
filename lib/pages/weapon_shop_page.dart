import 'package:flutter/material.dart';
import '../services/weapon_shop_service.dart';
import '../widgets/neon_card.dart';

//Dito kung saan ka nabili ng weapons. 
class WeaponShopPage extends StatefulWidget {
  @override
  State<WeaponShopPage> createState() => _WeaponShopPageState();
}

class _WeaponShopPageState extends State<WeaponShopPage> {
  final WeaponShopService _service = WeaponShopService();

  List<Map<String, dynamic>> weapons = [];
  int coins = 0;
  int? selectedWeaponId;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final w = await _service.loadWeapons();
    final c = await _service.getCoins();
    final s = await _service.getSelectedWeaponId();

    if (!mounted) return;
    setState(() {
      weapons = w;
      coins = c;
      selectedWeaponId = s;
    });
  }

  int _columns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 1;
    if (width < 1000) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weapon Shop"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.lightBlueAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "$coins",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),

            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns(context),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: weapons.length,
        itemBuilder: (_, i) {
          final w = weapons[i];
          final bool equipped = w['id'] == selectedWeaponId;
          final bool unlocked = w['is_unlocked'] == true;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: equipped
                ? null
                : () async {
                    if (unlocked) {
                      await _service.selectWeapon(w['id']);
                    } else {
                      final ok =
                          await _service.buyWeapon(w['id'], w['price']);
                      if (!ok) return;
                    }
                    await load();
                  },
            child: NeonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 220,
                    child: Image.asset(
                      w['sprite_path'],
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          w['name'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("DMG: ${w['damage']}"),
                        const SizedBox(height: 4),
                        Text("🪙 ${w['price']}"),
                      ],
                    ),
                  ),

                  const Spacer(),
                  Container(
                    height: 72,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: equipped
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      equipped
                          ? "EQUIPPED"
                          : unlocked
                              ? "SELECT"
                              : "BUY",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

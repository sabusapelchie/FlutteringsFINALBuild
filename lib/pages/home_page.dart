import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/character_service.dart';
import 'character_selection_page.dart';
import 'weapon_shop_page.dart';
import 'leaderboard_page.dart';
import 'sign_in_page.dart';

//Starting page once na mag log in kayo. Nandito Character selection page, leaderboards, shop screens displayed as bodies ng home page.
//Isipin niyo nalang parang plato ung home page.
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CharacterService _service = CharacterService();
  int coins = 0;
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    CharacterSelectionPage(),
    WeaponShopPage(),
    LeaderboardPage(),
  ];

  @override
  void initState() {
    super.initState();
    loadCoins();
  }

  Future<void> loadCoins() async {
    final c = await _service.getCoins();
    setState(() => coins = c);
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SignInPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: _tabs[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF0E0E0E),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          if (index == 3) {
            _logout();
            return;
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Characters",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: "Shop",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: "Leaderboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),
    );
  }
}

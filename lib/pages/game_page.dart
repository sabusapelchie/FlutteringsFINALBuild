//mapapa holy shit ka sa dami. Plano ko sana na itransfer ibang contents dito kaso wala na ako time, mostly burnout na din kasi ako, so yan. 
//Script with the most lines of code ng project niyo
//Pero eto kailangan niyo tandaan. Basically what this is, is eto mismo kung saan nangyayari ung pinaka game mismo.
//loading data, enemy spawning, character, waves, weapons initialization.
//So makikita niyo and daming imports. Ung game page magdedecide kung ano mismo ung mangyayari, like some kind of dirty game manager kumbaga.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import '../game/character.dart';
import '../game/world.dart';
import '../game/platform.dart';
import '../game/enemy.dart';
import '../game/projectile.dart';
import '../game/weapon.dart';
import '../services/weapon_service.dart';
import '../services/enemy_service.dart';
import '../services/level_service.dart';
import 'level_selection_page.dart';
import 'sub_level_selection_page.dart';
import '../game/particle.dart';
import '../game/particle_emitter.dart';
import '../game/particle_factory.dart';
import '../widgets/neon_card.dart';
import '../theme/neon_theme.dart';

class GamePage extends StatefulWidget {
  final Map<String, dynamic> level;
  final Map<String, dynamic> subLevel;
  final VoidCallback? onLevelComplete;

  GamePage({
    required this.level,
    required this.subLevel,
    this.onLevelComplete,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

//Eto, nilagyan ko comments kung saan tong mga to ginagamit. Para mapadali buhay niyo.
class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  
// CORE GAME STATE
// Used by: game loop, world update, rendering, restart logic
  late Character character;
  late World world;
  
  // Screen metrics used everywhere (world, enemies, UI, spawning)
  double screenWidth = 0;
  double screenHeight = 0;
  
  // Global runtime flags used by game loop, dialogs, input gating
  bool gameOver = false;
  bool paused = false;
  bool levelComplete = false;
  
  // Time tracking for fixed-ish timestep game loop
  late DateTime _lastTime;
  
  // GAME LOOP & INPUT
  // Used by: startGameLoop(), _gameTick()
  late AnimationController _controller;
  
  // Used by: accelerometer dodge + facing direction
  StreamSubscription? _accelerometerSubscription;
  double latestTiltX = 0.0;
  
  // Medyo physics constant (used by world / character)
  double gravity = 800.0;
  
  // SPAWNING & WAVES
  // Used by: _updateSpawner(), restart logic
  int currentWave = 1;
  late int maxWaves;
  
  // Wave definitions + runtime counters
  Map<int, List<WaveEntry>> wavePool = {};
  Map<int, List<int>> originalWaveCounts = {};
  
  // Spawn timing control
  final double minSpawnInterval = 1.0;
  final double maxSpawnInterval = 3.0;
  double nextSpawnIn = 0.0;
  
  // Randomization for spawn positions & timing
  final Random random = Random();
  
  // Vertical offset for initial spawn/platform placement
  final double spawnYOffset = 150;
  
  // ENEMIES & PROJECTILES
  // Used by: enemy updates, collision checks, rendering
  List<Enemy> enemies = [];
  
  // Used by: enemy & player projectile updates
  List<Projectile> activeProjectiles = [];
  
  // WEAPONS & COMBAT
  // Equipped player weapon
  Weapon? equippedWeapon;
  
  // Weapon firing control
  double timeSinceLastShot = 0.0;
  double weaponAngle = 0.0;
  
  // Sprite dimensions for weapon & projectiles (render + collision)
  final double weaponW = 48.0;
  final double weaponH = 24.0;
  final double projW = 48.0;
  final double projH = 24.0;
  
  // PARTICLES & VFX
  // Used by: dodge effects, hits, enemy death, summons
  List<Particle> particles = [];
    
  // SERVICES / BACKEND
  // Used by: data loading, spawning, progression, persistence
  late EnemyService enemyService;
  late WeaponService weaponService;
  late LevelService levelService;
  
  // RUN STATS / REWARDS
  // Used by: level completion, Supabase RPCs
  int runCoins = 0;
  int runKills = 0;
  
  @override
  void initState() {
    super.initState();
    levelService = LevelService();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadGameData();
      nextSpawnIn = 0.5 + random.nextDouble();
      startGameLoop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGameData() async {
    enemyService = EnemyService();
    weaponService = WeaponService();

    wavePool =
        await enemyService.loadWavePool(widget.subLevel['id'], 0, -120);
    maxWaves = enemyService.getMaxWave(wavePool);

    for (var entry in wavePool.entries) {
      originalWaveCounts[entry.key] =
          entry.value.map((e) => e.remaining).toList();
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final metaRaw = await supabase
        .from('users_meta')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final meta = metaRaw as Map<String, dynamic>?;
    if (meta == null || meta['selected_character_id'] == null) return;

    final charRaw = await supabase
        .from('characters')
        .select()
        .eq('id', meta['selected_character_id'])
        .maybeSingle();

    final charData = charRaw as Map<String, dynamic>?;
    if (charData == null) return;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    character = Character(
      x: screenWidth / 2 - 40,
      y: screenHeight - spawnYOffset - 80,
      width: 80,
      height: 80,
      jumpStrength: charData['jump_strength']?.toDouble() ?? 20.0,
      spritePath: charData['sprite_path'],
      horizontalSpeedMultiplier: charData['speed']?.toDouble() ?? 200.0,
      maxHealth: (charData['max_health'] ?? 100) as int,
      currentHealth: (charData['current_health'] ?? 100) as int,
    );

    character.dodgeParticleConfig = charData['dodge_particle'];
    character.dodgeDuration =
        (charData['dodge_duration'] ?? 2.0).toDouble();
    character.dodgeCooldown =
        (charData['dodge_cooldown'] ?? 1.0).toDouble();
    character.dodgeShakeThreshold =
        (charData['dodge_shake_threshold'] ?? 18.0).toDouble();

    world = World(
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      character: character,
      platformColor: _hex(widget.level['platform_color']),
      platformGlowColor: _hex(widget.level['platform_glow_color']),
      platformGapMin: widget.level['platform_gap_min'],
      platformGapMax: widget.level['platform_gap_max'],
      platformWidth: widget.level['platform_width'].toDouble(),
    );

    _addStartingPlatform();

    final results = await Future.wait([
      weaponService.getUserWeapon(user.id),
    ]);

    equippedWeapon = results[0] as Weapon?;

    List<Future> precacheFutures = [];
    precacheFutures.add(
      precacheImage(AssetImage(character.spritePath), context),
    );

    if (equippedWeapon != null) {
      precacheFutures.add(
        precacheImage(AssetImage(equippedWeapon!.spritePath), context),
      );
      precacheFutures.add(
        precacheImage(
          AssetImage(equippedWeapon!.projectile.spritePath),
          context,
        ),
      );
    }

    await Future.wait(precacheFutures);
  }

  void startGameLoop() {
    _lastTime = DateTime.now();

    _controller = AnimationController(vsync: this)
      ..addListener(_gameTick);

    _controller.repeat(
      min: 0,
      max: 1,
      period: const Duration(milliseconds: 16),
    );

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (paused) return;

      final double shakeStrength = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      character.tryDodge(shakeStrength);

      latestTiltX = -event.x;
      character.facingRight = latestTiltX > 0.1
          ? true
          : latestTiltX < -0.1
              ? false
              : character.facingRight;
    });
  }

  void _gameTick() {
    final now = DateTime.now();
    double dt =
        now.difference(_lastTime).inMilliseconds / 1000.0;
    _lastTime = now;

    dt = dt.clamp(0.016, 0.033);

    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(dt);
      if (particles[i].isDead) {
        particles.removeAt(i);
      }
    }

    if (!paused && !gameOver) {
      _updateSpawner(dt);
      _updateEnemies(dt);
      world.update(latestTiltX, dt);
      updateWeapon(dt);
      character.updateDodge();

      if (character.dodgeJustStarted &&
          character.dodgeParticleConfig != null) {
        particles.addAll(
          ParticleFactory.fromConfig(
            x: character.x + character.width / 2,
            y: character.y + character.height / 2,
            config: character.dodgeParticleConfig,
          ),
        );
        character.dodgeJustStarted = false;
      }

      _checkGameOver();
      setState(() {});
    }
  }

  void _updateSpawner(double dt) {
    if (wavePool[currentWave] == null ||
        wavePool[currentWave]!.isEmpty) return;

    nextSpawnIn -= dt;

    if (nextSpawnIn <= 0) {
      Enemy? enemy = enemyService.pickRandomFromWave(
        wavePool[currentWave]!,
        random.nextDouble() * (screenWidth - 80),
        -60 - random.nextDouble() * 120,
      );

      if (enemy != null) {
        enemy.onParticlesRequested = (spawnedParticles) {
          particles.addAll(spawnedParticles);
        };

        enemies.add(enemy);

        nextSpawnIn = minSpawnInterval +
            random.nextDouble() *
                (maxSpawnInterval - minSpawnInterval);
      }
    }

    if (enemyService.isWaveComplete(
        wavePool[currentWave]!, enemies)) {
      if (currentWave < maxWaves) {
        currentWave++;
        nextSpawnIn = 0.5;
      } else if (!levelComplete) {
        levelComplete = true;
        gameOver = true;
        paused = true;
        _showCompleteDialog();
      }
    }
  }

  void _updateEnemies(double dt) {
    for (int i = enemies.length - 1; i >= 0; i--) {
      final e = enemies[i];
      e.update(character, dt, screenWidth, screenHeight);

      if (e.pendingSummons > 0 && e.pendingSummonIds.isNotEmpty) {
        for (final id in e.pendingSummonIds) {
          enemyService
              .spawnEnemyById(
                id,
                e.x + e.width / 2,
                e.y + e.height,
              )
              .then((summoned) {
            if (summoned != null && mounted) {
              enemies.add(summoned);
              particles.addAll(
                ParticleFactory.fromConfig(
                  x: summoned.x,
                  y: summoned.y,
                  config: e.summonParticleConfig,
                ),
              );
            }
          });
        }

        e.pendingSummonIds.clear();
        e.pendingSummons = 0;
      }

      for (int j = e.activeProjectiles.length - 1; j >= 0; j--) {
        final p = e.activeProjectiles[j];
        p.update(dt);

        if (p.x >= character.x &&
            p.x <= character.x + character.width &&
            p.y >= character.y &&
            p.y <= character.y + character.height) {
          particles.addAll(
            ParticleFactory.fromConfig(
              x: p.x,
              y: p.y,
              config: p.hitParticle,
            ),
          );

          character.takeDamage(p.damage);
          character.onHit();
          HapticFeedback.mediumImpact();
          e.activeProjectiles.removeAt(j);
          continue;
        }

        if (p.x < 0 ||
            p.x > screenWidth ||
            p.y < 0 ||
            p.y > screenHeight) {
          e.activeProjectiles.removeAt(j);
        }
      }

      if (e.y > screenHeight + 200) {
        enemies.removeAt(i);
      }
    }

    if (character.currentHealth <= 0 && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void updateWeapon(double dt) {
    timeSinceLastShot += dt;

    if (equippedWeapon != null && enemies.isNotEmpty) {
      enemies.sort((a, b) {
        double da =
            ((a.x + a.width / 2) -
                        (character.x + character.width / 2))
                    .abs() +
                ((a.y + a.height / 2) -
                        (character.y +
                            character.height / 2))
                    .abs();

        double db =
            ((b.x + b.width / 2) -
                        (character.x + character.width / 2))
                    .abs() +
                ((b.y + b.height / 2) -
                        (character.y +
                            character.height / 2))
                    .abs();

        return da.compareTo(db);
      });

      final target = enemies.first;

      double dx = (target.x + target.width / 2) -
          (character.x + character.width / 2);
      double dy = (target.y + target.height / 2) -
          (character.y + character.height / 2);

      weaponAngle = atan2(dy, dx);

      double fireInterval =
          1 / max(0.0001, equippedWeapon!.fireRate);

      if (timeSinceLastShot >= fireInterval) {
        timeSinceLastShot = 0;

        Projectile proj = Projectile(
          x: character.x + character.width / 2,
          y: character.y + character.height / 2,
          speed: equippedWeapon!.projectile.speed,
          damage: equippedWeapon!.damage,
          spritePath:
              equippedWeapon!.projectile.spritePath,
          hitParticle:
              equippedWeapon!.projectile.hitParticle,
        );

        double dist = sqrt(dx * dx + dy * dy);
        proj.vx = dx / dist * proj.speed;
        proj.vy = dy / dist * proj.speed;

        activeProjectiles.add(proj);
      }
    }

    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);

      bool shouldRemove = false;

      for (int j = enemies.length - 1; j >= 0; j--) {
        final e = enemies[j];

        if (!(p.x + projW / 2 < e.x ||
            p.x - projW / 2 > e.x + e.width ||
            p.y + projH / 2 < e.y ||
            p.y - projH / 2 > e.y + e.height)) {
          particles.addAll(
            ParticleFactory.fromConfig(
              x: p.x,
              y: p.y,
              config: p.hitParticle,
            ),
          );

          e.currentHealth -= p.damage;
          e.onHit();
          shouldRemove = true;

          if (e.currentHealth <= 0) {
            runCoins += e.coinReward;
            runKills += 1;
            enemies.removeAt(j);
          }
          break;
        }
      }

      if (!shouldRemove) {
        if (p.x + projW / 2 < 0 ||
            p.x - projW / 2 > screenWidth ||
            p.y + projH / 2 < 0 ||
            p.y - projH / 2 > screenHeight) {
          shouldRemove = true;
        }
      }

      if (shouldRemove) {
        activeProjectiles.removeAt(i);
      }
    }
  }

  void _checkGameOver() {
    if (character.y > screenHeight && !gameOver) {
      gameOver = true;
      paused = true;
      _showGameOverDialog();
    }
  }

  void _addStartingPlatform() {
    world.platforms.clear();
    world.platforms.add(
      Platform(
        x: screenWidth / 2 - 60,
        y: screenHeight - spawnYOffset,
        width: world.platformWidth,
        height: 20,
        color: world.platformColor,
        glowColor: world.platformGlowColor,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (levelComplete) {
      return false;
    }

    paused = true;

    bool? result = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Are you sure you want to go back?"),
        actions: [
          TextButton(
            onPressed: () {
              paused = false;
              Navigator.of(context).pop(false);
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showCompleteDialog() async {
    final user = supabase.auth.currentUser;

    gameOver = true;
    paused = true;
    levelComplete = true;

    if (user != null) {
      await levelService.completeSubLevel(
        user.id,
        widget.subLevel['id'],
      );
    }

    if (widget.onLevelComplete != null) {
      widget.onLevelComplete!();
    }

    if (user != null && runCoins > 0) {
      await supabase.rpc(
        'add_coins',
        params: {
          'p_user_id': user.id,
          'p_amount': runCoins,
        },
      );
    }

    if (user != null && runKills > 0) {
      await supabase.rpc(
        'add_enemy_kills',
        params: {
          'p_user_id': user.id,
          'p_amount': runKills,
        },
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: NeonCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "LEVEL COMPLETE",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: NeonTheme.neonBlue,
                      shadows: [
                        Shadow(
                          blurRadius: 24,
                          color: NeonTheme.neonBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "+$runCoins Coins\n$runKills Kills",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("BACK"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _restartGame();
                    },
                    child: const Text("TRY AGAIN"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: NeonCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "GAME OVER",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: NeonTheme.neonPurple,
                    shadows: [
                      Shadow(
                        blurRadius: 20,
                        color: NeonTheme.neonPurple,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  child: const Text("TRY AGAIN"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text("BACK"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restartGame() {
    paused = false;
    gameOver = false;
    levelComplete = false;

    enemies.clear();
    activeProjectiles.clear();

    character.x = screenWidth / 2 - character.width / 2;
    character.y =
        screenHeight - spawnYOffset - character.height;
    character.vy = 0;
    character.currentHealth = character.maxHealth;

    nextSpawnIn = 0.5;
    currentWave = 1;
    runCoins = 0;

    _addStartingPlatform();

    for (var entry in wavePool.entries) {
      for (int i = 0; i < entry.value.length; i++) {
        entry.value[i].remaining =
            originalWaveCounts[entry.key]![i];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/background/${widget.level['background_image']}",
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
              ),
            ),
            ...world.platforms.map((p) {
              return Positioned(
                bottom: screenHeight - p.y,
                left: p.x,
                child: Container(
                  width: p.width,
                  height: p.height,
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: p.glowColor.withOpacity(0.9),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            ...enemies.map(
              (e) => Positioned(
                bottom: screenHeight - e.y - e.height,
                left: e.x,
                child: e.buildWidget(),
              ),
            ),
            ...enemies.expand(
              (e) => e.activeProjectiles.map((p) {
                final left = p.x - projW / 2;
                final bottom =
                    screenHeight - p.y - projH / 2;
                final angle = atan2(p.vy, p.vx);

                return Positioned(
                  left: left,
                  bottom: bottom,
                  child: Transform.rotate(
                    angle: angle,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: projW,
                      height: projH,
                      child: Image.asset(
                        p.spritePath,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                );
              }),
            ),
            ...particles.map((p) => p.build(screenHeight)),
            Positioned(
              bottom: screenHeight -
                  character.y -
                  character.height,
              left: character.x,
              child: character.buildWidget(),
            ),
            if (equippedWeapon != null)
              Positioned(
                bottom: screenHeight -
                    (character.y + character.height / 2) -
                    weaponH / 2,
                left: character.x +
                    character.width / 2 -
                    weaponW / 2,
                child: Transform.rotate(
                  angle: weaponAngle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: weaponW,
                    height: weaponH,
                    child: Image.asset(
                      equippedWeapon!.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              ),
            ...activeProjectiles.map((p) {
              final left = p.x - projW / 2;
              final bottom =
                  screenHeight - p.y - projH / 2;
              final angle = atan2(p.vy, p.vx);

              return Positioned(
                left: left,
                bottom: bottom,
                child: Transform.rotate(
                  angle: angle,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: projW,
                    height: projH,
                    child: Image.asset(
                      p.spritePath,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: NeonCard(
                child: Row(
                  children: List.generate(maxWaves, (i) {
                    final active = (i + 1) <= currentWave;

                    return Expanded(
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 3),
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(8),
                          gradient: active
                              ? const LinearGradient(
                                  colors: [
                                    NeonTheme.neonBlue,
                                    NeonTheme.neonPurple,
                                  ],
                                )
                              : null,
                          border: Border.all(
                            color: NeonTheme.neonBlue
                                .withOpacity(0.6),
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: NeonTheme.neonBlue
                                        .withOpacity(0.9),
                                    blurRadius: 14,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: NeonCard(
                child: SizedBox(
                  width: 180,
                  height: 20,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(10),
                          border: Border.all(
                            color: NeonTheme.neonBlue,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NeonTheme.neonBlue
                                  .withOpacity(0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      AnimatedFractionallySizedBox(
                        duration:
                            const Duration(milliseconds: 200),
                        alignment: Alignment.centerLeft,
                        widthFactor: character.currentHealth /
                            character.maxHealth,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                NeonTheme.neonBlue,
                                NeonTheme.neonPurple,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: NeonTheme.neonPurple
                                    .withOpacity(0.9),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _hex(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

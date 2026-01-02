import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'character.dart';
import 'projectile.dart';
import 'particle_factory.dart';
import 'particle.dart';

//handles enemy types. So right now meron tatlong enemy types = hunter, drone, and summoner. 
//Ginagawa ng hunter is basically manunuka siya na parang ibon, melee range.
//Drone is basically ranged enemy, nag oorbit din yan sa character, tapos shoot projectile
//Summoner, latest na ginawa ko, basically ginagawa netong enemy na to is nagtatawag or gumagawa siya ng enemy (galing sa enemy_id ng supabase)
//So yeah, any enemy kaya niya isummon. Ginagamit lang siya ng Boss sa Nether level.
enum EnemyState { descending, observing, rushing, cooldown, summoning, drone_idle, drone_dashing }

class Enemy {
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  final double width;
  final double height;
  final String name;
  final String spritePath;
  int maxHealth;
  int currentHealth;
  int damage;
  double speed;
  Map<String, dynamic> behavior;
  EnemyState state = EnemyState.descending;
  double stateTimer = 0.0;
  double observeTargetX = 0.0;
  double observeTargetY = 0.0;
  final Random _rand = Random();

  bool isRetracting = false;
  double retractRemaining = 0.0;
  double retractSpeed = 150.0;
  double retractDirX = 0.0;
  double retractDirY = 0.0;

  double shootCooldown = 0.0;
  List<Projectile> activeProjectiles = [];

  double hoverTimer = 0.0;
  double hoverTargetX = 0.0;
  double hoverTargetY = 0.0;
  
  double summonTimer = 0.0;
  int summonedCount = 0;
  bool summonFinished = false;
  //bool requestSummon = false;
  //int? requestedEnemyId;
  int pendingSummons = 0;
  List<int> pendingSummonIds = [];

  Map<String, dynamic>? summonParticleConfig;
  double hoverAnchorX = 0;
  double hoverAnchorY = 0;
  double hoverPhase = 0;
  void Function(List<Particle>)? onParticlesRequested;

  double droneStopY = 0;
  double droneFireTimer = 0;
  double droneDashTimer = 0;
  double droneNextDashDelay = 0;
  
  double droneDashTargetX = 0;
  double droneDashTargetY = 0;
  double droneDashSpeed = 500;


  int coinReward;
  
  double hitFlashTimer = 0.0;

  Enemy({
    required this.x,
    required this.y,
    this.width = 60,
    this.height = 60,
    required this.name,
    required this.spritePath,
    required this.maxHealth,
    int? currentHealth,
    required this.damage,
    required this.speed,
    required this.behavior,
    required this.coinReward,
    
  }) : currentHealth = currentHealth ?? maxHealth {
    vx = (_rand.nextDouble() * 2 - 1) * (speed * 0.1);
    vy = (_rand.nextDouble() * 2 - 1) * (speed * 0.05);
    observeTargetX = x;
    observeTargetY = y;
  }

  factory Enemy.fromMap({
    required double x,
    required double y,
    required String name,
    required String spritePath,
    required int maxHealth,
    required int damage,
    required double speed,
    required Map<String, dynamic> behavior,
    required int coinReward,
    
  }) {
    return Enemy(
      x: x,
      y: y,
      name: name,
      spritePath: spritePath,
      maxHealth: maxHealth,
      damage: damage,
      speed: speed,
      behavior: behavior,
      coinReward: coinReward,
    );
  }

  Enemy cloneAt(double spawnX, double spawnY) {
    return Enemy.fromMap(
      x: spawnX,
      y: spawnY,
      name: name,
      spritePath: spritePath,
      maxHealth: maxHealth,
      damage: damage,
      speed: speed,
      behavior: Map<String, dynamic>.from(behavior),
      coinReward: coinReward,

    );
  }
  void onHit() {
    hitFlashTimer = 0.12;
  }

  void startRetract(double dx, double dy, double distance) {
    isRetracting = true;
    retractRemaining = distance;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > 0) {
      retractDirX = dx / dist;
      retractDirY = dy / dist;
    } else {
      retractDirX = 0;
      retractDirY = 0;
    }
    state = EnemyState.cooldown;
    stateTimer = 0;
  }
  void update(Character character, double dt, double screenW, double screenH) {
    if (hitFlashTimer > 0) {
      hitFlashTimer -= dt;
      if (hitFlashTimer < 0) hitFlashTimer = 0;
    }

    if (isRetracting) {
      final move = min(retractSpeed * dt, retractRemaining);
      x += retractDirX * move;
      y += retractDirY * move;
      retractRemaining -= move;
      if (retractRemaining <= 0) {
        isRetracting = false;
        vx = 0;
        vy = 0;
      }
      return;
    }
  
    stateTimer += dt;
  
    final type = behavior['type'] ?? 'hunter';
      
    final hoverRadius = (behavior['hover_radius'] ?? 60).toDouble();
    final hoverSpeed = (behavior['hover_speed'] ?? 30).toDouble();
    final hoverChangeInterval =
        (behavior['hover_change_interval'] ?? 2.0).toDouble();
  
    final summonInterval =
        (behavior['summon_interval'] ?? 3.0).toDouble();
    final summonOnce = behavior['summon_once'] == true;
    final summonLimit = (behavior['summon_limit'] ?? 3) as int;
    final summonEnemyIds =
        (behavior['summon_enemy_ids'] as List?)?.cast<int>() ?? [];
    //
    final descendSpeed = (behavior['descend_speed'] ?? 60.0).toDouble();
    final observeHeight = (behavior['observe_height'] ?? 180.0).toDouble();
    final observeDuration = (behavior['observe_duration'] ?? 1.4).toDouble();
    final cooldownDuration = (behavior['cooldown_duration'] ?? 1.0).toDouble();
    final detectDistance = (behavior['detect_distance'] ?? 300.0).toDouble();
    final stopDistance = (behavior['stop_distance'] ?? 24.0).toDouble();
  
    switch (state) {
      case EnemyState.descending:
        vy = descendSpeed;
        y += vy * dt;
        if (y >= observeHeight) {
          y = observeHeight;
          vy = 0;
          vx = 0;
          state = EnemyState.observing;
          stateTimer = 0;

          if (type == 'summoner') {
            hoverAnchorX = screenW / 2;
            hoverAnchorY = observeHeight;
            hoverPhase = _rand.nextDouble() * pi * 2;
          }
          if (type == 'drone') {
            final speed = (behavior['descend_speed'] ?? 120).toDouble();
            y += speed * dt;
            if (y >= (behavior['stop_y'] ?? 180)) {
              y = (behavior['stop_y'] ?? 180);
              vx = 0;
              vy = 0;
              droneFireTimer = 0;
              droneDashTimer = 0;
              droneNextDashDelay = _randDouble(
                (behavior['dash_delay_min'] ?? 1.2).toDouble(),
                (behavior['dash_delay_max'] ?? 2.8).toDouble(),
              );
              state = EnemyState.drone_idle;
            }
          } else {
            _pickObserveTargetNear(
              character,
              behavior['observe_offset']?.toDouble() ?? 100,
            );
          }
        }
        break;
      case EnemyState.drone_idle:
        droneFireTimer += dt;
        droneDashTimer += dt;
    
        // shoot projectile
        final shootInterval = (behavior['shoot_interval'] ?? 0.6).toDouble();
        if (droneFireTimer >= shootInterval) {
          droneFireTimer = 0;
          final projData = behavior['projectile'];
          if (projData != null) {
            final proj = Projectile(
              x: x + width / 2,
              y: y + height / 2,
              speed: (projData['speed'] ?? 300).toDouble(),
              damage: projData['damage'] ?? 10,
              spritePath: projData['sprite_path'] ?? '',
              hitParticle: projData['hit_particle'],
            );
    
            final dx = (character.x + character.width / 2) - proj.x;
            final dy = (character.y + character.height / 2) - proj.y;
            final d = sqrt(dx * dx + dy * dy);
            if (d > 0) {
              proj.vx = dx / d * proj.speed;
              proj.vy = dy / d * proj.speed;
            }
            activeProjectiles.add(proj);
          }
        }
    
        // dash after random interval
        if (droneDashTimer >= droneNextDashDelay) {
          droneDashTimer = 0;
          final angle = _rand.nextDouble() * pi * 2;
          final dashDistance = (behavior['dash_distance'] ?? 200).toDouble();
          droneDashTargetX = x + cos(angle) * dashDistance;
          droneDashTargetY = y + sin(angle) * dashDistance;
          state = EnemyState.drone_dashing;
        }
        break;
        
      case EnemyState.drone_dashing:
            final dx = droneDashTargetX - x;
            final dy = droneDashTargetY - y;
            final dist = sqrt(dx * dx + dy * dy);
            if (dist > 2) {
              final speed = droneDashSpeed;
              vx = dx / dist * speed;
              vy = dy / dist * speed;
              x += vx * dt;
              y += vy * dt;
            } else {
              vx = 0;
              vy = 0;
              droneNextDashDelay = _randDouble(
                (behavior['dash_delay_min'] ?? 1.2).toDouble(),
                (behavior['dash_delay_max'] ?? 2.8).toDouble(),
              );
              state = EnemyState.drone_idle;
            }
            break;
        }

      case EnemyState.observing:
        if (type != 'summoner') {
          final dx = observeTargetX - x;
          final dy = observeTargetY - y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist > 1.0) {
            vx = dx / dist * (behavior['observe_speed']?.toDouble() ?? 50);
            vy = dy / dist * (behavior['observe_speed']?.toDouble() ?? 50);
          } else {
            vx *= 0.9;
            vy *= 0.9;
          }
          x += vx * dt;
          y += vy * dt;
        }
        
        if (type == 'summoner') {
          hoverPhase += dt * hoverSpeed / 40;
      
          final a = hoverRadius; 
          final b = hoverRadius * 0.5;
      
          final targetX = hoverAnchorX + sin(hoverPhase) * a;
          final targetY = hoverAnchorY + sin(hoverPhase * 2) * b;
      
          final dx = targetX - x;
          final dy = targetY - y;
          final dist = sqrt(dx * dx + dy * dy);
      
          if (dist > 0.5) {
            vx = dx / dist * hoverSpeed;
            vy = dy / dist * hoverSpeed;
          } else {
            vx = 0;
            vy = 0;
          }
      
          x += vx * dt;
          y += vy * dt;
      
          if (!summonFinished && summonEnemyIds.isNotEmpty) {
            state = EnemyState.summoning;
            summonTimer = 0;
            stateTimer = 0;
          }
      
          break;
        }
        else if (type == 'hunter') {
          final pdx = character.x - x;
          final pdy = character.y - y;
          final pdist = sqrt(pdx * pdx + pdy * pdy);
          if (pdist <= detectDistance) {
            state = EnemyState.rushing;
            stateTimer = 0;
          } else if (stateTimer >= observeDuration) {
            _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
            stateTimer = 0;
          }
        } 
        else if (type == 'drone') {
          // INITIAL DESCEND
          if (state == EnemyState.observing) {
            droneStopY = (behavior['stop_y'] ?? 180).toDouble();
            state = EnemyState.descending;
            stateTimer = 0;
          }
        }
        break;
      
      case EnemyState.rushing:
        if (type == 'hunter') {
          final dxr = character.x - x;
          final dyr = character.y - y;
          final dr = sqrt(dxr * dxr + dyr * dyr);
          if (dr > 1.0) {
            vx = (dxr / dr) * (behavior['rush_speed']?.toDouble() ?? speed);
            vy = (dyr / dr) * (behavior['rush_speed']?.toDouble() ?? speed);
          }
          x += vx * dt;
          y += vy * dt;
  
          if ((x < character.x + character.width &&
              x + width > character.x &&
              y < character.y + character.height &&
              y + height > character.y)) {
            character.takeDamage(damage);
            HapticFeedback.mediumImpact();
  
            final dx = x - character.x;
            final dy = y - character.y;
            startRetract(dx, dy, 50);
          }
  
          if (stateTimer >= (behavior['rush_duration']?.toDouble() ?? 0.9) || dr <= stopDistance) {
            state = EnemyState.cooldown;
            stateTimer = 0;
            _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
          }
        } else {
          state = EnemyState.observing;
          stateTimer = 0;
        }
        break;
  
      case EnemyState.cooldown:
        if (stateTimer >= cooldownDuration) {
          state = EnemyState.observing;
          stateTimer = 0;
          _pickObserveTargetNear(character, behavior['observe_offset']?.toDouble() ?? 100);
        }
        break;
      case EnemyState.summoning:
        hoverPhase += dt * hoverSpeed / 40;
        
        final a = hoverRadius;
        final b = hoverRadius * 0.5;
        
        final targetX = hoverAnchorX + sin(hoverPhase) * a;
        final targetY = hoverAnchorY + sin(hoverPhase * 2) * b;
        
        final dx = targetX - x;
        final dy = targetY - y;
        final dist = sqrt(dx * dx + dy * dy);
        
        if (dist > 0.5) {
          vx = dx / dist * hoverSpeed;
          vy = dy / dist * hoverSpeed;
        } else {
          vx = 0;
          vy = 0;
        }
        
        x += vx * dt;
        y += vy * dt;

        summonTimer += dt;
        if (summonTimer >= summonInterval) {
          summonTimer = 0;
        
          pendingSummonIds.clear();
        
          for (int i = 0; i < summonLimit; i++) {
            pendingSummonIds.add(
              summonEnemyIds[_rand.nextInt(summonEnemyIds.length)]
            );
          }
        
          pendingSummons = pendingSummonIds.length;
        
          summonParticleConfig = behavior['summon_particle'];
          if (summonParticleConfig != null) {
            final particles = ParticleFactory.fromConfig(
              x: x + width / 2,
              y: y + height / 2,
              config: summonParticleConfig,
            );
            onParticlesRequested?.call(particles);
          }
        
          if (summonOnce) {
            summonFinished = true;
            state = EnemyState.observing;
            stateTimer = 0;
          }
        }
        break;
    }
  
    for (int i = activeProjectiles.length - 1; i >= 0; i--) {
      final p = activeProjectiles[i];
      p.update(dt);
  
      if (p.x >= character.x &&
          p.x <= character.x + character.width &&
          p.y >= character.y &&
          p.y <= character.y + character.height) {
        character.takeDamage(p.damage);
        activeProjectiles.removeAt(i);
        continue;
      }
  
      if (p.x < 0 || p.x > screenW || p.y < 0 || p.y > screenH) {
        activeProjectiles.removeAt(i);
      }
    }
    x = x.clamp(0, screenW - width);
    y = y.clamp(0, screenH - height);
  }
  
  void _pickObserveTargetNear(Character targetCharacter, double offset) {
    final ox = targetCharacter.x + (_randDouble(-offset, offset));
    final oy = max(80.0, targetCharacter.y - (_randDouble(20, offset / 2)));
    observeTargetX = ox;
    observeTargetY = oy;
  }

  double _randDouble(double a, double b) => a + _rand.nextDouble() * (b - a);

  Widget buildWidget() {
    return SizedBox(
      width: width,
      height: height,
      child: ColorFiltered(
        colorFilter: hitFlashTimer > 0
            ? ColorFilter.mode(Colors.white.withOpacity(0.75), BlendMode.srcATop)
            : ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Image.asset(
          "assets/enemies/$spritePath",
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
        ),
      ),
    );
  }

  void dealDamage(Character character) {
    character.currentHealth -= damage;
    if (character.currentHealth < 0) character.currentHealth = 0;
  }
}

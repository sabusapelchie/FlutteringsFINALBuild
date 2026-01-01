//Character mechanics basically. Lahat ng nandito is configurable in supabase.
//So yeah, ung nakikita mo sa game page, eto un. Eto ung pinaka organs ng character niyo.
//Without this, di magfufunction character mo
//Design/Sprite, Wielding of weapon, visual effects, Block/dodge mechanic.
import 'package:flutter/material.dart';
import 'particle_factory.dart';
import 'particle.dart';

class Character {
  double x;
  double y;
  final double width;
  final double height;
  double vy = 0;

  final double jumpStrength;
  final double horizontalSpeedMultiplier;
  final String spritePath;

  int maxHealth;
  int currentHealth;

  bool facingRight = true;

  DateTime? _lastHitTime;
  static const double _hitFlashDuration = 0.15;

  bool isDodging = false;
  DateTime? _dodgeStart;
  DateTime? _lastDodgeEnd;
  
  double dodgeDuration = 2.0;
  double dodgeCooldown = 1.0;
  double dodgeShakeThreshold = 18.0;

  Map<String, dynamic>? dodgeParticleConfig;

  bool dodgeJustStarted = false;

  Character({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.jumpStrength,
    required this.spritePath,
    required this.horizontalSpeedMultiplier,
    required this.maxHealth,
    int? currentHealth,
  }) : currentHealth = currentHealth ?? maxHealth;

  void tryDodge(double shakeStrength) {
    final now = DateTime.now();
  
    if (shakeStrength < dodgeShakeThreshold) return;
  
    if (isDodging) return;
  
    if (_lastDodgeEnd != null &&
        now.difference(_lastDodgeEnd!).inMilliseconds <
            (dodgeCooldown * 1000)) return;
  
    isDodging = true;
    dodgeJustStarted = true; 
    _dodgeStart = now;
  }
  
  void updateDodge() {
    if (!isDodging || _dodgeStart == null) return;
  
    if (DateTime.now()
            .difference(_dodgeStart!)
            .inMilliseconds >=
        dodgeDuration * 1000) {
      isDodging = false;
      _lastDodgeEnd = DateTime.now();
    }
  }

  void moveHorizontally(double tiltX, double dt, double screenWidth) {
    x += tiltX * horizontalSpeedMultiplier * dt;
    x = x.clamp(0, screenWidth - width);

    if (tiltX > 0.1) {
      facingRight = true;
    } else if (tiltX < -0.1) {
      facingRight = false;
    }
  }

  void jump() {
    vy = -jumpStrength;
  }

  void takeDamage(int damage) {
    if (isDodging) return;
    
    currentHealth -= damage;
    if (currentHealth < 0) currentHealth = 0;

    _lastHitTime = DateTime.now();
  }

  void resetHealth() {
    currentHealth = maxHealth;
    _lastHitTime = null;
  }

  void updatePhysics(
    double dt,
    double tiltInput,
    double gravity,
    double screenWidth,
    double screenHeight,
  ) {
    moveHorizontally(tiltInput, dt, screenWidth);

    y += vy * dt;
    vy += gravity * dt;

    x = x.clamp(0, screenWidth - width);
    y = y.clamp(0, screenHeight - height);
  }
  
  void onHit() {
    _lastHitTime = DateTime.now();
  }

  bool get _isHitFlashing {
    if (_lastHitTime == null) return false;
    return DateTime.now()
            .difference(_lastHitTime!)
            .inMilliseconds <
        (_hitFlashDuration * 1000);
  }

  Widget buildWidget() {
    final sprite = SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(facingRight ? 1.0 : -1.0, 1.0),
        child: Image.asset(
          "assets/character sprites/$spritePath",
          fit: BoxFit.fill,
          filterQuality: FilterQuality.none,
        ),
      ),
    );

    if (_isHitFlashing) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.red.withOpacity(0.75),
          BlendMode.srcATop,
        ),
        child: sprite,
      );
    }
    return Opacity(
      opacity: isDodging ? 0.4 : 1.0,
      child: sprite,
    );
  }
}

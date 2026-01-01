import 'dart:math';
import 'particle.dart';
import 'package:flutter/material.dart';

class ParticleEmitter {
  static List<Particle> explosion({
    required double x,
    required double y,
    int count = 14,
    double speed = 220,
    double life = 0.4,
    double size = 6,
    List<Color>? colors,
    ParticleShape shape = ParticleShape.circle,
  }) {
    final rand = Random();
    final palette = colors ??
        [Colors.orange, Colors.red, Colors.yellow];

    return List.generate(count, (_) {
      final angle = rand.nextDouble() * pi * 2;
      final s = speed * (0.4 + rand.nextDouble() * 0.6);

      return Particle(
        x: x,
        y: y,
        vx: cos(angle) * s,
        vy: sin(angle) * s,
        life: life,
        size: size,
        color: palette[rand.nextInt(palette.length)],
        shape: shape,
      );
    });
  }
}

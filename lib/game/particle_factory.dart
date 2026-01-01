import 'package:flutter/material.dart';
import 'particle_emitter.dart';
import 'particle.dart';

class ParticleFactory {
  static List<Particle> fromConfig({
    required double x,
    required double y,
    Map<String, dynamic>? config,
  }) {
    if (config == null) return [];

    return ParticleEmitter.explosion(
      x: x,
      y: y,
      count: config['count'] ?? 12,
      speed: (config['speed'] ?? 200).toDouble(),
      life: (config['life'] ?? 0.4).toDouble(),
      size: (config['size'] ?? 6).toDouble(),
      colors: (config['colors'] as List?)
          ?.map((c) => _hex(c))
          .toList(),
      shape: config['shape'] == 'square'
          ? ParticleShape.square
          : ParticleShape.circle,
    );
  }

  static Color _hex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  }
}

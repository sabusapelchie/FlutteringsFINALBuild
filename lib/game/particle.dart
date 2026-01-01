import 'dart:math';
import 'package:flutter/material.dart';

enum ParticleShape { circle, square }

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double size;
  final Color color;
  final ParticleShape shape;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
    required this.shape,
  });

  bool get isDead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }

  Widget build(double screenHeight) {
    return Positioned(
      left: x,
      bottom: screenHeight - y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: shape == ParticleShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
        ),
      ),
    );
  }
}

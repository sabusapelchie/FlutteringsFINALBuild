import 'package:flutter/material.dart';

//Mostly for neon design lang, for example sa game page, home page. You can see na they share similar themes, medyo glowing, not too much.
class NeonCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NeonCard({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Color(0xFF00E5FF).withOpacity(0.15),
              Color(0xFFB388FF).withOpacity(0.15),
            ],
          ),
          border: Border.all(color: Color(0xFF00E5FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFB388FF).withOpacity(0.6),
              blurRadius: 25,
              spreadRadius: 1,
            )
          ],
        ),
        padding: EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

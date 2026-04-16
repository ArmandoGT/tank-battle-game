/// ============================================================
/// Pixel Text Widget — Reusable retro-styled text component.
/// ============================================================
/// Uses the Press Start 2P pixel art font for authentic NES feel.
/// ============================================================

import 'package:flutter/material.dart';

class PixelText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;

  const PixelText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = Colors.white,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: fontSize,
        color: color,
        letterSpacing: 2,
        height: 1.5,
      ),
    );
  }
}

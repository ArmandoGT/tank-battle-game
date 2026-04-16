/// ============================================================
/// Retro Button Widget — NES-style menu button with hover fx.
/// ============================================================

import 'package:flutter/material.dart';
import 'pixel_text.dart';

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double fontSize;
  final Color textColor;
  final Color hoverColor;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 14,
    this.textColor = Colors.white,
    this.hoverColor = const Color(0xFFE8D038),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovered ? widget.hoverColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector arrow (like NES tank cursor).
              AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isHovered ? 1.0 : 0.0,
                child: PixelText(
                  text: '►',
                  fontSize: widget.fontSize,
                  color: widget.hoverColor,
                ),
              ),
              const SizedBox(width: 12),
              PixelText(
                text: widget.text,
                fontSize: widget.fontSize,
                color: _isHovered ? widget.hoverColor : widget.textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

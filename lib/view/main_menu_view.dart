/// ============================================================
/// Main Menu View — Retro NES-style start screen.
/// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/pixel_text.dart';
import '../widgets/retro_button.dart';

class MainMenuView extends StatefulWidget {
  final VoidCallback onStartOnePlayer;
  final VoidCallback onStartTwoPlayer;

  const MainMenuView({
    super.key,
    required this.onStartOnePlayer,
    required this.onStartTwoPlayer,
  });

  @override
  State<MainMenuView> createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimController;
  late AnimationController _blinkAnimController;
  late Animation<double> _titleSlide;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    // Title slides in from top.
    _titleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleSlide = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(
        parent: _titleAnimController,
        curve: Curves.bounceOut,
      ),
    );
    _titleAnimController.forward();

    // Blink controller for decorative elements.
    _blinkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Show buttons after title animation.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showButtons = true);
    });
  }

  @override
  void dispose() {
    _titleAnimController.dispose();
    _blinkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Title ──
            AnimatedBuilder(
              animation: _titleSlide,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _titleSlide.value),
                  child: child,
                );
              },
              child: Column(
                children: [
                  const PixelText(
                    text: 'BATTLE',
                    fontSize: 32,
                    color: Color(0xFFE8D038),
                  ),
                  const SizedBox(height: 8),
                  const PixelText(
                    text: 'CITY',
                    fontSize: 32,
                    color: Color(0xFFE8D038),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Subtitle ──
            AnimatedBuilder(
              animation: _blinkAnimController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + _blinkAnimController.value * 0.5,
                  child: child,
                );
              },
              child: const PixelText(
                text: '© 1990 NAMCO',
                fontSize: 8,
                color: Color(0xFF888888),
              ),
            ),

            const SizedBox(height: 48),

            // ── Menu options ──
            if (_showButtons) ...[
              RetroButton(
                text: '1 PLAYER',
                onPressed: widget.onStartOnePlayer,
              ),
              const SizedBox(height: 16),
              RetroButton(
                text: '2 PLAYERS',
                onPressed: widget.onStartTwoPlayer,
              ),
              const SizedBox(height: 48),
              const PixelText(
                text: 'P1: WASD + SPACE',
                fontSize: 7,
                color: Color(0xFF888888),
              ),
              const SizedBox(height: 8),
              const PixelText(
                text: 'P2: ARROWS + ENTER',
                fontSize: 7,
                color: Color(0xFF888888),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

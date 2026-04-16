/// ============================================================
/// HUD Widget — In-game heads-up display overlay.
/// ============================================================
/// Uses GetX Obx() to reactively display score, lives, enemies
/// remaining, and stage number. Updates ONLY on discrete events
/// (never at 60 FPS) because Rx variables are set on state changes.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/game_controller.dart';
import 'pixel_text.dart';

class HudWidget extends StatelessWidget {
  const HudWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = Get.find<GameController>();

    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      child: Container(
        width: 120,
        color: const Color(0xFF636363),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const PixelText(text: 'ENEMY', fontSize: 8, color: Colors.black),
            const SizedBox(height: 8),

            // ── Enemy icons remaining ──
            Obx(() {
              final remaining = gc.rxEnemiesRemaining.value;
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(
                  remaining.clamp(0, 20),
                  (_) => Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.rectangle,
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // ── Player 1 info ──
            const PixelText(text: '1P', fontSize: 8, color: Colors.black),
            const SizedBox(height: 4),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 12, color: Colors.red),
                const SizedBox(width: 4),
                PixelText(
                  text: '${gc.rxLivesP1.value}',
                  fontSize: 8,
                  color: Colors.black,
                ),
              ],
            )),
            const SizedBox(height: 4),
            Obx(() => PixelText(
              text: '${gc.rxScoreP1.value}',
              fontSize: 7,
              color: Colors.black,
            )),

            const SizedBox(height: 16),

            // ── Player 2 info (conditional) ──
            Obx(() {
              if (!gc.rxIsTwoPlayer.value) return const SizedBox.shrink();
              return Column(
                children: [
                  const PixelText(text: '2P', fontSize: 8, color: Colors.black),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      PixelText(
                        text: '${gc.rxLivesP2.value}',
                        fontSize: 8,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PixelText(
                    text: '${gc.rxScoreP2.value}',
                    fontSize: 7,
                    color: Colors.black,
                  ),
                ],
              );
            }),

            const Spacer(),

            // ── Stage flag ──
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),
              child: Column(
                children: [
                  const Icon(Icons.flag, size: 16, color: Colors.black),
                  const SizedBox(height: 2),
                  Obx(() => PixelText(
                    text: '${gc.rxCurrentStage.value}',
                    fontSize: 8,
                    color: Colors.black,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// Game Over View — End-of-game screen with score summary.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/game_controller.dart';
import '../widgets/pixel_text.dart';
import '../widgets/retro_button.dart';

class GameOverView extends StatelessWidget {
  final VoidCallback onReturnToMenu;
  final VoidCallback onRetry;

  const GameOverView({
    super.key,
    required this.onReturnToMenu,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final gc = Get.find<GameController>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelText(
              text: 'GAME OVER',
              fontSize: 28,
              color: Color(0xFFFF0000),
            ),
            const SizedBox(height: 32),

            // Score display.
            Obx(() => Column(
              children: [
                PixelText(
                  text: '1P SCORE: ${gc.rxScoreP1.value}',
                  fontSize: 12,
                  color: const Color(0xFFE8D038),
                ),
                if (gc.rxIsTwoPlayer.value) ...[
                  const SizedBox(height: 8),
                  PixelText(
                    text: '2P SCORE: ${gc.rxScoreP2.value}',
                    fontSize: 12,
                    color: const Color(0xFF58D854),
                  ),
                ],
                const SizedBox(height: 8),
                PixelText(
                  text: 'STAGE: ${gc.rxCurrentStage.value}',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ],
            )),

            const SizedBox(height: 40),
            RetroButton(text: 'RETRY', onPressed: onRetry),
            const SizedBox(height: 16),
            RetroButton(text: 'MENU', onPressed: onReturnToMenu),
          ],
        ),
      ),
    );
  }
}

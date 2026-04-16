/// ============================================================
/// Game View — Main game screen with Flame GameWidget + HUD.
/// ============================================================
/// Integrates FlameGame via GameWidget and overlays Flutter
/// widgets (HUD, menus) using GetX Obx() observation.
/// ============================================================

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../game/battle_city_game.dart';
import '../model/game_state.dart';
import '../viewmodel/game_controller.dart';
import '../widgets/hud_widget.dart';
import 'main_menu_view.dart';
import 'stage_intro_view.dart';
import 'game_over_view.dart';

class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late BattleCityGame _game;
  late GameController _gc;

  @override
  void initState() {
    super.initState();
    _gc = Get.find<GameController>();
    _game = BattleCityGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 744 / 624, // Game area + HUD sidebar
          child: Stack(
            children: [
              // ── Flame game canvas ──
              GameWidget(game: _game),

              // ── HUD sidebar ──
              const HudWidget(),

              // ── Overlay screens (reactive to game phase) ──
              Obx(() {
                switch (_gc.rxPhase.value) {
                  case GamePhase.mainMenu:
                    return MainMenuView(
                      onStartOnePlayer: () {
                        _gc.startGame(twoPlayer: false);
                      },
                      onStartTwoPlayer: () {
                        _gc.startGame(twoPlayer: true);
                      },
                    );

                  case GamePhase.stageIntro:
                    return StageIntroView(
                      stageNumber: _gc.rxCurrentStage.value,
                      onComplete: () {
                        _gc.beginPlaying();
                        _game.restartStage();
                      },
                    );

                  case GamePhase.gameOver:
                    return GameOverView(
                      onReturnToMenu: () {
                        _gc.returnToMenu();
                      },
                      onRetry: () {
                        _gc.startGame(
                          twoPlayer: _gc.rxIsTwoPlayer.value,
                        );
                      },
                    );

                  case GamePhase.paused:
                    return Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PixelTextInline(
                              text: 'PAUSED',
                              fontSize: 24,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            PixelTextInline(
                              text: 'Press ESC to resume',
                              fontSize: 10,
                              color: Color(0xFF888888),
                            ),
                          ],
                        ),
                      ),
                    );

                  case GamePhase.playing:
                  case GamePhase.victory:
                    return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline version of PixelText that doesn't import the widget file
/// (avoids circular dependency for pause screen).
class PixelTextInline extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;

  const PixelTextInline({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: fontSize,
        color: color,
        letterSpacing: 2,
      ),
    );
  }
}

/// ============================================================
/// Main Entry Point — Battle City 1990 Flutter Web Clone.
/// ============================================================
/// Initializes GetX dependency injection for all controllers,
/// then launches the app with the GameView.
/// ============================================================

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'viewmodel/game_controller.dart';
import 'viewmodel/player_controller.dart';
import 'viewmodel/enemy_controller.dart';
import 'view/game_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Register GetX Controllers (Dependency Injection) ──
  // These persist for the entire app lifecycle.
  Get.put(GameController());
  Get.put(PlayerController());
  Get.put(EnemyController());

  runApp(const BattleCityApp());
}

class BattleCityApp extends StatelessWidget {
  const BattleCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Battle City 1990',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'PressStart2P',
      ),
      home: const GameView(),
    );
  }
}

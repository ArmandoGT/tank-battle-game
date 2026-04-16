/// ============================================================
/// Battle City Game — Main FlameGame orchestrator.
/// ============================================================
/// Responsibilities:
///  • Owns the game loop (update/render at 60 FPS)
///  • Initializes collision detection with groups/masks
///  • Integrates with GetX controllers for LOW-FREQUENCY state only
///  • Pre-allocates all reusable objects (Object Pooling) in onLoad
///  • Delegates keyboard events to InputService (boolean map polling)
///
/// ARCHITECTURAL RULE: Flame owns physics & rendering. GetX owns
/// meta-state (score, lives, stage). Never couple GetX Rx/Obx into
/// the game loop — it would trigger Flutter rebuilds at 60 FPS.
/// ============================================================

import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:get/get.dart';

import '../model/tank_model.dart';
import '../model/terrain_model.dart';
import '../model/game_state.dart';
import '../viewmodel/game_controller.dart';
import '../viewmodel/player_controller.dart';
import '../viewmodel/enemy_controller.dart';
import '../services/input_service.dart';
import '../services/audio_service.dart';
import '../services/stage_loader_service.dart';
import 'components/tank_component.dart';
import 'components/bullet_component.dart';
import 'components/terrain_component.dart';
import 'components/base_component.dart';
import 'components/power_up_component.dart';
import 'components/explosion_component.dart';

/// The size of a single grid cell in pixels.
const double kCellSize = 48.0;

/// The grid dimensions (NES Battle City uses 13×13).
const int kGridWidth = 13;
const int kGridHeight = 13;

/// Total game world size in pixels.
const double kGameWidth = kCellSize * kGridWidth;   // 624
const double kGameHeight = kCellSize * kGridHeight;  // 624

class BattleCityGame extends FlameGame
    with KeyboardEvents, HasCollisionDetection {

  // ── GetX Controller References (read-only from game loop) ──
  // These are looked up once in onLoad, never recreated.
  // Public so child components can access meta-state.
  late final GameController gameController;
  late final PlayerController playerController;
  late final EnemyController enemyController;

  // ── Services ──
  late final InputService inputService;
  late final AudioService audioService;
  late final StageLoaderService stageLoaderService;

  // ── Pre-allocated Objects (Object Pooling) ──
  // Avoid GC jank by reusing these across frames.

  /// Pool of bullet components, pre-allocated to avoid per-frame allocation.
  /// Max bullets: 2 players × 2 bullets + 4 enemies × 1 bullet = 8
  late final List<BulletComponent> bulletPool;
  static const int kBulletPoolSize = 16;

  /// Pool of explosion components.
  late final List<ExplosionComponent> explosionPool;
  static const int kExplosionPoolSize = 8;



  // ── Terrain Grid ──
  late List<List<TerrainTile>> terrainGrid;
  late List<List<TerrainComponent>> terrainComponents;

  // ── Tank References ──
  late TankComponent player1Tank;
  TankComponent? player2Tank;
  final List<TankComponent> enemyTanks = [];

  // ── Base ──
  late BaseComponent baseComponent;

  // ── Game Timing ──
  double _enemySpawnTimer = 0;
  static const double kEnemySpawnInterval = 3.0;
  int _enemySpawnCount = 0;

  /// Tracks which enemy indices are "flashing" (drop power-ups).
  static const List<int> kFlashingEnemyIndices = [3, 10, 17]; // 4th, 11th, 18th

  @override
  Color backgroundColor() => const Color(0xFF000000);

  // ────────────────────────────────────────────────────────────
  // onLoad — One-time initialization, pre-allocation, stage load
  // ────────────────────────────────────────────────────────────
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Resize camera to match the game world exactly.
    camera.viewfinder.visibleGameSize = Vector2(kGameWidth, kGameHeight);
    camera.viewfinder.position = Vector2(kGameWidth / 2, kGameHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    // ── Initialize services ──
    inputService = InputService();
    audioService = AudioService();
    stageLoaderService = StageLoaderService();

    // ── Look up GetX controllers (registered by Flutter widget layer) ──
    gameController = Get.find<GameController>();
    playerController = Get.find<PlayerController>();
    enemyController = Get.find<EnemyController>();

    // ── Pre-allocate bullet pool ──
    bulletPool = List.generate(kBulletPoolSize, (_) {
      final bullet = BulletComponent();
      bullet.deactivate(); // Start inactive
      return bullet;
    });

    // ── Pre-allocate explosion pool ──
    explosionPool = List.generate(kExplosionPoolSize, (_) {
      final explosion = ExplosionComponent();
      explosion.deactivate();
      return explosion;
    });

    // Load the first stage.
    await _loadStage(gameController.state.currentStage);
  }

  // ────────────────────────────────────────────────────────────
  // Stage loading — Builds terrain, places tanks, resets state
  // ────────────────────────────────────────────────────────────
  Future<void> _loadStage(int stageNumber) async {
    // Clear existing components from previous stage.
    world.removeAll(world.children);

    // Load terrain grid from service.
    terrainGrid = stageLoaderService.loadStage(stageNumber);
    terrainComponents = [];

    // Build terrain components row by row.
    for (int row = 0; row < kGridHeight; row++) {
      final rowComponents = <TerrainComponent>[];
      for (int col = 0; col < kGridWidth; col++) {
        final tile = terrainGrid[row][col];
        if (tile.type != TileType.empty) {
          final terrainComp = TerrainComponent(
            tile: tile,
            gridX: col,
            gridY: row,
          );
          rowComponents.add(terrainComp);

          // Forest tiles render above tanks (priority 10).
          if (tile.type == TileType.forest) {
            terrainComp.priority = 10;
          }

          world.add(terrainComp);
        } else {
          rowComponents.add(TerrainComponent(tile: tile, gridX: col, gridY: row));
        }
      }
      terrainComponents.add(rowComponents);
    }

    // ── Place the Base (eagle) at bottom-center ──
    baseComponent = BaseComponent(
      gridX: 6,
      gridY: 12,
    );
    world.add(baseComponent);

    // ── Place Player 1 tank ──
    final p1Model = TankModel.player(TankType.player1);
    p1Model.x = 4 * kCellSize;
    p1Model.y = 12 * kCellSize;
    player1Tank = TankComponent(
      model: p1Model,
      game: this,
    );
    world.add(player1Tank);

    // ── Place Player 2 tank (if two-player mode) ──
    if (gameController.state.isTwoPlayer) {
      final p2Model = TankModel.player(TankType.player2);
      p2Model.x = 8 * kCellSize;
      p2Model.y = 12 * kCellSize;
      player2Tank = TankComponent(
        model: p2Model,
        game: this,
      );
      world.add(player2Tank!);
    }

    // ── Add bullet pool to world (inactive, waiting for use) ──
    for (final bullet in bulletPool) {
      bullet.deactivate();
      world.add(bullet);
    }

    // ── Add explosion pool to world ──
    for (final explosion in explosionPool) {
      explosion.deactivate();
      world.add(explosion);
    }

    // Reset enemy state.
    enemyTanks.clear();
    _enemySpawnCount = 0;
    _enemySpawnTimer = 0;
  }

  // ────────────────────────────────────────────────────────────
  // update — Main game loop, called every frame
  // ────────────────────────────────────────────────────────────
  @override
  void update(double dt) {
    super.update(dt);

    final state = gameController.state;

    // Only update game logic while in playing phase.
    if (state.phase != GamePhase.playing) return;

    // ── Check freeze timer (clock power-up) ──
    if (state.enemiesFrozen) {
      state.freezeTimer -= dt;
      if (state.freezeTimer <= 0) {
        state.enemiesFrozen = false;
        state.freezeTimer = 0;
      }
    }

    // ── Check base fortify timer (shovel power-up) ──
    if (state.baseFortified) {
      state.fortifyTimer -= dt;
      if (state.fortifyTimer <= 0) {
        state.baseFortified = false;
        state.fortifyTimer = 0;
        _removeFortification();
      }
    }

    // ── Enemy spawning logic ──
    _updateEnemySpawns(dt);

    // ── Check game-over conditions ──
    _checkGameOver();

    // ── Check stage-clear condition ──
    _checkStageClear();
  }

  // ────────────────────────────────────────────────────────────
  // Keyboard handling — delegates to InputService boolean map
  // ────────────────────────────────────────────────────────────
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    inputService.handleKeyEvent(event);
    return KeyEventResult.handled;
  }

  // ────────────────────────────────────────────────────────────
  // Bullet pool — Get an inactive bullet from the pool
  // ────────────────────────────────────────────────────────────
  BulletComponent? acquireBullet() {
    for (final bullet in bulletPool) {
      if (!bullet.isActive) {
        return bullet;
      }
    }
    return null; // Pool exhausted (should be rare)
  }

  /// Count active bullets belonging to a specific tank type.
  int activeBulletsFor(TankType ownerType) {
    int count = 0;
    for (final bullet in bulletPool) {
      if (bullet.isActive && bullet.ownerType == ownerType) {
        count++;
      }
    }
    return count;
  }

  // ────────────────────────────────────────────────────────────
  // Explosion pool — Spawn an explosion at a position
  // ────────────────────────────────────────────────────────────
  void spawnExplosion(double x, double y, {bool large = false}) {
    for (final explosion in explosionPool) {
      if (!explosion.isActive) {
        explosion.activate(x, y, large: large);
        return;
      }
    }
  }

  // ────────────────────────────────────────────────────────────
  // Terrain collision queries — used by tanks and bullets
  // ────────────────────────────────────────────────────────────

  /// Check if a bounding box overlaps any blocking terrain.
  bool isBlocked(double x, double y, double w, double h,
      {bool isBullet = false}) {
    // Convert pixel coords to grid coords.
    final startCol = (x / kCellSize).floor().clamp(0, kGridWidth - 1);
    final endCol = ((x + w) / kCellSize).ceil().clamp(0, kGridWidth);
    final startRow = (y / kCellSize).floor().clamp(0, kGridHeight - 1);
    final endRow = ((y + h) / kCellSize).ceil().clamp(0, kGridHeight);

    for (int row = startRow; row < endRow; row++) {
      for (int col = startCol; col < endCol; col++) {
        if (row >= kGridHeight || col >= kGridWidth) continue;
        final tile = terrainGrid[row][col];
        if (isBullet && tile.blocksBullets) return true;
        if (!isBullet && tile.blocksTanks) return true;
      }
    }

    // Check world boundaries.
    if (x < 0 || y < 0 || x + w > kGameWidth || y + h > kGameHeight) {
      return true;
    }

    return false;
  }

  /// Check if a position is on ice terrain.
  bool isOnIce(double x, double y, double w, double h) {
    final centerCol = ((x + w / 2) / kCellSize).floor().clamp(0, kGridWidth - 1);
    final centerRow = ((y + h / 2) / kCellSize).floor().clamp(0, kGridHeight - 1);
    return terrainGrid[centerRow][centerCol].type == TileType.ice;
  }

  /// Destroy terrain at a bullet hit position. Returns true if something was hit.
  bool destroyTerrainAt(double x, double y, Direction bulletDir,
      {bool canDestroySteel = false}) {
    final col = (x / kCellSize).floor().clamp(0, kGridWidth - 1);
    final row = (y / kCellSize).floor().clamp(0, kGridHeight - 1);

    if (row >= kGridHeight || col >= kGridWidth) return false;

    final tile = terrainGrid[row][col];

    if (tile.type == TileType.steel) {
      if (canDestroySteel) {
        tile.reset(TileType.empty);
        _updateTerrainComponent(row, col);
        return true;
      }
      return true; // Blocked but not destroyed
    }

    if (tile.type == TileType.brick) {
      // Determine which quadrants to destroy based on bullet direction.
      final List<int> quads = _getAffectedQuadrants(
        x, y, col, row, bulletDir,
      );
      tile.destroyQuadrants(quads);

      if (tile.isFullyDestroyed) {
        tile.reset(TileType.empty);
      }
      _updateTerrainComponent(row, col);
      return true;
    }

    if (tile.type == TileType.base) {
      gameController.state.baseDestroyed = true;
      return true;
    }

    return false;
  }

  /// Determine which brick quadrants a bullet affects.
  List<int> _getAffectedQuadrants(
    double bx, double by, int col, int row, Direction dir,
  ) {
    final cellCenterX = col * kCellSize + kCellSize / 2;
    final cellCenterY = row * kCellSize + kCellSize / 2;

    switch (dir) {
      case Direction.up:
      case Direction.down:
        // Horizontal split: hit left or right quadrants
        if (bx < cellCenterX) {
          return [0, 2]; // Left quadrants
        } else {
          return [1, 3]; // Right quadrants
        }
      case Direction.left:
      case Direction.right:
        // Vertical split: hit top or bottom quadrants
        if (by < cellCenterY) {
          return [0, 1]; // Top quadrants
        } else {
          return [2, 3]; // Bottom quadrants
        }
    }
  }

  /// Notify the terrain component to re-render after destruction.
  void _updateTerrainComponent(int row, int col) {
    if (row < terrainComponents.length && col < terrainComponents[row].length) {
      terrainComponents[row][col].markDirty();
    }
  }

  // ────────────────────────────────────────────────────────────
  // Enemy spawning
  // ────────────────────────────────────────────────────────────
  void _updateEnemySpawns(double dt) {
    final state = gameController.state;
    if (state.enemiesRemaining <= 0) return;
    if (enemyTanks.where((t) => t.model.isAlive).length >= 4) return;

    _enemySpawnTimer += dt;
    if (_enemySpawnTimer >= kEnemySpawnInterval) {
      _enemySpawnTimer = 0;
      _spawnNextEnemy();
    }
  }

  void _spawnNextEnemy() {
    final state = gameController.state;
    if (state.enemiesRemaining <= 0) return;

    // Choose enemy type based on stage progression.
    final enemyType = enemyController.getNextEnemyType(
      _enemySpawnCount,
      state.currentStage,
    );

    final isFlashing = kFlashingEnemyIndices.contains(_enemySpawnCount);

    final model = TankModel.enemy(enemyType, flashing: isFlashing);

    // Spawn from one of three spawn points.
    final spawnPoints = [
      [0.0, 0.0],
      [6.0 * kCellSize, 0.0],
      [12.0 * kCellSize, 0.0],
    ];
    final spawnIdx = _enemySpawnCount % 3;
    model.x = spawnPoints[spawnIdx][0];
    model.y = spawnPoints[spawnIdx][1];
    model.direction = Direction.down;

    final tankComp = TankComponent(model: model, game: this);
    enemyTanks.add(tankComp);
    world.add(tankComp);

    _enemySpawnCount++;
  }

  // ────────────────────────────────────────────────────────────
  // Game state checks
  // ────────────────────────────────────────────────────────────
  void _checkGameOver() {
    final state = gameController.state;

    // Base destroyed → game over.
    if (state.baseDestroyed) {
      gameController.triggerGameOver();
      return;
    }

    // All player lives depleted → game over.
    if (state.livesPlayer1 <= 0 &&
        (!state.isTwoPlayer || state.livesPlayer2 <= 0)) {
      gameController.triggerGameOver();
    }
  }

  void _checkStageClear() {
    final state = gameController.state;
    if (state.enemiesRemaining <= 0 &&
        enemyTanks.where((t) => t.model.isAlive).isEmpty) {
      gameController.triggerStageComplete();
    }
  }

  // ────────────────────────────────────────────────────────────
  // Power-up effects
  // ────────────────────────────────────────────────────────────
  void activateFortification() {
    gameController.state.baseFortified = true;
    gameController.state.fortifyTimer = 20.0;
    // Replace bricks around base with steel.
    for (final pos in [
      [5, 11], [6, 11], [7, 11],
      [5, 12], [7, 12],
    ]) {
      final row = pos[1];
      final col = pos[0];
      if (row < kGridHeight && col < kGridWidth) {
        terrainGrid[row][col].reset(TileType.steel);
        _updateTerrainComponent(row, col);
      }
    }
  }

  void _removeFortification() {
    // Revert steel back to brick around base.
    for (final pos in [
      [5, 11], [6, 11], [7, 11],
      [5, 12], [7, 12],
    ]) {
      final row = pos[1];
      final col = pos[0];
      if (row < kGridHeight && col < kGridWidth) {
        terrainGrid[row][col].reset(TileType.brick);
        _updateTerrainComponent(row, col);
      }
    }
  }

  void freezeAllEnemies() {
    gameController.state.enemiesFrozen = true;
    gameController.state.freezeTimer = 10.0;
  }

  void destroyAllEnemies() {
    for (final tank in enemyTanks) {
      if (tank.model.isAlive) {
        tank.model.isAlive = false;
        gameController.state.enemiesRemaining--;
        spawnExplosion(tank.model.x, tank.model.y, large: true);
      }
    }
    gameController.notifyEnemiesRemaining();
  }

  /// Advance to next stage.
  Future<void> nextStage() async {
    gameController.state.nextStage();
    await _loadStage(gameController.state.currentStage);
  }

  /// Restart current stage.
  Future<void> restartStage() async {
    await _loadStage(gameController.state.currentStage);
  }
}

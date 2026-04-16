/// ============================================================
/// Stage Loader Service — Loads and prepares stage grid data.
/// ============================================================

import '../model/terrain_model.dart';
import '../game/stages/stage_data.dart';

class StageLoaderService {
  /// Load a stage grid as a 2D list of TerrainTile objects.
  /// Each tile is a fresh TerrainTile with full quadrants for bricks.
  List<List<TerrainTile>> loadStage(int stageNumber) {
    final rawTypes = StageData.getStage(stageNumber);

    return rawTypes.map((row) {
      return row.map((tileType) {
        return TerrainTile(type: tileType);
      }).toList();
    }).toList();
  }

  /// Total number of available stages.
  int get totalStages => StageData.totalStages;
}

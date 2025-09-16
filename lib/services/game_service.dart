import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:ui';

import '../models/models.dart';
import 'storage_service.dart';
import 'time_fragment_service.dart';

/// Service principal du jeu qui orchestre tous les autres services
class GameService extends ChangeNotifier {
  static GameService? _instance;
  
  PlayerProgress _playerProgress = PlayerProgress.initial();
  WorldState _worldState = WorldState.initial();
  GameSave? _currentSave;
  
  bool _isInitialized = false;
  bool _isLoading = false;

  final StorageService _storage = StorageService.instance;
  final TimeFragmentService _fragmentService = TimeFragmentService.instance;
  
  Timer? _autoSaveTimer;

  GameService._();

  static GameService get instance {
    _instance ??= GameService._();
    return _instance!;
  }

  /// État d'initialisation
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  /// Accès aux données de jeu
  PlayerProgress get playerProgress => _playerProgress;
  WorldState get worldState => _worldState;
  GameSave? get currentSave => _currentSave;

  /// Accès aux services
  TimeFragmentService get fragmentService => _fragmentService;

  /// Initialiser le service de jeu
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Initialiser les services de base
      await _storage.initialize();
      await _fragmentService.initialize();

      // Charger la sauvegarde existante ou créer une nouvelle
      await _loadOrCreateSave();

      // Démarrer la sauvegarde automatique
      _startAutoSave();

      _isInitialized = true;
      debugPrint('GameService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du GameService: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger une sauvegarde existante ou créer une nouvelle
  Future<void> _loadOrCreateSave() async {
    _currentSave = await _storage.loadGameSave();

    if (_currentSave != null) {
      // Charger la sauvegarde existante
      _playerProgress = _currentSave!.playerProgress;
      _worldState = _currentSave!.currentWorld;
      debugPrint('Sauvegarde chargée: ${_playerProgress}');
    } else {
      // Créer une nouvelle sauvegarde
      _currentSave = GameSave.initial();
      _playerProgress = _currentSave!.playerProgress;
      _worldState = _currentSave!.currentWorld;
      
      await _saveGame();
      debugPrint('Nouvelle sauvegarde créée');
    }
  }

  /// Démarrer la sauvegarde automatique
  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _saveGame();
    });
  }

  /// Sauvegarder le jeu
  Future<void> _saveGame() async {
    if (_currentSave == null) return;

    try {
      _currentSave = _currentSave!.copyWith(
        playerProgress: _playerProgress,
        currentWorld: _worldState,
        lastPlayTime: DateTime.now(),
      );

      await _storage.saveGameSave(_currentSave!);
      debugPrint('Jeu sauvegardé automatiquement');
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Sauvegarder manuellement
  Future<void> saveManually() async {
    await _saveGame();
    debugPrint('Sauvegarde manuelle effectuée');
  }

  /// Terminer une session Pomodoro
  Future<void> completePomodoroSession(PomodoroSession session) async {
    try {
      // Sauvegarder la session
      await _storage.savePomodoroSession(session);

      // Ajouter à l'historique
      if (_currentSave != null) {
        _currentSave = _currentSave!.addPomodoroSession(session);
      }

      // Gagner les FT
      if (session.ftEarned > 0) {
        await _fragmentService.earnFromPomodoro(
          sessionDuration: session.duration,
          actualDuration: session.elapsedTime,
          wasCompleted: session.status == SessionStatus.completed,
          wasAppLeft: session.wasAppLeft,
          timeOutOfApp: session.timeOutOfApp,
        );

        // Mettre à jour la progression du joueur
        _playerProgress = _playerProgress.addPomodoroSession(
          wasCompleted: session.status == SessionStatus.completed,
          ftEarned: session.ftEarned,
        );
      }

      // Vérifier les achievements
      _playerProgress = _playerProgress.checkAchievements();

      // Déclencher une révélation TimeLapse si des FT ont été gagnés
      if (session.ftEarned > 0) {
        await _triggerTimeLapse(session.ftEarned);
      }

      notifyListeners();
      debugPrint('Session Pomodoro terminée: ${session.ftEarned} FT gagnés');
    } catch (e) {
      debugPrint('Erreur lors de la completion de la session: $e');
      rethrow;
    }
  }

  /// Ajouter des pas de marche
  Future<void> addSteps(int steps) async {
    try {
      // Gagner des FT depuis la marche
      await _fragmentService.earnFromWalking(steps);

      // Mettre à jour la progression
      final ftEarned = steps ~/ 100;
      if (ftEarned > 0) {
        _playerProgress = _playerProgress
            .addSteps(steps)
            .addFTEarned(ftEarned);
      } else {
        _playerProgress = _playerProgress.addSteps(steps);
      }

      // Vérifier les achievements
      _playerProgress = _playerProgress.checkAchievements();

      notifyListeners();
      debugPrint('$steps pas ajoutés, $ftEarned FT gagnés');
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout des pas: $e');
    }
  }

  /// Déclencher une révélation TimeLapse
  Future<void> _triggerTimeLapse(int ftEarned) async {
    // Calculer le nombre de tuiles à révéler basé sur les FT gagnés
    final tilesToReveal = _calculateTilesToReveal(ftEarned);
    
    if (tilesToReveal > 0) {
      final newTiles = _generateNewTiles(tilesToReveal);
      _worldState = _worldState.revealTiles(newTiles);
      
      // Mettre à jour le compteur de tuiles révélées
      _playerProgress = _playerProgress.revealTiles(newTiles.length);
      
      debugPrint('TimeLapse: ${newTiles.length} nouvelles tuiles révélées');
    }
  }

  /// Calculer le nombre de tuiles à révéler
  int _calculateTilesToReveal(int ftEarned) {
    // 25 FT = 1 tuile, 45 FT = 2 tuiles, 90 FT = 3 tuiles
    if (ftEarned >= 90) return 3;
    if (ftEarned >= 45) return 2;
    if (ftEarned >= 25) return 1;
    return 0;
  }

  /// Générer de nouvelles tuiles à révéler
  List<MapTile> _generateNewTiles(int count) {
    final newTiles = <MapTile>[];
    final revealedPositions = _worldState.revealedTiles
        .map((t) => '${t.x},${t.y}')
        .toSet();

    // Générer des tuiles adjacentes aux tuiles déjà révélées
    for (int i = 0; i < count; i++) {
      final position = _findNextTilePosition(revealedPositions);
      if (position != null) {
        final tileType = _randomTileType();
        newTiles.add(MapTile(
          x: position.dx.round(),
          y: position.dy.round(),
          type: tileType,
          ftCostToReveal: MapTile.getCostForType(tileType),
        ));
        revealedPositions.add('${position.dx.round()},${position.dy.round()}');
      }
    }

    return newTiles;
  }

  /// Trouver la prochaine position de tuile à révéler
  Offset? _findNextTilePosition(Set<String> revealedPositions) {
    // Logique simple: chercher une position adjacente libre
    for (final tile in _worldState.revealedTiles) {
      final adjacent = [
        Offset(tile.x + 1, tile.y.toDouble()),
        Offset(tile.x - 1, tile.y.toDouble()),
        Offset(tile.x.toDouble(), tile.y + 1),
        Offset(tile.x.toDouble(), tile.y - 1),
      ];

      for (final pos in adjacent) {
        final key = '${pos.dx.round()},${pos.dy.round()}';
        if (!revealedPositions.contains(key)) {
          return pos;
        }
      }
    }
    return null;
  }

  /// Générer un type de tuile aléatoire
  TileType _randomTileType() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    if (random < 60) return TileType.terrain;
    if (random < 75) return TileType.forest;
    if (random < 85) return TileType.water;
    if (random < 92) return TileType.stele;
    if (random < 97) return TileType.bridge;
    if (random < 99) return TileType.relic;
    return TileType.bossPortal;
  }

  /// Dépenser des FT pour du temps d'exploration
  Future<int> buyExplorationTime(int minutes) async {
    final actualMinutes = await _fragmentService.buyExplorationTime(minutes);
    
    if (actualMinutes > 0) {
      _worldState = _worldState.addExplorationTime(actualMinutes);
      
      // Mettre à jour le solde FT du joueur
      _playerProgress = _playerProgress.spendFT(actualMinutes * 10);
      
      notifyListeners();
      debugPrint('$actualMinutes minutes d\'exploration achetés');
    }
    
    return actualMinutes;
  }

  /// Déplacer le joueur
  void movePlayer(double x, double y) {
    _worldState = _worldState.movePlayer(x, y);
    notifyListeners();
  }

  /// Battre un boss
  Future<void> defeatBoss() async {
    _playerProgress = _playerProgress.defeatBoss();
    
    // Bonus FT pour avoir battu un boss
    await _fragmentService.earnBonus(
      amount: 100,
      reason: 'Boss vaincu - Monde ${_worldState.worldLevel}',
      additionalMetadata: {'worldLevel': _worldState.worldLevel},
    );

    _playerProgress = _playerProgress.addFTEarned(100);
    _playerProgress = _playerProgress.checkAchievements();
    
    notifyListeners();
    debugPrint('Boss vaincu! 100 FT de bonus gagnés');
  }

  /// Changer de monde
  Future<void> levelUpWorld() async {
    _playerProgress = _playerProgress.levelUpWorld();
    
    // Créer un nouveau monde
    _worldState = WorldState(
      id: 'world_${_playerProgress.currentWorldLevel}_${DateTime.now().millisecondsSinceEpoch}',
      worldLevel: _playerProgress.currentWorldLevel,
      currentPosition: PlayerPosition(
        x: 0.0,
        y: 0.0,
        worldLevel: _playerProgress.currentWorldLevel,
      ),
      lastUpdated: DateTime.now(),
      revealedTiles: [
        MapTile(
          x: 0,
          y: 0,
          type: TileType.terrain,
          isRevealed: true,
        ),
      ],
    );
    
    notifyListeners();
    debugPrint('Niveau de monde augmenté: ${_playerProgress.currentWorldLevel}');
  }

  /// Réinitialiser le jeu
  Future<void> resetGame() async {
    try {
      await _storage.clearAllData();
      await _fragmentService.reset();
      
      _currentSave = GameSave.initial();
      _playerProgress = _currentSave!.playerProgress;
      _worldState = _currentSave!.currentWorld;
      
      await _saveGame();
      notifyListeners();
      
      debugPrint('Jeu réinitialisé');
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }

  /// Nettoyer les ressources
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
import 'player_progress.dart';
import 'world_state.dart';
import 'pomodoro_session.dart';
import 'time_fragment.dart';

/// Sauvegarde complète du jeu
class GameSave {
  final PlayerProgress playerProgress;
  final WorldState currentWorld;
  final List<PomodoroSession> sessionHistory;
  final TimeFragmentCollection fragmentCollection;
  final DateTime lastPlayTime;
  final int saveVersion;
  final Map<String, dynamic> gameSettings;

  const GameSave({
    required this.playerProgress,
    required this.currentWorld,
    this.sessionHistory = const [],
    required this.fragmentCollection,
    required this.lastPlayTime,
    this.saveVersion = 1,
    this.gameSettings = const {},
  });

  /// Sauvegarde initiale
  factory GameSave.initial() {
    final now = DateTime.now();
    return GameSave(
      playerProgress: PlayerProgress.initial(),
      currentWorld: WorldState.initial(),
      fragmentCollection: const TimeFragmentCollection([]),
      lastPlayTime: now,
      gameSettings: {
        'soundEnabled': true,
        'musicEnabled': true,
        'notificationsEnabled': true,
        'darkMode': false,
      },
    );
  }

  /// Mettre à jour la progression du joueur
  GameSave updatePlayerProgress(PlayerProgress newProgress) {
    return copyWith(
      playerProgress: newProgress,
      lastPlayTime: DateTime.now(),
    );
  }

  /// Mettre à jour l'état du monde
  GameSave updateWorldState(WorldState newWorld) {
    return copyWith(
      currentWorld: newWorld,
      lastPlayTime: DateTime.now(),
    );
  }

  /// Ajouter une session Pomodoro à l'historique
  GameSave addPomodoroSession(PomodoroSession session) {
    final updatedHistory = [...sessionHistory, session];
    // Garder seulement les 100 dernières sessions
    final limitedHistory = updatedHistory.length > 100 
        ? updatedHistory.sublist(updatedHistory.length - 100)
        : updatedHistory;
    
    return copyWith(
      sessionHistory: limitedHistory,
      lastPlayTime: DateTime.now(),
    );
  }

  /// Ajouter des fragments de temps
  GameSave addTimeFragments(List<TimeFragment> fragments) {
    final updatedCollection = fragments.fold(
      fragmentCollection,
      (collection, fragment) => collection.add(fragment),
    );
    
    return copyWith(
      fragmentCollection: updatedCollection,
      lastPlayTime: DateTime.now(),
    );
  }

  /// Statistiques de session
  Map<String, dynamic> get sessionStatistics {
    final totalSessions = sessionHistory.length;
    final completedSessions = sessionHistory
        .where((s) => s.status == SessionStatus.completed)
        .length;
    final totalMinutes = sessionHistory
        .where((s) => s.status == SessionStatus.completed)
        .fold(0, (sum, s) => sum + s.duration.inMinutes);
    
    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'failedSessions': totalSessions - completedSessions,
      'totalFocusMinutes': totalMinutes,
      'averageSessionLength': totalSessions > 0 ? totalMinutes / totalSessions : 0,
      'successRate': totalSessions > 0 ? completedSessions / totalSessions : 0,
    };
  }

  /// Statistiques des fragments de temps
  Map<String, dynamic> get fragmentStatistics {
    return {
      'totalFragments': fragmentCollection.totalAmount,
      'todayFragments': fragmentCollection.todayAmount,
      'pomodoroFragments': fragmentCollection.getAmountBySource(FragmentSource.pomodoro),
      'walkingFragments': fragmentCollection.getAmountBySource(FragmentSource.walking),
      'bonusFragments': fragmentCollection.getAmountBySource(FragmentSource.bonus),
      'achievementFragments': fragmentCollection.getAmountBySource(FragmentSource.achievement),
    };
  }

  /// Vérifier l'intégrité de la sauvegarde
  bool get isValid {
    try {
      // Vérifications de base
      if (playerProgress.currentFTBalance < 0) return false;
      if (playerProgress.totalFTEarned < playerProgress.currentFTBalance) return false;
      if (currentWorld.worldLevel < 1) return false;
      if (saveVersion <= 0) return false;
      
      // Vérifier la cohérence des FT
      final expectedTotal = fragmentCollection.totalAmount;
      if (playerProgress.totalFTEarned != expectedTotal) return false;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Méthode copyWith pour l'immutabilité
  GameSave copyWith({
    PlayerProgress? playerProgress,
    WorldState? currentWorld,
    List<PomodoroSession>? sessionHistory,
    TimeFragmentCollection? fragmentCollection,
    DateTime? lastPlayTime,
    int? saveVersion,
    Map<String, dynamic>? gameSettings,
  }) {
    return GameSave(
      playerProgress: playerProgress ?? this.playerProgress,
      currentWorld: currentWorld ?? this.currentWorld,
      sessionHistory: sessionHistory ?? this.sessionHistory,
      fragmentCollection: fragmentCollection ?? this.fragmentCollection,
      lastPlayTime: lastPlayTime ?? this.lastPlayTime,
      saveVersion: saveVersion ?? this.saveVersion,
      gameSettings: gameSettings ?? this.gameSettings,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'playerProgress': playerProgress.toJson(),
      'currentWorld': currentWorld.toJson(),
      'sessionHistory': sessionHistory.map((s) => s.toJson()).toList(),
      'fragmentCollection': fragmentCollection.toJson(),
      'lastPlayTime': lastPlayTime.toIso8601String(),
      'saveVersion': saveVersion,
      'gameSettings': gameSettings,
    };
  }

  /// Création depuis JSON
  factory GameSave.fromJson(Map<String, dynamic> json) {
    return GameSave(
      playerProgress: PlayerProgress.fromJson(json['playerProgress'] as Map<String, dynamic>),
      currentWorld: WorldState.fromJson(json['currentWorld'] as Map<String, dynamic>),
      sessionHistory: (json['sessionHistory'] as List<dynamic>? ?? [])
          .map((item) => PomodoroSession.fromJson(item as Map<String, dynamic>))
          .toList(),
      fragmentCollection: TimeFragmentCollection.fromJson(json['fragmentCollection'] as List<dynamic>? ?? []),
      lastPlayTime: DateTime.parse(json['lastPlayTime'] as String),
      saveVersion: json['saveVersion'] as int? ?? 1,
      gameSettings: Map<String, dynamic>.from(json['gameSettings'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'GameSave{version: $saveVersion, player: $playerProgress, world: ${currentWorld.worldLevel}, lastPlay: $lastPlayTime}';
  }
}
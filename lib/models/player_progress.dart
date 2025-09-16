import 'time_fragment.dart';
import 'world_state.dart';
import 'pomodoro_session.dart';
import 'combat_stats.dart';

/// Types d'achievements
enum AchievementType {
  pomodoro,     // Sessions Pomodoro
  exploration,  // Exploration du monde
  combat,       // Combat et victoires
  walking,      // Marche et activité
  progression,  // Progression générale
}

/// Achievement débloqué
class Achievement {
  final String id;
  final String name;
  final String description;
  final AchievementType type;
  final int ftReward;
  final DateTime unlockedAt;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> metadata;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.ftReward,
    required this.unlockedAt,
    this.criteria = const {},
    this.metadata = const {},
  });

  /// Achievements prédéfinis
  static List<Achievement> get predefinedAchievements => [
    Achievement(
      id: 'first_step',
      name: 'Premier Pas',
      description: 'Terminer votre première session Pomodoro',
      type: AchievementType.pomodoro,
      ftReward: 50,
      unlockedAt: DateTime.now(),
      criteria: {'pomodoroSessions': 1},
    ),
    Achievement(
      id: 'walker',
      name: 'Marcheur Assidu',
      description: 'Marcher 10,000 pas en une journée',
      type: AchievementType.walking,
      ftReward: 100,
      unlockedAt: DateTime.now(),
      criteria: {'dailySteps': 10000},
    ),
    Achievement(
      id: 'explorer',
      name: 'Explorateur',
      description: 'Révéler 50 tuiles du monde',
      type: AchievementType.exploration,
      ftReward: 75,
      unlockedAt: DateTime.now(),
      criteria: {'tilesRevealed': 50},
    ),
    Achievement(
      id: 'time_master',
      name: 'Maître du Temps',
      description: 'Compléter 100 sessions Pomodoro',
      type: AchievementType.pomodoro,
      ftReward: 200,
      unlockedAt: DateTime.now(),
      criteria: {'pomodoroSessions': 100},
    ),
    Achievement(
      id: 'boss_slayer',
      name: 'Vainqueur',
      description: 'Battre votre premier boss',
      type: AchievementType.combat,
      ftReward: 150,
      unlockedAt: DateTime.now(),
      criteria: {'bossesDefeated': 1},
    ),
  ];

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'ftReward': ftReward,
      'unlockedAt': unlockedAt.toIso8601String(),
      'criteria': criteria,
      'metadata': metadata,
    };
  }

  /// Création depuis JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: AchievementType.values.firstWhere((e) => e.name == json['type']),
      ftReward: json['ftReward'] as int,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      criteria: Map<String, dynamic>.from(json['criteria'] ?? {}),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Progression complète du joueur
class PlayerProgress {
  final int totalFTEarned;
  final int currentFTBalance;
  final int totalPomodoroSessions;
  final int completedPomodoroSessions;
  final int totalStepsTaken;
  final int dailySteps;
  final int currentWorldLevel;
  final int tilesRevealed;
  final int bossesDefeated;
  final List<Achievement> unlockedAchievements;
  final CombatStats combatStats;
  final DateTime lastPlayTime;
  final DateTime createdAt;
  final Map<String, dynamic> statistics;

  const PlayerProgress({
    this.totalFTEarned = 0,
    this.currentFTBalance = 0,
    this.totalPomodoroSessions = 0,
    this.completedPomodoroSessions = 0,
    this.totalStepsTaken = 0,
    this.dailySteps = 0,
    this.currentWorldLevel = 1,
    this.tilesRevealed = 0,
    this.bossesDefeated = 0,
    this.unlockedAchievements = const [],
    required this.combatStats,
    required this.lastPlayTime,
    required this.createdAt,
    this.statistics = const {},
  });

  /// Progression initiale
  factory PlayerProgress.initial() {
    final now = DateTime.now();
    return PlayerProgress(
      combatStats: CombatStats.initial(),
      lastPlayTime: now,
      createdAt: now,
    );
  }

  /// Ajouter des FT gagnés
  PlayerProgress addFTEarned(int amount) {
    return copyWith(
      totalFTEarned: totalFTEarned + amount,
      currentFTBalance: currentFTBalance + amount,
    );
  }

  /// Dépenser des FT
  PlayerProgress spendFT(int amount) {
    if (amount > currentFTBalance) {
      throw ArgumentError('Solde FT insuffisant: $currentFTBalance < $amount');
    }
    return copyWith(
      currentFTBalance: currentFTBalance - amount,
    );
  }

  /// Ajouter une session Pomodoro
  PlayerProgress addPomodoroSession({required bool wasCompleted, required int ftEarned}) {
    return copyWith(
      totalPomodoroSessions: totalPomodoroSessions + 1,
      completedPomodoroSessions: wasCompleted ? completedPomodoroSessions + 1 : completedPomodoroSessions,
    ).addFTEarned(ftEarned);
  }

  /// Ajouter des pas
  PlayerProgress addSteps(int steps) {
    final today = DateTime.now();
    final lastPlayDay = DateTime(lastPlayTime.year, lastPlayTime.month, lastPlayTime.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    
    // Reset daily steps if it's a new day
    final newDailySteps = lastPlayDay.isBefore(todayDay) ? steps : dailySteps + steps;
    
    return copyWith(
      totalStepsTaken: totalStepsTaken + steps,
      dailySteps: newDailySteps,
      lastPlayTime: today,
    );
  }

  /// Révéler des tuiles
  PlayerProgress revealTiles(int count) {
    return copyWith(tilesRevealed: tilesRevealed + count);
  }

  /// Battre un boss
  PlayerProgress defeatBoss() {
    return copyWith(bossesDefeated: bossesDefeated + 1);
  }

  /// Monter de niveau dans le monde
  PlayerProgress levelUpWorld() {
    return copyWith(currentWorldLevel: currentWorldLevel + 1);
  }

  /// Débloquer un achievement
  PlayerProgress unlockAchievement(Achievement achievement) {
    if (unlockedAchievements.any((a) => a.id == achievement.id)) {
      return this; // Déjà débloqué
    }
    
    return copyWith(
      unlockedAchievements: [...unlockedAchievements, achievement],
    ).addFTEarned(achievement.ftReward);
  }

  /// Vérifier et débloquer les achievements automatiquement
  PlayerProgress checkAchievements() {
    PlayerProgress updated = this;
    
    for (final achievement in Achievement.predefinedAchievements) {
      if (unlockedAchievements.any((a) => a.id == achievement.id)) {
        continue; // Déjà débloqué
      }
      
      bool shouldUnlock = false;
      
      switch (achievement.id) {
        case 'first_step':
          shouldUnlock = completedPomodoroSessions >= 1;
          break;
        case 'walker':
          shouldUnlock = dailySteps >= 10000;
          break;
        case 'explorer':
          shouldUnlock = tilesRevealed >= 50;
          break;
        case 'time_master':
          shouldUnlock = completedPomodoroSessions >= 100;
          break;
        case 'boss_slayer':
          shouldUnlock = bossesDefeated >= 1;
          break;
      }
      
      if (shouldUnlock) {
        updated = updated.unlockAchievement(achievement);
      }
    }
    
    return updated;
  }

  /// Calculer le ratio de réussite Pomodoro
  double get pomodoroSuccessRate {
    if (totalPomodoroSessions == 0) return 0.0;
    return completedPomodoroSessions / totalPomodoroSessions;
  }

  /// FT gagnés par pas (100 pas = 1 FT)
  int get ftFromSteps => totalStepsTaken ~/ 100;

  /// Pourcentage de progression vers le niveau suivant
  double get worldProgressPercentage {
    // Logique basée sur les FT dépensés pour débloquer le niveau suivant
    const baseRequirement = 500;
    final requirement = baseRequirement * currentWorldLevel;
    final spent = totalFTEarned - currentFTBalance;
    return (spent / requirement).clamp(0.0, 1.0);
  }

  /// Méthode copyWith pour l'immutabilité
  PlayerProgress copyWith({
    int? totalFTEarned,
    int? currentFTBalance,
    int? totalPomodoroSessions,
    int? completedPomodoroSessions,
    int? totalStepsTaken,
    int? dailySteps,
    int? currentWorldLevel,
    int? tilesRevealed,
    int? bossesDefeated,
    List<Achievement>? unlockedAchievements,
    CombatStats? combatStats,
    DateTime? lastPlayTime,
    DateTime? createdAt,
    Map<String, dynamic>? statistics,
  }) {
    return PlayerProgress(
      totalFTEarned: totalFTEarned ?? this.totalFTEarned,
      currentFTBalance: currentFTBalance ?? this.currentFTBalance,
      totalPomodoroSessions: totalPomodoroSessions ?? this.totalPomodoroSessions,
      completedPomodoroSessions: completedPomodoroSessions ?? this.completedPomodoroSessions,
      totalStepsTaken: totalStepsTaken ?? this.totalStepsTaken,
      dailySteps: dailySteps ?? this.dailySteps,
      currentWorldLevel: currentWorldLevel ?? this.currentWorldLevel,
      tilesRevealed: tilesRevealed ?? this.tilesRevealed,
      bossesDefeated: bossesDefeated ?? this.bossesDefeated,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      combatStats: combatStats ?? this.combatStats,
      lastPlayTime: lastPlayTime ?? this.lastPlayTime,
      createdAt: createdAt ?? this.createdAt,
      statistics: statistics ?? this.statistics,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'totalFTEarned': totalFTEarned,
      'currentFTBalance': currentFTBalance,
      'totalPomodoroSessions': totalPomodoroSessions,
      'completedPomodoroSessions': completedPomodoroSessions,
      'totalStepsTaken': totalStepsTaken,
      'dailySteps': dailySteps,
      'currentWorldLevel': currentWorldLevel,
      'tilesRevealed': tilesRevealed,
      'bossesDefeated': bossesDefeated,
      'unlockedAchievements': unlockedAchievements.map((a) => a.toJson()).toList(),
      'combatStats': combatStats.toJson(),
      'lastPlayTime': lastPlayTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'statistics': statistics,
    };
  }

  /// Création depuis JSON
  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      totalFTEarned: json['totalFTEarned'] as int? ?? 0,
      currentFTBalance: json['currentFTBalance'] as int? ?? 0,
      totalPomodoroSessions: json['totalPomodoroSessions'] as int? ?? 0,
      completedPomodoroSessions: json['completedPomodoroSessions'] as int? ?? 0,
      totalStepsTaken: json['totalStepsTaken'] as int? ?? 0,
      dailySteps: json['dailySteps'] as int? ?? 0,
      currentWorldLevel: json['currentWorldLevel'] as int? ?? 1,
      tilesRevealed: json['tilesRevealed'] as int? ?? 0,
      bossesDefeated: json['bossesDefeated'] as int? ?? 0,
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>? ?? [])
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
      combatStats: CombatStats.fromJson(json['combatStats'] as Map<String, dynamic>? ?? {}),
      lastPlayTime: DateTime.parse(json['lastPlayTime'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'PlayerProgress{FT: $currentFTBalance/$totalFTEarned, level: $currentWorldLevel, pomodoros: $completedPomodoroSessions/$totalPomodoroSessions}';
  }
}
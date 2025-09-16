import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/models.dart';

/// Service de stockage local utilisant SQLite et SharedPreferences
class StorageService {
  static StorageService? _instance;
  static Database? _database;
  static SharedPreferences? _prefs;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  /// Initialiser le service de stockage
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _initDatabase();
  }

  /// Initialiser la base de données SQLite
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'chronocore.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Créer les tables
  Future<void> _onCreate(Database db, int version) async {
    // Table des fragments de temps
    await db.execute('''
      CREATE TABLE time_fragments (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        earned_at TEXT NOT NULL,
        source TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // Table des sessions Pomodoro
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id TEXT PRIMARY KEY,
        duration INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        status TEXT NOT NULL,
        ft_earned INTEGER DEFAULT 0,
        was_app_left INTEGER DEFAULT 0,
        time_out_of_app INTEGER DEFAULT 0,
        app_exit_times TEXT,
        app_return_times TEXT
      )
    ''');

    // Table des achievements
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        ft_reward INTEGER NOT NULL,
        unlocked_at TEXT NOT NULL,
        criteria TEXT,
        metadata TEXT
      )
    ''');

    // Table des tuiles du monde
    await db.execute('''
      CREATE TABLE world_tiles (
        world_level INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        type TEXT NOT NULL,
        is_revealed INTEGER DEFAULT 0,
        is_interactable INTEGER DEFAULT 0,
        ft_cost_to_reveal INTEGER DEFAULT 20,
        properties TEXT,
        PRIMARY KEY (world_level, x, y)
      )
    ''');
  }

  /// Mettre à jour la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures
  }

  /// Sauvegarder la progression du joueur
  Future<void> savePlayerProgress(PlayerProgress progress) async {
    if (_prefs == null) throw Exception('StorageService non initialisé');
    
    final json = jsonEncode(progress.toJson());
    await _prefs!.setString('player_progress', json);
  }

  /// Charger la progression du joueur
  Future<PlayerProgress?> loadPlayerProgress() async {
    if (_prefs == null) throw Exception('StorageService non initialisé');
    
    final json = _prefs!.getString('player_progress');
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PlayerProgress.fromJson(map);
    } catch (e) {
      print('Erreur lors du chargement de la progression: $e');
      return null;
    }
  }

  /// Sauvegarder l'état du monde
  Future<void> saveWorldState(WorldState worldState) async {
    if (_prefs == null) throw Exception('StorageService non initialisé');
    
    final json = jsonEncode(worldState.toJson());
    await _prefs!.setString('world_state', json);
  }

  /// Charger l'état du monde
  Future<WorldState?> loadWorldState() async {
    if (_prefs == null) throw Exception('StorageService non initialisé');
    
    final json = _prefs!.getString('world_state');
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return WorldState.fromJson(map);
    } catch (e) {
      print('Erreur lors du chargement du monde: $e');
      return null;
    }
  }

  /// Sauvegarder un fragment de temps
  Future<void> saveTimeFragment(TimeFragment fragment) async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    await _database!.insert(
      'time_fragments',
      {
        'id': fragment.id,
        'amount': fragment.amount,
        'earned_at': fragment.earnedAt.toIso8601String(),
        'source': fragment.source.name,
        'metadata': jsonEncode(fragment.metadata),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Charger tous les fragments de temps
  Future<TimeFragmentCollection> loadTimeFragments() async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    final List<Map<String, dynamic>> maps = await _database!.query('time_fragments');
    
    final fragments = maps.map((map) {
      return TimeFragment(
        id: map['id'] as String,
        amount: map['amount'] as int,
        earnedAt: DateTime.parse(map['earned_at'] as String),
        source: FragmentSource.values.firstWhere((e) => e.name == map['source']),
        metadata: jsonDecode(map['metadata'] as String? ?? '{}') as Map<String, dynamic>,
      );
    }).toList();

    return TimeFragmentCollection(fragments);
  }

  /// Sauvegarder une session Pomodoro
  Future<void> savePomodoroSession(PomodoroSession session) async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    await _database!.insert(
      'pomodoro_sessions',
      {
        'id': session.id,
        'duration': session.duration.inMilliseconds,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'status': session.status.name,
        'ft_earned': session.ftEarned,
        'was_app_left': session.wasAppLeft ? 1 : 0,
        'time_out_of_app': session.timeOutOfApp.inMilliseconds,
        'app_exit_times': jsonEncode(session.appExitTimes.map((t) => t.toIso8601String()).toList()),
        'app_return_times': jsonEncode(session.appReturnTimes.map((t) => t.toIso8601String()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Charger l'historique des sessions Pomodoro (les 100 dernières)
  Future<List<PomodoroSession>> loadPomodoroSessions() async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'pomodoro_sessions',
      orderBy: 'start_time DESC',
      limit: 100,
    );
    
    return maps.map((map) {
      return PomodoroSession(
        id: map['id'] as String,
        duration: Duration(milliseconds: map['duration'] as int),
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null 
            ? DateTime.parse(map['end_time'] as String) 
            : null,
        status: SessionStatus.values.firstWhere((e) => e.name == map['status']),
        ftEarned: map['ft_earned'] as int? ?? 0,
        wasAppLeft: (map['was_app_left'] as int? ?? 0) == 1,
        timeOutOfApp: Duration(milliseconds: map['time_out_of_app'] as int? ?? 0),
        appExitTimes: (jsonDecode(map['app_exit_times'] as String? ?? '[]') as List<dynamic>)
            .map((t) => DateTime.parse(t as String))
            .toList(),
        appReturnTimes: (jsonDecode(map['app_return_times'] as String? ?? '[]') as List<dynamic>)
            .map((t) => DateTime.parse(t as String))
            .toList(),
      );
    }).toList();
  }

  /// Sauvegarder un achievement
  Future<void> saveAchievement(Achievement achievement) async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    await _database!.insert(
      'achievements',
      {
        'id': achievement.id,
        'name': achievement.name,
        'description': achievement.description,
        'type': achievement.type.name,
        'ft_reward': achievement.ftReward,
        'unlocked_at': achievement.unlockedAt.toIso8601String(),
        'criteria': jsonEncode(achievement.criteria),
        'metadata': jsonEncode(achievement.metadata),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Charger les achievements débloqués
  Future<List<Achievement>> loadAchievements() async {
    if (_database == null) throw Exception('Base de données non initialisée');
    
    final List<Map<String, dynamic>> maps = await _database!.query('achievements');
    
    return maps.map((map) {
      return Achievement(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        type: AchievementType.values.firstWhere((e) => e.name == map['type']),
        ftReward: map['ft_reward'] as int,
        unlockedAt: DateTime.parse(map['unlocked_at'] as String),
        criteria: jsonDecode(map['criteria'] as String? ?? '{}') as Map<String, dynamic>,
        metadata: jsonDecode(map['metadata'] as String? ?? '{}') as Map<String, dynamic>,
      );
    }).toList();
  }

  /// Sauvegarder une sauvegarde complète
  Future<void> saveGameSave(GameSave gameSave) async {
    // Sauvegarder les différents composants
    await Future.wait([
      savePlayerProgress(gameSave.playerProgress),
      saveWorldState(gameSave.currentWorld),
    ]);

    // Sauvegarder les sessions récentes
    for (final session in gameSave.sessionHistory) {
      await savePomodoroSession(session);
    }

    // Sauvegarder les fragments
    for (final fragment in gameSave.fragmentCollection.fragments) {
      await saveTimeFragment(fragment);
    }

    // Sauvegarder les achievements
    for (final achievement in gameSave.playerProgress.unlockedAchievements) {
      await saveAchievement(achievement);
    }

    // Sauvegarder les paramètres
    if (_prefs != null) {
      final settingsJson = jsonEncode(gameSave.gameSettings);
      await _prefs!.setString('game_settings', settingsJson);
    }
  }

  /// Charger une sauvegarde complète
  Future<GameSave?> loadGameSave() async {
    try {
      final playerProgress = await loadPlayerProgress();
      final worldState = await loadWorldState();
      final sessionHistory = await loadPomodoroSessions();
      final fragmentCollection = await loadTimeFragments();

      if (playerProgress == null || worldState == null) {
        return null; // Pas de sauvegarde existante
      }

      // Charger les paramètres
      Map<String, dynamic> gameSettings = {};
      if (_prefs != null) {
        final settingsJson = _prefs!.getString('game_settings');
        if (settingsJson != null) {
          gameSettings = jsonDecode(settingsJson) as Map<String, dynamic>;
        }
      }

      return GameSave(
        playerProgress: playerProgress,
        currentWorld: worldState,
        sessionHistory: sessionHistory,
        fragmentCollection: fragmentCollection,
        lastPlayTime: DateTime.now(),
        gameSettings: gameSettings,
      );
    } catch (e) {
      print('Erreur lors du chargement de la sauvegarde: $e');
      return null;
    }
  }

  /// Supprimer toutes les données (reset)
  Future<void> clearAllData() async {
    if (_database != null) {
      await _database!.delete('time_fragments');
      await _database!.delete('pomodoro_sessions');
      await _database!.delete('achievements');
      await _database!.delete('world_tiles');
    }

    if (_prefs != null) {
      await _prefs!.clear();
    }
  }

  /// Fermer les connexions
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
    _prefs = null;
    _instance = null;
  }
}
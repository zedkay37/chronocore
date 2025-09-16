/// Statut d'une session Pomodoro
enum SessionStatus {
  pending,   // En attente de démarrage
  active,    // En cours
  paused,    // En pause
  completed, // Terminée avec succès
  failed,    // Échouée (app quittée trop longtemps)
  cancelled, // Annulée manuellement
}

/// Session Pomodoro avec suivi du focus
class PomodoroSession {
  final String id;
  final Duration duration;
  final DateTime startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final int ftEarned;
  final bool wasAppLeft;
  final Duration timeOutOfApp;
  final List<DateTime> appExitTimes;
  final List<DateTime> appReturnTimes;

  const PomodoroSession({
    required this.id,
    required this.duration,
    required this.startTime,
    this.endTime,
    required this.status,
    this.ftEarned = 0,
    this.wasAppLeft = false,
    this.timeOutOfApp = Duration.zero,
    this.appExitTimes = const [],
    this.appReturnTimes = const [],
  });

  /// Créer une nouvelle session
  factory PomodoroSession.create({
    required String id,
    required Duration duration,
  }) {
    return PomodoroSession(
      id: id,
      duration: duration,
      startTime: DateTime.now(),
      status: SessionStatus.pending,
    );
  }

  /// Durées standard de session
  static const Duration duration25min = Duration(minutes: 25);
  static const Duration duration45min = Duration(minutes: 45);
  static const Duration duration90min = Duration(minutes: 90);

  /// Calculer les FT gagnés selon les règles
  static int calculateFTEarned({
    required Duration sessionDuration,
    required Duration actualDuration,
    required bool wasCompleted,
    required bool wasAppLeft,
    required Duration timeOutOfApp,
  }) {
    // Échec si l'app est quittée > 30 secondes
    if (wasAppLeft && timeOutOfApp.inSeconds > 30) {
      return 0;
    }

    // 1 FT par minute réussie
    final completedMinutes = actualDuration.inMinutes;
    int baseFT = completedMinutes;

    // Bonus de +5 FT pour session complète
    if (wasCompleted && actualDuration >= sessionDuration) {
      baseFT += 5;
    }

    return baseFT;
  }

  /// Temps écoulé depuis le début
  Duration get elapsedTime {
    final now = DateTime.now();
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return now.difference(startTime);
  }

  /// Temps restant
  Duration get remainingTime {
    final elapsed = elapsedTime;
    if (elapsed >= duration) {
      return Duration.zero;
    }
    return duration - elapsed;
  }

  /// Pourcentage de progression
  double get progressPercentage {
    final elapsed = elapsedTime.inMilliseconds;
    final total = duration.inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  /// Marquer la session comme démarrée
  PomodoroSession start() {
    return copyWith(
      status: SessionStatus.active,
      startTime: DateTime.now(),
    );
  }

  /// Marquer l'app comme quittée
  PomodoroSession markAppLeft() {
    return copyWith(
      wasAppLeft: true,
      appExitTimes: [...appExitTimes, DateTime.now()],
    );
  }

  /// Marquer le retour dans l'app
  PomodoroSession markAppReturned() {
    final now = DateTime.now();
    if (appExitTimes.isNotEmpty && appReturnTimes.length < appExitTimes.length) {
      final lastExit = appExitTimes.last;
      final additionalTimeOut = now.difference(lastExit);
      
      return copyWith(
        timeOutOfApp: timeOutOfApp + additionalTimeOut,
        appReturnTimes: [...appReturnTimes, now],
      );
    }
    return this;
  }

  /// Terminer la session
  PomodoroSession complete() {
    final now = DateTime.now();
    final actualDuration = now.difference(startTime);
    final wasCompleted = actualDuration >= duration;
    
    final earned = calculateFTEarned(
      sessionDuration: duration,
      actualDuration: actualDuration,
      wasCompleted: wasCompleted,
      wasAppLeft: wasAppLeft,
      timeOutOfApp: timeOutOfApp,
    );

    return copyWith(
      status: wasCompleted ? SessionStatus.completed : SessionStatus.failed,
      endTime: now,
      ftEarned: earned,
    );
  }

  /// Annuler la session
  PomodoroSession cancel() {
    return copyWith(
      status: SessionStatus.cancelled,
      endTime: DateTime.now(),
    );
  }

  /// Mettre en pause
  PomodoroSession pause() {
    return copyWith(status: SessionStatus.paused);
  }

  /// Reprendre
  PomodoroSession resume() {
    return copyWith(status: SessionStatus.active);
  }

  /// Méthode copyWith pour l'immutabilité
  PomodoroSession copyWith({
    String? id,
    Duration? duration,
    DateTime? startTime,
    DateTime? endTime,
    SessionStatus? status,
    int? ftEarned,
    bool? wasAppLeft,
    Duration? timeOutOfApp,
    List<DateTime>? appExitTimes,
    List<DateTime>? appReturnTimes,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      ftEarned: ftEarned ?? this.ftEarned,
      wasAppLeft: wasAppLeft ?? this.wasAppLeft,
      timeOutOfApp: timeOutOfApp ?? this.timeOutOfApp,
      appExitTimes: appExitTimes ?? this.appExitTimes,
      appReturnTimes: appReturnTimes ?? this.appReturnTimes,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'duration': duration.inMilliseconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status.name,
      'ftEarned': ftEarned,
      'wasAppLeft': wasAppLeft,
      'timeOutOfApp': timeOutOfApp.inMilliseconds,
      'appExitTimes': appExitTimes.map((t) => t.toIso8601String()).toList(),
      'appReturnTimes': appReturnTimes.map((t) => t.toIso8601String()).toList(),
    };
  }

  /// Création depuis JSON
  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String) 
          : null,
      status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
      ftEarned: json['ftEarned'] as int? ?? 0,
      wasAppLeft: json['wasAppLeft'] as bool? ?? false,
      timeOutOfApp: Duration(milliseconds: json['timeOutOfApp'] as int? ?? 0),
      appExitTimes: (json['appExitTimes'] as List<dynamic>? ?? [])
          .map((t) => DateTime.parse(t as String))
          .toList(),
      appReturnTimes: (json['appReturnTimes'] as List<dynamic>? ?? [])
          .map((t) => DateTime.parse(t as String))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PomodoroSession{id: $id, duration: $duration, status: $status, ftEarned: $ftEarned}';
  }
}
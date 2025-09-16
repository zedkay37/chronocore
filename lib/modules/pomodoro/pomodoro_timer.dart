import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../models/models.dart';
import '../../services/services.dart';
import 'focus_tracker.dart';

/// États du timer Pomodoro
enum TimerState {
  idle,      // Pas de session active
  ready,     // Prêt à démarrer
  running,   // Session en cours
  paused,    // Session en pause
  completed, // Session terminée avec succès
  failed,    // Session échouée
}

/// Timer Pomodoro avec suivi du focus et génération de FT
class PomodoroTimer extends ChangeNotifier {
  static PomodoroTimer? _instance;
  
  TimerState _state = TimerState.idle;
  PomodoroSession? _currentSession;
  Timer? _timer;
  
  final FocusTracker _focusTracker = FocusTracker();
  final GameService _gameService = GameService.instance;
  
  // Callbacks pour les notifications
  VoidCallback? _onSessionCompleted;
  VoidCallback? _onSessionFailed;
  ValueChanged<Duration>? _onTick;

  PomodoroTimer._();

  static PomodoroTimer get instance {
    _instance ??= PomodoroTimer._();
    return _instance!;
  }

  /// État actuel du timer
  TimerState get state => _state;
  PomodoroSession? get currentSession => _currentSession;
  FocusTracker get focusTracker => _focusTracker;

  /// Durée sélectionnée
  Duration? get selectedDuration => _currentSession?.duration;

  /// Temps écoulé
  Duration get elapsedTime => _currentSession?.elapsedTime ?? Duration.zero;

  /// Temps restant
  Duration get remainingTime => _currentSession?.remainingTime ?? Duration.zero;

  /// Pourcentage de progression
  double get progressPercentage => _currentSession?.progressPercentage ?? 0.0;

  /// Minutes écoulées
  int get minutesElapsed => elapsedTime.inMinutes;

  /// Configurer les callbacks
  void setCallbacks({
    VoidCallback? onSessionCompleted,
    VoidCallback? onSessionFailed,
    ValueChanged<Duration>? onTick,
  }) {
    _onSessionCompleted = onSessionCompleted;
    _onSessionFailed = onSessionFailed;
    _onTick = onTick;
  }

  /// Démarrer une nouvelle session
  Future<bool> startSession(Duration duration) async {
    if (_state != TimerState.idle && _state != TimerState.ready) {
      debugPrint('Impossible de démarrer: session déjà active');
      return false;
    }

    try {
      // Créer une nouvelle session
      final sessionId = _generateSessionId();
      _currentSession = PomodoroSession.create(
        id: sessionId,
        duration: duration,
      );

      // Réinitialiser le tracker de focus
      _focusTracker.reset();

      // Changer l'état et démarrer le timer
      _state = TimerState.running;
      _currentSession = _currentSession!.start();
      
      _startTimer();
      
      debugPrint('Session Pomodoro démarrée: ${duration.inMinutes} minutes');
      notifyListeners();
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage de la session: $e');
      return false;
    }
  }

  /// Mettre en pause la session
  void pauseSession() {
    if (_state != TimerState.running) return;

    _timer?.cancel();
    _state = TimerState.paused;
    _currentSession = _currentSession?.pause();
    
    debugPrint('Session mise en pause');
    notifyListeners();
  }

  /// Reprendre la session
  void resumeSession() {
    if (_state != TimerState.paused) return;

    _state = TimerState.running;
    _currentSession = _currentSession?.resume();
    _startTimer();
    
    debugPrint('Session reprise');
    notifyListeners();
  }

  /// Annuler la session
  void cancelSession() {
    if (_state == TimerState.idle) return;

    _timer?.cancel();
    _state = TimerState.failed;
    _currentSession = _currentSession?.cancel();
    
    debugPrint('Session annulée');
    notifyListeners();
    
    // Nettoyer après un délai
    Timer(const Duration(seconds: 2), _resetSession);
  }

  /// Terminer la session
  Future<void> endSession() async {
    if (_currentSession == null) return;

    _timer?.cancel();

    // Calculer la récompense FT
    final ftEarned = _focusTracker.calculateFTReward(
      sessionDuration: _currentSession!.duration,
      actualDuration: _currentSession!.elapsedTime,
      wasCompleted: _currentSession!.elapsedTime >= _currentSession!.duration,
    );

    // Compléter la session
    _currentSession = _currentSession!.copyWith(ftEarned: ftEarned).complete();

    // Déterminer l'état final
    if (_currentSession!.status == SessionStatus.completed) {
      _state = TimerState.completed;
      _onSessionCompleted?.call();
      
      // Enregistrer la session réussie
      await _gameService.completePomodoroSession(_currentSession!);
      
      debugPrint('Session terminée avec succès: $ftEarned FT gagnés');
    } else {
      _state = TimerState.failed;
      _onSessionFailed?.call();
      
      debugPrint('Session échouée');
    }

    notifyListeners();
    
    // Nettoyer après un délai
    Timer(const Duration(seconds: 3), _resetSession);
  }

  /// Démarrer le timer interne
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession == null) {
        timer.cancel();
        return;
      }

      // Vérifier si la session est terminée
      if (_currentSession!.remainingTime <= Duration.zero) {
        timer.cancel();
        endSession();
        return;
      }

      // Vérifier l'intégrité du focus
      if (!_focusTracker.validateFocusIntegrity()) {
        timer.cancel();
        _failSession();
        return;
      }

      // Notifier le tick
      _onTick?.call(remainingTime);
      notifyListeners();
    });
  }

  /// Marquer la session comme échouée
  void _failSession() {
    _state = TimerState.failed;
    _currentSession = _currentSession?.copyWith(
      status: SessionStatus.failed,
      endTime: DateTime.now(),
    );
    
    _onSessionFailed?.call();
    notifyListeners();
    
    debugPrint('Session échouée: focus perdu');
    Timer(const Duration(seconds: 2), _resetSession);
  }

  /// Réinitialiser pour une nouvelle session
  void _resetSession() {
    _currentSession = null;
    _state = TimerState.idle;
    _timer?.cancel();
    _focusTracker.reset();
    
    notifyListeners();
  }

  /// Gérer le changement de cycle de vie de l'app
  void onAppLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _focusTracker.markAppBackground();
        break;
      case AppLifecycleState.resumed:
        _focusTracker.markAppForeground();
        break;
      case AppLifecycleState.inactive:
        // Ne rien faire pour inactive
        break;
    }
  }

  /// Générer un ID unique pour la session
  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = random.nextInt(999999);
    return 'pomodoro_${timestamp}_$randomPart';
  }

  /// Obtenir les durées standard
  static List<Duration> get standardDurations => [
    PomodoroSession.duration25min,
    PomodoroSession.duration45min,
    PomodoroSession.duration90min,
  ];

  /// Estimer les FT à gagner pour une durée
  static int estimateFTReward(Duration duration) {
    // Estimation optimiste (session complète + bonus)
    return duration.inMinutes + 5;
  }

  /// Obtenir les statistiques de la session actuelle
  Map<String, dynamic> getCurrentSessionStats() {
    if (_currentSession == null) return {};

    return {
      'id': _currentSession!.id,
      'duration': _currentSession!.duration.inMinutes,
      'elapsed': elapsedTime.inMinutes,
      'remaining': remainingTime.inMinutes,
      'progress': progressPercentage,
      'state': _state.name,
      'status': _currentSession!.status.name,
      'estimatedFT': estimateFTReward(_currentSession!.duration),
      'focus': _focusTracker.getFocusStatistics(),
    };
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusTracker.dispose();
    super.dispose();
  }
}
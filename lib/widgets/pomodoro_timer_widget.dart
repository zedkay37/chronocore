import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../models/models.dart';
import '../modules/pomodoro/pomodoro.dart';

/// Widget timer Pomodoro avec progression circulaire
class PomodoroTimerWidget extends StatefulWidget {
  final Duration? selectedDuration;
  final Function(int) onFTEarned;
  final VoidCallback? onSessionComplete;
  final VoidCallback? onSessionFailed;

  const PomodoroTimerWidget({
    super.key,
    this.selectedDuration,
    required this.onFTEarned,
    this.onSessionComplete,
    this.onSessionFailed,
  });

  @override
  State<PomodoroTimerWidget> createState() => _PomodoroTimerWidgetState();
}

class _PomodoroTimerWidgetState extends State<PomodoroTimerWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final PomodoroTimer _timer = PomodoroTimer.instance;
  Duration? _selectedDuration;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _selectedDuration = widget.selectedDuration ?? PomodoroSession.duration25min;
    
    // Configurer les callbacks du timer
    _timer.setCallbacks(
      onSessionCompleted: () {
        widget.onFTEarned(_timer.currentSession?.ftEarned ?? 0);
        widget.onSessionComplete?.call();
        _pulseController.stop();
      },
      onSessionFailed: () {
        widget.onSessionFailed?.call();
        _pulseController.stop();
      },
      onTick: (remaining) {
        setState(() {});
      },
    );

    _timer.addListener(_onTimerStateChanged);
  }

  void _onTimerStateChanged() {
    setState(() {});
    
    if (_timer.state == TimerState.running) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _timer.removeListener(_onTimerStateChanged);
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectDuration(Duration duration) {
    if (_timer.state == TimerState.idle || _timer.state == TimerState.ready) {
      setState(() {
        _selectedDuration = duration;
      });
    }
  }

  void _startSession() {
    if (_selectedDuration != null) {
      _timer.startSession(_selectedDuration!);
    }
  }

  void _pauseSession() {
    _timer.pauseSession();
  }

  void _resumeSession() {
    _timer.resumeSession();
  }

  void _cancelSession() {
    _timer.cancelSession();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark 
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer.withOpacity(0.1),
            isDark 
              ? theme.colorScheme.surface.withOpacity(0.8)
              : theme.colorScheme.secondaryContainer.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Sélecteur de durée
          if (_timer.state == TimerState.idle || _timer.state == TimerState.ready)
            _buildDurationSelector(theme),
          
          const SizedBox(height: 32),
          
          // Timer circulaire
          _buildCircularTimer(theme, isDark),
          
          const SizedBox(height: 32),
          
          // Informations de session
          _buildSessionInfo(theme),
          
          const SizedBox(height: 24),
          
          // Boutons de contrôle
          _buildControlButtons(theme),
        ],
      ),
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Choisir la durée',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: PomodoroTimer.standardDurations.map((duration) {
            final isSelected = _selectedDuration == duration;
            return GestureDetector(
              onTap: () => _selectDuration(duration),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${duration.inMinutes}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: isSelected 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'min',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected 
                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCircularTimer(ThemeData theme, bool isDark) {
    final progress = _timer.progressPercentage;
    final remainingTime = _timer.remainingTime;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _timer.state == TimerState.running ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de fond
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 12,
                  backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                // Cercle de progression
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(theme, isDark),
                  ),
                ),
                // Temps restant
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDuration(remainingTime),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _getStateText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionInfo(ThemeData theme) {
    final estimatedFT = _selectedDuration != null 
        ? PomodoroTimer.estimateFTReward(_selectedDuration!)
        : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            theme,
            'FT Estimés',
            '$estimatedFT',
            Icons.auto_awesome,
          ),
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor,
          ),
          _buildInfoItem(
            theme,
            'Temps Écoulé',
            '${_timer.minutesElapsed} min',
            Icons.timer,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(ThemeData theme) {
    switch (_timer.state) {
      case TimerState.idle:
      case TimerState.ready:
        return ElevatedButton.icon(
          onPressed: _selectedDuration != null ? _startSession : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Commencer'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      
      case TimerState.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pauseSession,
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _cancelSession,
              icon: const Icon(Icons.stop),
              label: const Text('Arrêter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        );
      
      case TimerState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _resumeSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reprendre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _cancelSession,
              icon: const Icon(Icons.stop),
              label: const Text('Arrêter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
            ),
          ],
        );
      
      case TimerState.completed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.primaryContainer,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Session terminée !',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      
      case TimerState.failed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.errorContainer,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Session échouée',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Color _getProgressColor(ThemeData theme, bool isDark) {
    switch (_timer.state) {
      case TimerState.running:
        return theme.colorScheme.primary;
      case TimerState.paused:
        return theme.colorScheme.secondary;
      case TimerState.completed:
        return theme.colorScheme.tertiary;
      case TimerState.failed:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _getStateText() {
    switch (_timer.state) {
      case TimerState.idle:
      case TimerState.ready:
        return 'Prêt à commencer';
      case TimerState.running:
        return 'Session en cours';
      case TimerState.paused:
        return 'En pause';
      case TimerState.completed:
        return 'Terminé !';
      case TimerState.failed:
        return 'Échoué';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
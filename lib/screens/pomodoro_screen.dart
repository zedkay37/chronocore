import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/widgets.dart';
import '../services/services.dart';
import '../models/models.dart';

/// Écran Pomodoro avec timer et contrôles
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  final GameService _gameService = GameService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<GameService>(
        builder: (context, gameService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Titre de la section
                Text(
                  'Session Pomodoro',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Concentrez-vous pour gagner des Fragments de Temps',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Timer principal
                PomodoroTimerWidget(
                  onFTEarned: _onFTEarned,
                  onSessionComplete: _onSessionComplete,
                  onSessionFailed: _onSessionFailed,
                ),
                
                const SizedBox(height: 32),
                
                // Statistiques de session
                _buildSessionStats(theme, gameService),
                
                const SizedBox(height: 24),
                
                // Conseils de focus
                _buildFocusTips(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onFTEarned(int amount) {
    if (amount > 0) {
      // Afficher une notification de gain
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: 8),
              Text('Vous avez gagné $amount Fragments de Temps !'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onSessionComplete() {
    // Vibration ou feedback haptique
    // HapticFeedback.heavyImpact();
    
    // Afficher félicitations
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('Félicitations !'),
          ],
        ),
        content: const Text(
          'Vous avez terminé votre session Pomodoro avec succès ! '
          'Vos Fragments de Temps ont été ajoutés et de nouvelles zones '
          'du monde ont été révélées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _onSessionFailed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text('Session échouée. Restez concentré pour gagner des FT !'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSessionStats(ThemeData theme, GameService gameService) {
    final progress = gameService.playerProgress;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos Statistiques',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Sessions Totales',
                  '${progress.totalPomodoroSessions}',
                  Icons.timer,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Sessions Réussies',
                  '${progress.completedPomodoroSessions}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Taux de Réussite',
                  '${(progress.pomodoroSuccessRate * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'FT Gagnés',
                  '${gameService.fragmentService.getEarnedBySource(FragmentSource.pomodoro)}',
                  Icons.auto_awesome,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withOpacity(0.5),
      ),
      child: Column(
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTips(ThemeData theme) {
    final tips = [
      'Éliminez les distractions autour de vous',
      'Gardez l\'application au premier plan',
      'Prenez des pauses entre les sessions',
      'Hydratez-vous régulièrement',
      'Plus vous restez concentré, plus vous gagnez de FT !',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.2),
            theme.colorScheme.secondaryContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Conseils de Focus',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/services.dart';
import '../widgets/widgets.dart';
import '../modules/pedometer/pedometer.dart';
import 'pomodoro_screen.dart';
import 'world_screen.dart';

/// Écran principal de l'application (Hub)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final GameService _gameService = GameService.instance;
  final StepCounter _stepCounter = StepCounter.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _gameService.initialize();
      await _stepCounter.initialize();
      await _stepCounter.startTracking();
    } catch (e) {
      debugPrint('Erreur d\'initialisation: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<GameService>(
        builder: (context, gameService, child) {
          if (!gameService.isInitialized) {
            return _buildLoadingScreen(theme);
          }

          return Column(
            children: [
              // Header avec informations principales
              _buildHeader(theme, isDark, gameService),
              
              // Contenu principal avec onglets
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const _HomeTab(),
                    const PomodoroScreen(),
                    const WorldScreen(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(theme),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.1),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation de chargement avec icône sablier
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 3.14159,
                  child: Icon(
                    Icons.hourglass_empty,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Focus World',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initialisation...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, GameService gameService) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark 
              ? theme.colorScheme.surface
              : theme.colorScheme.primaryContainer.withOpacity(0.2),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          // Titre et FT
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Focus World',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Monde ${gameService.worldState.worldLevel}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              TimeFragmentDisplay(
                currentFT: gameService.fragmentService.currentBalance,
                showGainAnimation: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques rapides
          _buildQuickStats(theme, gameService),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, GameService gameService) {
    return Consumer<StepCounter>(
      builder: (context, stepCounter, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                theme,
                'Pas Aujourd\'hui',
                '${stepCounter.dailySteps}',
                Icons.directions_walk,
                stepCounter.dailyProgress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Sessions',
                '${gameService.playerProgress.completedPomodoroSessions}',
                Icons.timer,
                gameService.playerProgress.pomodoroSuccessRate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                theme,
                'Exploration',
                '${gameService.worldState.explorationTimeRemaining}min',
                Icons.explore,
                (gameService.worldState.explorationTimeRemaining / 45).clamp(0.0, 1.0),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
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
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.home),
            text: 'Hub',
          ),
          Tab(
            icon: Icon(Icons.timer),
            text: 'Pomodoro',
          ),
          Tab(
            icon: Icon(Icons.explore),
            text: 'Monde',
          ),
        ],
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: theme.colorScheme.primary,
      ),
    );
  }
}

/// Onglet principal du Hub
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<GameService>(
      builder: (context, gameService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section actions rapides
              _buildQuickActionsSection(context, theme, gameService),
              
              const SizedBox(height: 24),
              
              // Section progression
              _buildProgressSection(context, theme, gameService),
              
              const SizedBox(height: 24),
              
              // Section achievements récents
              _buildAchievementsSection(context, theme, gameService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    ThemeData theme,
    GameService gameService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions Rapides',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                theme,
                'Session Focus',
                'Commencer un Pomodoro',
                Icons.timer,
                () {
                  // Navigator vers l'onglet Pomodoro
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                theme,
                'Explorer',
                'Découvrir le monde',
                Icons.explore,
                gameService.worldState.explorationTimeRemaining > 0 
                  ? () {
                      // Navigator vers l'onglet Monde
                    }
                  : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isEnabled 
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : theme.colorScheme.surfaceVariant.withOpacity(0.2),
              isEnabled 
                ? theme.colorScheme.secondaryContainer.withOpacity(0.2)
                : theme.colorScheme.surfaceVariant.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isEnabled 
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEnabled 
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isEnabled 
                  ? theme.colorScheme.onSurface.withOpacity(0.6)
                  : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    ThemeData theme,
    GameService gameService,
  ) {
    final progress = gameService.playerProgress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progression',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Niveau de Monde',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${progress.currentWorldLevel}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.worldProgressPercentage,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progression vers le niveau suivant',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(
    BuildContext context,
    ThemeData theme,
    GameService gameService,
  ) {
    final achievements = gameService.playerProgress.unlockedAchievements;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${achievements.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (achievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun achievement débloqué',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...achievements.take(3).map((achievement) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '+${achievement.ftReward} FT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/services.dart';
import '../models/models.dart';

/// Écran du monde 2.5D avec exploration
class WorldScreen extends StatefulWidget {
  const WorldScreen({super.key});

  @override
  State<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends State<WorldScreen> {
  final GameService _gameService = GameService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<GameService>(
        builder: (context, gameService, child) {
          final worldState = gameService.worldState;
          final hasExplorationTime = worldState.explorationTimeRemaining > 0;

          return Column(
            children: [
              // Header du monde
              _buildWorldHeader(theme, worldState),
              
              // Zone principale
              Expanded(
                child: hasExplorationTime 
                  ? _buildActiveExploration(theme, worldState)
                  : _buildIdleMode(theme, gameService),
              ),
              
              // Footer avec actions
              _buildWorldFooter(theme, gameService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorldHeader(ThemeData theme, WorldState worldState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.2),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monde ${worldState.worldLevel}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getWorldName(worldState.worldLevel),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              if (worldState.explorationTimeRemaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${worldState.explorationTimeRemaining}min',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Statistiques du monde
          Row(
            children: [
              Expanded(
                child: _buildWorldStat(
                  theme,
                  'Tuiles Révélées',
                  '${worldState.revealedTiles.length}',
                  Icons.map,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWorldStat(
                  theme,
                  'Structures',
                  '${worldState.activeStructures.length}',
                  Icons.account_balance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWorldStat(
                  theme,
                  'Boss Débloqué',
                  worldState.isBossUnlocked ? 'Oui' : 'Non',
                  Icons.pets,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorldStat(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
            style: theme.textTheme.titleSmall?.copyWith(
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

  Widget _buildActiveExploration(ThemeData theme, WorldState worldState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation d'exploration
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 3),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.4),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.colorScheme.primary.withOpacity(0.3),
                        theme.colorScheme.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.explore,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Exploration Active',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Vous explorez le monde mystérieux...\n'
            'Tapez sur les éléments pour interagir avec eux.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Grille simple des tuiles révélées
          _buildSimpleWorldGrid(theme, worldState),
        ],
      ),
    );
  }

  Widget _buildIdleMode(ThemeData theme, GameService gameService) {
    final ftService = gameService.fragmentService;
    final canBuyTime = ftService.currentBalance >= 10;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Message principal
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Mode Idle',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Votre monde attend patiemment...\n'
                  'Gagnez des Fragments de Temps pour explorer !',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Options d'achat de temps
          if (canBuyTime)
            _buildTimeShop(theme, ftService),
          
          const SizedBox(height: 24),
          
          // Dernière exploration
          _buildLastExplorationSummary(theme, gameService),
        ],
      ),
    );
  }

  Widget _buildSimpleWorldGrid(ThemeData theme, WorldState worldState) {
    // Grille simple 5x5 pour représenter le monde
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withOpacity(0.5),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 25,
        itemBuilder: (context, index) {
          final x = index % 5 - 2; // -2 à 2
          final y = index ~/ 5 - 2; // -2 à 2
          
          final tile = worldState.revealedTiles.firstWhere(
            (t) => t.x == x && t.y == y,
            orElse: () => const MapTile(x: 0, y: 0, type: TileType.terrain),
          );
          
          final isRevealed = worldState.revealedTiles.any((t) => t.x == x && t.y == y);
          final isCenter = x == 0 && y == 0;
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isRevealed 
                ? _getTileColor(theme, tile.type)
                : theme.colorScheme.outline.withOpacity(0.1),
              border: isCenter 
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
            ),
            child: isRevealed 
              ? Icon(
                  _getTileIcon(tile.type),
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                )
              : null,
          );
        },
      ),
    );
  }

  Widget _buildTimeShop(ThemeData theme, TimeFragmentService ftService) {
    final canBuy15min = ftService.currentBalance >= 150;
    final canBuy30min = ftService.currentBalance >= 300;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
      ),
      child: Column(
        children: [
          Text(
            'Acheter du Temps d\'Exploration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildTimePackage(
                  theme,
                  '15 min',
                  '150 FT',
                  canBuy15min,
                  () => _buyExplorationTime(15),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimePackage(
                  theme,
                  '30 min',
                  '300 FT',
                  canBuy30min,
                  () => _buyExplorationTime(30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePackage(
    ThemeData theme,
    String time,
    String cost,
    bool canBuy,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: canBuy ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: canBuy 
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              time,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: canBuy 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            Text(
              cost,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: canBuy 
                  ? theme.colorScheme.onPrimary.withOpacity(0.8)
                  : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastExplorationSummary(ThemeData theme, GameService gameService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernière Exploration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Vous avez découvert des terres mystérieuses et révélé '
            '${gameService.worldState.revealedTiles.length} tuiles. '
            'Continuez à explorer pour débloquer de nouveaux secrets !',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldFooter(ThemeData theme, GameService gameService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _buyExplorationTime(15),
              icon: const Icon(Icons.timer),
              label: const Text('Acheter 15min'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Ouvrir écran de combat si boss débloqué
              },
              icon: const Icon(Icons.gavel),
              label: const Text('Combat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buyExplorationTime(int minutes) async {
    final actualMinutes = await _gameService.buyExplorationTime(minutes);
    
    if (actualMinutes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actualMinutes minutes d\'exploration achetés !'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fragments de Temps insuffisants !'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _getWorldName(int level) {
    switch (level) {
      case 1:
        return 'Plaines Oubliées';
      case 2:
        return 'Forêt Temporelle';
      case 3:
        return 'Ruines Mystiques';
      case 4:
        return 'Pic Éternel';
      default:
        return 'Terres Inconnues';
    }
  }

  Color _getTileColor(ThemeData theme, TileType type) {
    switch (type) {
      case TileType.terrain:
        return theme.colorScheme.surfaceVariant;
      case TileType.forest:
        return Colors.green.withOpacity(0.3);
      case TileType.water:
        return Colors.blue.withOpacity(0.3);
      case TileType.mountain:
        return Colors.grey.withOpacity(0.3);
      case TileType.stele:
        return Colors.purple.withOpacity(0.3);
      case TileType.bridge:
        return Colors.brown.withOpacity(0.3);
      case TileType.relic:
        return Colors.amber.withOpacity(0.3);
      case TileType.bossPortal:
        return Colors.red.withOpacity(0.3);
    }
  }

  IconData _getTileIcon(TileType type) {
    switch (type) {
      case TileType.terrain:
        return Icons.grass;
      case TileType.forest:
        return Icons.forest;
      case TileType.water:
        return Icons.water;
      case TileType.mountain:
        return Icons.terrain;
      case TileType.stele:
        return Icons.account_balance_wallet;
      case TileType.bridge:
        return Icons.account_balance;
      case TileType.relic:
        return Icons.diamond;
      case TileType.bossPortal:
        return Icons.pets;
    }
  }
}
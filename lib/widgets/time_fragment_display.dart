import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/services.dart';

/// Widget d'affichage des Fragments de Temps avec animation
class TimeFragmentDisplay extends StatefulWidget {
  final int currentFT;
  final bool showGainAnimation;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const TimeFragmentDisplay({
    super.key,
    required this.currentFT,
    this.showGainAnimation = false,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<TimeFragmentDisplay> createState() => _TimeFragmentDisplayState();
}

class _TimeFragmentDisplayState extends State<TimeFragmentDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: null,
      end: Colors.amber,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(TimeFragmentDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGainAnimation && !oldWidget.showGainAnimation) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Consumer<TimeFragmentService>(
      builder: (context, ftService, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              // Interface sans bordures selon les préférences utilisateur
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  // Couleurs adaptatives selon le thème
                  isDark 
                    ? theme.colorScheme.surface.withOpacity(0.8)
                    : theme.colorScheme.primaryContainer.withOpacity(0.3),
                  isDark
                    ? theme.colorScheme.surface.withOpacity(0.6)
                    : theme.colorScheme.secondaryContainer.withOpacity(0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colorAnimation.value ?? 
                                 (isDark ? Colors.amber.shade200 : Colors.amber.shade600),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: isDark ? Colors.black87 : Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Fragments de Temps',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '${widget.currentFT} FT',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
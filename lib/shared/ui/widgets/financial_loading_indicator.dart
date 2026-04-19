import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Financial-themed loading indicator with animated coin/bar chart visualization.
class FinancialLoadingIndicator extends StatefulWidget {
  /// Size of the loading indicator.
  final double size;

  /// Color of the loading indicator.
  final Color? color;

  /// Stroke width of the spinner.
  final double strokeWidth;

  const FinancialLoadingIndicator({
    super.key,
    this.size = 48,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  State<FinancialLoadingIndicator> createState() =>
      _FinancialLoadingIndicatorState();
}

class _FinancialLoadingIndicatorState extends State<FinancialLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _bounceController;
  late AnimationController _messageController;
  late Animation<double> _spinAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  int _messageIndex = 0;

  /// Financial-themed status messages in Spanish.
  static const List<String> _messages = [
    'Conectando...',
    'Iniciando servicios...',
    'Cargando datos...',
  ];

  @override
  void initState() {
    super.initState();

    // Spin animation for the ring
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.linear));
    _spinController.repeat();

    // Bounce animation for financial icons
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _bounceController.repeat();

    // Fade animation for message changes
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeInOut),
    );

    // Timer to cycle messages every 3 seconds
    Timer.periodic(const Duration(milliseconds: 3000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _messageController.forward(from: 0);
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _bounceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.color ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Financial animated ring with bouncing elements
        SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinAnimation, _bounceAnimation]),
            builder: (context, child) {
              return CustomPaint(
                painter: _FinancialLoadingPainter(
                  spinProgress: _spinAnimation.value,
                  bounceProgress: _bounceAnimation.value,
                  color: accentColor,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Cycling message with fade transition
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            _messages[_messageIndex],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for financial loading animation.
class _FinancialLoadingPainter extends CustomPainter {
  final double spinProgress;
  final double bounceProgress;
  final Color color;

  _FinancialLoadingPainter({
    required this.spinProgress,
    required this.bounceProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw outer spinning ring
    final ringColor = color.withAlpha((0.3 * 255).round());
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, ringPaint);

    // Draw spinning arc
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * spinProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + sweepAngle,
      1.5,
      false,
      arcPaint,
    );

    // Draw bouncing coin/dot elements
    final dotRadius = 4.0;
    final dotPaint = Paint()..color = color;

    // Four dots that bounce in sequence
    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) + (spinProgress * 2 * math.pi);
      final dotBounce = (bounceProgress + i * 0.25) % 1.0;
      final bounceOffset =
          8 * (1 - dotBounce) * (dotBounce < 0.5 ? 1 : -1) * 0.1;

      final dotCenter = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle) + bounceOffset * 10,
      );

      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialLoadingPainter oldDelegate) {
    return spinProgress != oldDelegate.spinProgress ||
        bounceProgress != oldDelegate.bounceProgress ||
        color != oldDelegate.color;
  }
}

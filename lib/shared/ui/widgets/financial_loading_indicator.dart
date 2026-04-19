import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Beautiful financial-themed loading indicator.
/// Alternates between different visualizations every 4 seconds.
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
  late AnimationController _animController;
  late Animation<double> _animation;
  int _visualIndex = 0;
  int _messageIndex = 0;

  /// Calm, progress-focused messages in Spanish.
  static const List<String> _messages = [
    'Conectando con el servidor...',
    'Verificando seguridad...',
    'Cargando tu información...',
    'Preparando tu espacio...',
    'Casi listo...',
    'Un momento más...',
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.repeat();

    // Change visualization every 4 seconds
    Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _visualIndex = (_visualIndex + 1) % 3;
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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
        // Animated visualization
        SizedBox(
          width: widget.size * 2,
          height: widget.size * 2,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: _FinancialLoadingPainter(
                  animationValue: _animation.value,
                  visualIndex: _visualIndex,
                  primaryColor: accentColor,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Progress message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _messages[_messageIndex],
            key: ValueKey(_messageIndex),
            style: TextStyle(
              fontSize: 14,
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

/// Custom painter that alternates between 3 visualizations.
class _FinancialLoadingPainter extends CustomPainter {
  final double animationValue;
  final int visualIndex;
  final Color primaryColor;
  final bool isDark;

  _FinancialLoadingPainter({
    required this.animationValue,
    required this.visualIndex,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    // Draw background ring
    _drawBackgroundRing(canvas, center, radius);

    // Alternate visualizations
    switch (visualIndex) {
      case 0:
        _drawSpinningArc(canvas, center, radius);
        _drawRisingCoins(canvas, center, radius);
        break;
      case 1:
        _drawSpinningArc(canvas, center, radius);
        _drawBarChart(canvas, center, radius);
        break;
      case 2:
        _drawSpinningArc(canvas, center, radius);
        _drawTrendLine(canvas, center, radius);
        break;
    }
  }

  void _drawBackgroundRing(Canvas canvas, Offset center, double radius) {
    final bgPaint = Paint()
      ..color = primaryColor.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, bgPaint);
  }

  void _drawSpinningArc(Canvas canvas, Offset center, double radius) {
    final arcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * animationValue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + sweepAngle,
      1.5,
      false,
      arcPaint,
    );
  }

  void _drawRisingCoins(Canvas canvas, Offset center, double radius) {
    // Single coin that rises gently
    final coinRadius = 12.0;
    final startY = center.dy + radius * 0.3;
    final endY = center.dy - radius * 0.2;
    final currentY = startY - (animationValue * (startY - endY));

    // Coin circle
    final coinPaint = Paint()
      ..color = AppColors.income
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, currentY), coinRadius, coinPaint);

    // Dollar sign
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '\$',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        currentY - textPainter.height / 2,
      ),
    );

    // Ripple effect at bottom
    if (animationValue > 0.7) {
      final rippleRadius = (animationValue - 0.7) * 30;
      final ripplePaint = Paint()
        ..color = AppColors.income.withAlpha(
          ((1 - animationValue) * 100).round(),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(center.dx, startY), rippleRadius, ripplePaint);
    }
  }

  void _drawBarChart(Canvas canvas, Offset center, double radius) {
    // Small bar chart
    final barWidth = 6.0;
    final barSpacing = 10.0;
    final maxHeight = radius * 0.6;
    final chartBottom = center.dy + radius * 0.3;

    final barValues = [0.3, 0.5, 0.4, 0.7, 0.6, 0.9, 0.75];
    final colors = [
      AppColors.expense,
      AppColors.warning,
      AppColors.income,
      AppColors.savings,
      AppColors.investment,
      AppColors.income,
      AppColors.income,
    ];

    for (int i = 0; i < barValues.length; i++) {
      final x =
          center.dx -
          (barValues.length * barSpacing / 2) +
          i * barSpacing +
          barSpacing / 2;
      final barHeight = maxHeight * barValues[i] * animationValue;
      final color = colors[i];

      // Animate bars growing
      if (animationValue > (i * 0.1)) {
        final barPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        final actualHeight = barHeight.clamp(0.0, maxHeight);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - barWidth / 2,
              chartBottom - actualHeight,
              barWidth,
              actualHeight,
            ),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }
    }
  }

  void _drawTrendLine(Canvas canvas, Offset center, double radius) {
    // Trend line graph
    final linePaint = Paint()
      ..color = AppColors.income
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.2),
      Offset(center.dx - radius * 0.25, center.dy + radius * 0.1),
      Offset(center.dx, center.dy),
      Offset(center.dx + radius * 0.25, center.dy - radius * 0.15),
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.25),
    ];

    // Animate line drawing
    final pointsToDraw = (points.length * animationValue).ceil();

    if (pointsToDraw > 0) {
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < pointsToDraw; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);

      // Dot at the end
      if (pointsToDraw > 0) {
        final dotPaint = Paint()
          ..color = AppColors.income
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(points[pointsToDraw - 1].dx, points[pointsToDraw - 1].dy),
          4,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialLoadingPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        visualIndex != oldDelegate.visualIndex;
  }
}

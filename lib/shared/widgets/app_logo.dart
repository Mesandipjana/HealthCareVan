import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogoMark extends StatelessWidget {
  final double size;
  final bool elevated;

  const AppLogoMark({
    super.key,
    this.size = 40,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.26),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: CustomPaint(
        painter: _AppLogoPainter(),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.width * 0.24);

    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryDark,
          AppColors.primary,
          AppColors.secondary,
        ],
      ).createShader(rect);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bgPaint);

    final routePaint = Paint()
      ..color = AppColors.successLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;
    final route = Path()
      ..moveTo(size.width * 0.22, size.height * 0.74)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.62,
        size.width * 0.48,
        size.height * 0.84,
        size.width * 0.64,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.58,
        size.width * 0.77,
        size.height * 0.48,
        size.width * 0.82,
        size.height * 0.36,
      );
    canvas.drawPath(route, routePaint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.74),
      size.width * 0.055,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.36),
      size.width * 0.055,
      dotPaint,
    );

    final crossPaint = Paint()..color = Colors.white;
    final center = Offset(size.width * 0.5, size.height * 0.38);
    final arm = size.width * 0.11;
    final long = size.width * 0.28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: arm, height: long),
        Radius.circular(size.width * 0.025),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: long, height: arm),
        Radius.circular(size.width * 0.025),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

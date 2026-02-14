import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  final ThemeController themeController;

  const SplashScreen({super.key, required this.themeController});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Dashboard after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardScreen(themeController: widget.themeController),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5), // Brand Indigo
      body: Center(
        // Using your custom animation widget
        child: FlowCtrlLogoAnimation(size: 250),
      ),
    );
  }
}

// === YOUR ANIMATION CODE BELOW ===

class FlowCtrlLogoAnimation extends StatefulWidget {
  final double size;
  
  const FlowCtrlLogoAnimation({
    super.key,
    this.size = 200.0,
  });

  @override
  State<FlowCtrlLogoAnimation> createState() => _FlowCtrlLogoAnimationState();
}

class _FlowCtrlLogoAnimationState extends State<FlowCtrlLogoAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drop1Animation;
  late Animation<double> _drop2Animation;
  late Animation<double> _drop3Animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _drop1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _drop2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeIn),
    ));

    _drop3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: FlowCtrlLogoPainter(
              drop1Progress: _drop1Animation.value,
              drop2Progress: _drop2Animation.value,
              drop3Progress: _drop3Animation.value,
            ),
          );
        },
      ),
    );
  }
}

class FlowCtrlLogoPainter extends CustomPainter {
  final double drop1Progress;
  final double drop2Progress;
  final double drop3Progress;

  FlowCtrlLogoPainter({
    required this.drop1Progress,
    required this.drop2Progress,
    required this.drop3Progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = size.width * 0.015
      ..strokeCap = StrokeCap.round;

    final scale = size.width / 400;
    final centerX = size.width / 2;
    final centerY = size.height / 2 + (size.height * 0.075);
    double s(double value) => value * scale;

    // === UMBRELLA ===
    final umbrellaTopPath = Path();
    umbrellaTopPath.moveTo(centerX, centerY - s(60));
    umbrellaTopPath.lineTo(centerX - s(60), centerY - s(25));
    umbrellaTopPath.lineTo(centerX, centerY - s(25));
    umbrellaTopPath.lineTo(centerX + s(60), centerY - s(25));
    umbrellaTopPath.close();
    canvas.drawPath(umbrellaTopPath, paint);

    final umbrellaCurvePath = Path();
    umbrellaCurvePath.moveTo(centerX - s(60), centerY - s(25));
    umbrellaCurvePath.quadraticBezierTo(centerX - s(50), centerY - s(15), centerX, centerY - s(15));
    umbrellaCurvePath.quadraticBezierTo(centerX + s(50), centerY - s(15), centerX + s(60), centerY - s(25));
    canvas.drawPath(umbrellaCurvePath, paint..color = Colors.white.withOpacity(0.5));
    paint.color = Colors.white;

    // Handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, centerY + s(15)), width: s(6), height: s(60)),
      Radius.circular(s(3)),
    );
    canvas.drawRRect(handleRect, paint);

    final handleCurvePath = Path();
    handleCurvePath.moveTo(centerX, centerY + s(45));
    handleCurvePath.quadraticBezierTo(centerX, centerY + s(52), centerX + s(8), centerY + s(55));
    canvas.drawPath(handleCurvePath, strokePaint);

    // === DROPS ===
    _drawDrop(canvas, paint, centerX - s(33), centerY - s(115), centerY - s(60), drop1Progress, s);
    _drawDrop(canvas, paint, centerX, centerY - s(115), centerY - s(60), drop2Progress, s);
    _drawDrop(canvas, paint, centerX + s(27), centerY - s(115), centerY - s(60), drop3Progress, s);
  }

  void _drawDrop(Canvas canvas, Paint paint, double x, double startY, double endY, double progress, Function s) {
    final y = startY + (endY - startY) * progress;
    final opacity = progress < 0.9 ? 0.7 : (1.0 - progress) * 7;
    if (opacity > 0) {
      // Ensure opacity stays within bounds 0.0-1.0
      final safeOpacity = opacity.clamp(0.0, 1.0);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: s(6).toDouble(), height: (s(30) * (1 - progress * 0.3)).toDouble()),
        Radius.circular(s(3).toDouble()),
      );
      canvas.drawRRect(rect, paint..color = Colors.white.withOpacity(safeOpacity));
    }
  }

  @override
  bool shouldRepaint(FlowCtrlLogoPainter oldDelegate) {
    return oldDelegate.drop1Progress != drop1Progress ||
        oldDelegate.drop2Progress != drop2Progress ||
        oldDelegate.drop3Progress != drop3Progress;
  }
}

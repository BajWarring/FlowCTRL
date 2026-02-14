import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'main.dart'; // To access ThemeController

class SplashScreen extends StatefulWidget {
  final ThemeController themeController;

  const SplashScreen({super.key, required this.themeController});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1. Setup Animation: Duration 1.5s repeating
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 2. Setup Navigation: Go to Dashboard after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(themeController: widget.themeController),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5), // Deep Indigo
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: CustomPaint(
            painter: UmbrellaPainter(animation: _controller),
          ),
        ),
      ),
    );
  }
}

// === YOUR CUSTOM PAINTER ===
class UmbrellaPainter extends CustomPainter {
  final Animation<double> animation;

  UmbrellaPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Translate to center + 15 offset as per SVG logic
    canvas.translate(size.width / 2, size.height / 2 + 15);

    final Paint whitePaint = Paint()..color = Colors.white;
    final Paint whiteOpacityPaint = Paint()..color = Colors.white.withOpacity(0.5);
    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6;

    // --- 1. HANDLE ---
    // Vertical part
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -15, 6, 60),
        const Radius.circular(3),
      ),
      whitePaint,
    );

    // Curved hook
    Path handleCurve = Path();
    handleCurve.moveTo(0, 45);
    handleCurve.cubicTo(0, 52, 3, 55, 8, 55);
    canvas.drawPath(handleCurve, strokePaint);

    // --- 2. RAIN DROPS (Behind Umbrella Top) ---
    // Staggered drops
    _drawDrop(canvas, offsetX: -33, startHeight: 30, cycleOffset: 0.0);
    _drawDrop(canvas, offsetX: -3, startHeight: 35, cycleOffset: 0.33);
    _drawDrop(canvas, offsetX: 27, startHeight: 30, cycleOffset: 0.66);

    // --- 3. UMBRELLA TOP (Front) ---
    // Triangle
    Path umbrellaTop = Path();
    umbrellaTop.moveTo(0, -60);
    umbrellaTop.lineTo(-60, -25);
    umbrellaTop.lineTo(0, -25);
    umbrellaTop.lineTo(60, -25);
    umbrellaTop.close();
    canvas.drawPath(umbrellaTop, whitePaint);

    // Bottom Curve
    Path umbrellaBottomCurve = Path();
    umbrellaBottomCurve.moveTo(-60, -25);
    umbrellaBottomCurve.cubicTo(-60, -25, -50, -15, 0, -15);
    umbrellaBottomCurve.cubicTo(50, -15, 60, -25, 60, -25);
    canvas.drawPath(umbrellaBottomCurve, whiteOpacityPaint);
  }

  void _drawDrop(Canvas canvas, {required double offsetX, required double startHeight, required double cycleOffset}) {
    double progress = (animation.value + cycleOffset) % 1.0;

    const double startY = -140.0;
    const double surfaceY = -75.0; 
    const double deepY = -40.0;    

    double currentY;
    double currentHeight;
    double opacity;

    if (progress < 0.6) {
      // Falling
      double t = progress / 0.6; 
      currentY = _lerp(startY, surfaceY, t);
      currentHeight = startHeight;
      opacity = _lerp(0.0, 1.0, math.min(t * 4, 1.0)); 
    } else {
      // Hitting/Shrinking
      double t = (progress - 0.6) / 0.4; 
      currentY = _lerp(surfaceY, deepY, t);
      currentHeight = _lerp(startHeight, 0, t);
      opacity = t > 0.9 ? 0.0 : 1.0; 
    }

    if (opacity > 0 && currentHeight > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(offsetX, currentY, 6, currentHeight),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withOpacity(opacity * 0.7),
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant UmbrellaPainter oldDelegate) => true;
}

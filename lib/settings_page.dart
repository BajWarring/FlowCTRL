import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // Import to access ThemeController

class SettingsPage extends StatefulWidget {
  final ThemeController themeController;

  const SettingsPage({super.key, required this.themeController});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  // --- Tailwind Colors (HTML Match) ---
  final Color kIndigo50 = const Color(0xFFEEF2FF);
  final Color kIndigo400 = const Color(0xFF818CF8);
  final Color kIndigo500 = const Color(0xFF6366F1);
  final Color kIndigo600 = const Color(0xFF4F46E5);
  final Color kSlate950 = const Color(0xFF020617);
  final Color kSlate900 = const Color(0xFF0F172A);
  final Color kSlate800 = const Color(0xFF1E293B);
  final Color kGray50 = const Color(0xFFF9FAFB);
  final Color kBlue50 = const Color(0xFFEFF6FF);
  final Color kBlue400 = const Color(0xFF60A5FA); // Added Blue 400
  final Color kBlue600 = const Color(0xFF2563EB);
  final Color kEmerald50 = const Color(0xFFECFDF5);
  final Color kEmerald400 = const Color(0xFF34D399); // Added Emerald 400
  final Color kEmerald500 = const Color(0xFF10B981); // Added Emerald 500
  final Color kEmerald600 = const Color(0xFF059669);

  // Native Platform Channel
  static const platform = MethodChannel('com.sage.flowctrl/settings');
  
  // Animation
  late AnimationController _navController;
  late Animation<Offset> _mainScreenOffset;
  late Animation<double> _mainScreenScale;
  late Animation<Offset> _detailScreenOffset;
  
  bool _tileEnabled = true;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _mainScreenOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0))
        .animate(CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic));
    
    _mainScreenScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic));

    _detailScreenOffset = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic));

    _checkTileStatus();
  }

  Future<void> _checkTileStatus() async {
    try {
      final bool result = await platform.invokeMethod('isTileEnabled');
      if (mounted) setState(() => _tileEnabled = result);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleTile(bool enable) async {
    try {
      await platform.invokeMethod('setTileEnabled', {'enabled': enable});
      setState(() => _tileEnabled = enable);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _openDetail() => _navController.forward();
  void _closeDetail() => _navController.reverse();

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme controller for live updates
    return ValueListenableBuilder<bool>(
      valueListenable: widget.themeController,
      builder: (context, isDark, child) {
        final bgColor = isDark ? kSlate950 : kGray50;
        final cardColor = isDark ? kSlate900 : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final borderColor = isDark ? kSlate800 : Colors.grey[200]!;

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Screen 1: Main Settings
              SlideTransition(
                position: _mainScreenOffset,
                child: ScaleTransition(
                  scale: _mainScreenScale,
                  child: AnimatedBuilder(
                    animation: _navController,
                    builder: (context, child) {
                      return ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(_navController.value * 0.5),
                          BlendMode.darken,
                        ),
                        child: child,
                      );
                    },
                    child: _buildMainScreen(isDark, cardColor, textColor, borderColor),
                  ),
                ),
              ),

              // Screen 2: Detail
              SlideTransition(
                position: _detailScreenOffset,
                child: _buildDetailScreen(isDark, cardColor, textColor, borderColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainScreen(bool isDark, Color cardColor, Color textColor, Color borderColor) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by parent
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: (isDark ? kSlate950 : kGray50).withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _sectionTitle("Appearance", isDark),
          _card(isDark, cardColor, borderColor, [
            _tile(
              isDark, textColor,
              icon: Icons.dark_mode_outlined,
              iconColor: kIndigo600,
              iconBg: isDark ? kIndigo600.withOpacity(0.1) : kIndigo50,
              title: "Dark Theme",
              trailing: Switch.adaptive(
                value: widget.themeController.value,
                activeColor: kIndigo600,
                onChanged: (val) => widget.themeController.toggle(),
              ),
            )
          ]),
          
          const SizedBox(height: 24),

          _sectionTitle("General", isDark),
          _card(isDark, cardColor, borderColor, [
            _tile(
              isDark, textColor,
              onTap: _openDetail,
              icon: Icons.dashboard_customize_outlined,
              // FIX: Use kBlue400 instead of Colors.blue.shade400
              iconColor: isDark ? kBlue400 : kBlue600,
              iconBg: isDark ? kBlue400.withOpacity(0.1) : kBlue50,
              title: "Quick Settings Button",
              subtitle: "Custom tile for control panel",
              trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
            ),
            Divider(height: 1, color: borderColor),
            _tile(
              isDark, textColor,
              icon: Icons.apps_outlined,
              // FIX: Use kEmerald400 instead of Colors.emerald.shade400
              iconColor: isDark ? kEmerald400 : kEmerald600,
              // FIX: Use kEmerald500 instead of Colors.emerald
              iconBg: isDark ? kEmerald500.withOpacity(0.1) : kEmerald50,
              title: "Blocked Apps",
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? kSlate800 : Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                    child: Text("2 Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 40),
          Center(child: Text("FlowCTRL v1.0", style: TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildDetailScreen(bool isDark, Color cardColor, Color textColor, Color borderColor) {
    return Scaffold(
      backgroundColor: cardColor, // Full background
      appBar: AppBar(
        title: Text("Quick Settings Tile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: _closeDetail,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? kSlate900 : kGray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Show Tile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 4),
                  Text("Enable FlowCTRL in system panel", style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
                Switch.adaptive(value: _tileEnabled, activeColor: kIndigo600, onChanged: _toggleTile),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Illustration (Centered)
          Center(
            child: SizedBox(
              width: 340, 
              height: 460,
              child: Stack(
                children: [
                  CustomPaint(size: const Size(340, 460), painter: OneUIPainter(isDark: isDark, indigo: kIndigo600)),
                  Positioned(top: 180, right: 80, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: kIndigo600, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: kIndigo600.withOpacity(0.4), blurRadius: 10)]), child: const Text("Added!", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))))
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text("Quick Settings Tile Setup Guide", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          _step(1, "Swipe down twice to open full Quick Panel.", isDark),
          _step(2, "Tap the 3 dots (top right) or Pencil icon.", isDark),
          _step(3, "Tap Edit buttons.", isDark),
          _step(4, "Drag FlowCTRL from the list to your active buttons.", isDark, highlight: true),
        ],
      ),
    );
  }

  // --- Helpers ---
  Widget _sectionTitle(String title, bool isDark) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)));
  
  Widget _card(bool isDark, Color bg, Color border, List<Widget> children) => Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: Column(children: children));

  Widget _tile(bool isDark, Color textColor, {required IconData icon, required Color iconColor, required Color iconBg, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)) : null,
      trailing: trailing,
    );
  }

  Widget _step(int n, String text, bool isDark, {bool highlight = false}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("$n. ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), Expanded(child: highlight ? RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Inter'), children: [const TextSpan(text: "Drag "), TextSpan(text: "FlowCTRL", style: TextStyle(color: kIndigo600, fontWeight: FontWeight.bold)), const TextSpan(text: " from the list.")])) : Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14)))]));
}

// --- Custom Painter for OneUI Illustration ---
class OneUIPainter extends CustomPainter {
  final bool isDark;
  final Color indigo;

  OneUIPainter({required this.isDark, required this.indigo});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2);
    final ghostPaint = Paint()..color = isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB);
    final btnPaint = Paint()..color = isDark ? const Color(0xFF383838) : Colors.white;

    // Panel Background
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)), bgPaint);

    // Top Bar
    _drawText(canvas, "15:50", 25, 45, 20, FontWeight.w600, isDark ? Colors.white : Colors.black);
    _drawText(canvas, "Sun, May 23", 25, 65, 12, FontWeight.normal, Colors.grey);
    
    // Ghost Icons Top Right
    canvas.drawCircle(const Offset(250, 40), 10, ghostPaint);
    canvas.drawCircle(const Offset(280, 40), 10, ghostPaint);
    canvas.drawCircle(const Offset(310, 40), 10, ghostPaint);

    // Buttons
    final btnRect1 = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 85, 145, 40), const Radius.circular(20));
    final btnRect2 = RRect.fromRectAndRadius(const Rect.fromLTWH(175, 85, 145, 40), const Radius.circular(20));
    canvas.drawRRect(btnRect1, btnPaint);
    canvas.drawRRect(btnRect2, btnPaint);
    
    // Button content
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 98, 14, 14), const Radius.circular(3)), ghostPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(183, 98, 14, 14), const Radius.circular(3)), ghostPaint);
    _drawText(canvas, "Device Control", 50, 110, 11, FontWeight.w600, isDark ? Colors.white : Colors.black);
    _drawText(canvas, "Media Output", 205, 110, 11, FontWeight.w600, isDark ? Colors.white : Colors.black);

    // Grid Logic
    double startY = 172; 
    double startX = 42;
    double gapX = 75;
    double gapY = 75;

    // Row 1
    for(int i=0; i<4; i++) canvas.drawCircle(Offset(startX + (i*gapX), startY), 24, ghostPaint);
    
    // Row 2
    canvas.drawCircle(Offset(startX, startY + gapY), 24, ghostPaint);
    
    // ACTIVE TILE (FlowCTRL)
    final activeCenter = Offset(startX + gapX, startY + gapY);
    canvas.drawCircle(activeCenter, 28, Paint()..color = indigo.withOpacity(0.3));
    canvas.drawCircle(activeCenter, 24, Paint()..color = indigo);
    
    // Umbrella Icon
    final umbPath = Path();
    umbPath.moveTo(activeCenter.dx - 7, activeCenter.dy - 2); 
    umbPath.quadraticBezierTo(activeCenter.dx, activeCenter.dy - 8, activeCenter.dx + 7, activeCenter.dy - 2); 
    umbPath.moveTo(activeCenter.dx, activeCenter.dy - 2); 
    umbPath.lineTo(activeCenter.dx, activeCenter.dy + 5); 
    umbPath.quadraticBezierTo(activeCenter.dx, activeCenter.dy + 8, activeCenter.dx + 3, activeCenter.dy + 7); 
    
    canvas.drawPath(umbPath, Paint()..color = Colors.white ..style = PaintingStyle.stroke ..strokeWidth = 2);

    // Rest of Row 2
    canvas.drawCircle(Offset(startX + (2*gapX), startY + gapY), 24, ghostPaint);
    canvas.drawCircle(Offset(startX + (3*gapX), startY + gapY), 24, ghostPaint);

    // Row 3
    for(int i=0; i<4; i++) canvas.drawCircle(Offset(startX + (i*gapX), startY + (2*gapY)), 24, ghostPaint);

    // Slider
    final sliderRect = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 380, 300, 46), const Radius.circular(23));
    canvas.drawRRect(sliderRect, Paint()..color = isDark ? const Color(0xFF444444) : const Color(0xFFDCDCDC));
    canvas.drawCircle(const Offset(46, 403), 10, ghostPaint);
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, FontWeight weight, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

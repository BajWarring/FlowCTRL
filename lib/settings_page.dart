import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const SettingsPage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  // --- Constants (Tailwind Colors) ---
  final Color kSlate950 = const Color(0xFF020617);
  final Color kSlate900 = const Color(0xFF0F172A);
  final Color kSlate800 = const Color(0xFF1E293B);
  final Color kIndigo600 = const Color(0xFF4F46E5);
  final Color kGray50 = const Color(0xFFF9FAFB);

  // --- Logic ---
  static const platform = MethodChannel('com.sage.flowctrl/settings');
  late AnimationController _navController;
  late Animation<Offset> _mainScreenOffset;
  late Animation<double> _mainScreenScale;
  late Animation<Offset> _detailScreenOffset;
  
  bool _tileEnabled = true;

  @override
  void initState() {
    super.initState();
    // Animation setup for the "Push" transition
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _mainScreenOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0))
        .animate(CurvedAnimation(parent: _navController, curve: Curves.easeOutCubic));
    
    _mainScreenScale = Tween<double>(begin: 1.0, end: 0.95) // Slight scale down effect
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
      debugPrint("Error checking tile: $e");
    }
  }

  Future<void> _toggleTile(bool enable) async {
    try {
      await platform.invokeMethod('setTileEnabled', {'enabled': enable});
      setState(() => _tileEnabled = enable);
    } catch (e) {
      debugPrint("Error toggling tile: $e");
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
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? kSlate950 : kGray50;
    final cardColor = isDark ? kSlate900 : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? kSlate800 : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // === SCREEN 1: MAIN SETTINGS ===
          SlideTransition(
            position: _mainScreenOffset,
            child: ScaleTransition(
              scale: _mainScreenScale, // Optional subtle depth effect
              child: AnimatedBuilder(
                animation: _navController,
                builder: (context, child) {
                  return ColorFiltered(
                    // Dim the background when detail opens
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(_navController.value * 0.5),
                      BlendMode.darken,
                    ),
                    child: child,
                  );
                },
                child: _buildMainContent(isDark, cardColor, textColor, borderColor),
              ),
            ),
          ),

          // === SCREEN 2: DETAIL PAGE ===
          SlideTransition(
            position: _detailScreenOffset,
            child: _buildDetailContent(isDark, cardColor, textColor, borderColor),
          ),
        ],
      ),
    );
  }

  // --- BUILDERS ---

  Widget _buildMainContent(bool isDark, Color cardColor, Color textColor, Color borderColor) {
    return Scaffold(
      backgroundColor: isDark ? kSlate950 : kGray50,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: (isDark ? kSlate950 : kGray50).withOpacity(0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader("Appearance", isDark),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: _buildIconBox(Icons.dark_mode_outlined, Colors.indigo, isDark),
              title: Text("Dark Theme", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
              trailing: Switch.adaptive(
                value: widget.isDarkMode,
                activeColor: kIndigo600,
                onChanged: (val) => widget.onThemeToggle(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSectionHeader("General", isDark),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
            ),
            child: Column(
              children: [
                ListTile(
                  onTap: _openDetail,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildIconBox(Icons.dashboard_customize_outlined, Colors.blue, isDark),
                  title: Text("Quick Settings Button", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                  subtitle: Text("Custom tile for control panel", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13)),
                  trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _buildIconBox(Icons.apps_outlined, Colors.emerald, isDark),
                  title: Text("Blocked Apps", style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? kSlate800 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("2 Active", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          Center(child: Text("FlowCTRL v1.0", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[600] : Colors.grey[400]))),
        ],
      ),
    );
  }

  Widget _buildDetailContent(bool isDark, Color cardColor, Color textColor, Color borderColor) {
    return Scaffold(
      backgroundColor: cardColor, // Detail page is usually fuller background
      appBar: AppBar(
        title: Text("Quick Settings Tile", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: cardColor.withOpacity(0.9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: _closeDetail,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Toggle Card
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Show Tile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 4),
                    Text("Enable FlowCTRL in system panel", style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[500])),
                  ],
                ),
                Switch.adaptive(
                  value: _tileEnabled,
                  activeColor: kIndigo600,
                  onChanged: _toggleTile,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // THE ILLUSTRATION (Custom Painter to match SVG)
          Center(
            child: SizedBox(
              width: 340,
              height: 460,
              child: Stack(
                children: [
                  // The actual illustration drawn with code
                  CustomPaint(
                    size: const Size(340, 460),
                    painter: OneUIPainter(isDark: isDark, indigo: kIndigo600),
                  ),
                  
                  // "Added!" Badge
                  Positioned(
                    top: 180, // Approximate position from SVG
                    right: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kIndigo600,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: kIndigo600.withOpacity(0.4), blurRadius: 10)],
                      ),
                      child: const Text("Added!", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Instructions
          Text("Quick Settings Tile Setup Guide", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 12),
          _buildStep(1, "Swipe down twice to open full Quick Panel.", isDark),
          _buildStep(2, "Tap the 3 dots (top right) or Pencil icon.", isDark),
          _buildStep(3, "Tap Edit buttons.", isDark),
          _buildStep(4, "Drag FlowCTRL from the list to your active buttons.", isDark, highlight: true),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          letterSpacing: 1.2,
          color: isDark ? Colors.grey[400] : Colors.grey[500]
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.1 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: isDark ? color.withOpacity(0.8) : color, size: 20),
    );
  }

  Widget _buildStep(int num, String text, bool isDark, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$num. ", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.bold)),
          Expanded(
            child: highlight 
              ? RichText(text: TextSpan(
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14, fontFamily: 'Inter'),
                  children: [
                    const TextSpan(text: "Drag "),
                    TextSpan(text: "FlowCTRL", style: TextStyle(color: kIndigo600, fontWeight: FontWeight.bold)),
                    const TextSpan(text: " from the list to your active buttons."),
                  ]
                ))
              : Text(text, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painter to Replicate the HTML SVG Exactly ---
class OneUIPainter extends CustomPainter {
  final bool isDark;
  final Color indigo;

  OneUIPainter({required this.isDark, required this.indigo});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2);
    final ghostPaint = Paint()..color = isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB);
    final btnPaint = Paint()..color = isDark ? const Color(0xFF383838) : Colors.white;
    final textPaint = TextPainter(textDirection: TextDirection.ltr);

    // 1. Panel Background
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
    canvas.drawRRect(rrect, bgPaint);

    // 2. Top Bar (Clock)
    _drawText(canvas, "15:50", 25, 45, 20, FontWeight.w600, isDark ? Colors.white : Colors.black);
    _drawText(canvas, "Sun, May 23", 25, 65, 12, FontWeight.normal, Colors.grey);

    // 3. Top Right Ghosts
    canvas.drawCircle(const Offset(250, 40), 10, ghostPaint);
    canvas.drawCircle(const Offset(280, 40), 10, ghostPaint);
    canvas.drawCircle(const Offset(310, 40), 10, ghostPaint);

    // 4. Device/Media Buttons
    final btnRect1 = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 85, 145, 40), const Radius.circular(20));
    final btnRect2 = RRect.fromRectAndRadius(const Rect.fromLTWH(175, 85, 145, 40), const Radius.circular(20));
    canvas.drawRRect(btnRect1, btnPaint);
    canvas.drawRRect(btnRect2, btnPaint);
    
    // Icons inside buttons
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 98, 14, 14), const Radius.circular(3)), ghostPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(183, 98, 14, 14), const Radius.circular(3)), ghostPaint);
    
    // Text inside buttons
    _drawText(canvas, "Device Control", 50, 110, 11, FontWeight.w600, isDark ? Colors.white : Colors.black);
    _drawText(canvas, "Media Output", 205, 110, 11, FontWeight.w600, isDark ? Colors.white : Colors.black);

    // 5. Grid Logic
    double startY = 172; // Adjusted for padding
    double startX = 42;
    double gapX = 75;
    double gapY = 75;

    // Row 1
    for(int i=0; i<4; i++) canvas.drawCircle(Offset(startX + (i*gapX), startY), 24, ghostPaint);
    
    // Row 2
    canvas.drawCircle(Offset(startX, startY + gapY), 24, ghostPaint);
    
    // THE ACTIVE TILE (FlowCTRL)
    final activeCenter = Offset(startX + gapX, startY + gapY);
    // Glow
    canvas.drawCircle(activeCenter, 28, Paint()..color = indigo.withOpacity(0.3));
    // Solid Circle
    canvas.drawCircle(activeCenter, 24, Paint()..color = indigo);
    // Draw Umbrella (Simplified Path)
    final umbPath = Path();
    umbPath.moveTo(activeCenter.dx - 7, activeCenter.dy - 2); // Left arch
    umbPath.quadraticBezierTo(activeCenter.dx, activeCenter.dy - 8, activeCenter.dx + 7, activeCenter.dy - 2); // Arch
    umbPath.moveTo(activeCenter.dx, activeCenter.dy - 2); 
    umbPath.lineTo(activeCenter.dx, activeCenter.dy + 5); // Handle vertical
    umbPath.quadraticBezierTo(activeCenter.dx, activeCenter.dy + 8, activeCenter.dx + 3, activeCenter.dy + 7); // Handle Hook
    
    canvas.drawPath(umbPath, Paint()..color = Colors.white ..style = PaintingStyle.stroke ..strokeWidth = 2);

    // Rest of Row 2
    canvas.drawCircle(Offset(startX + (2*gapX), startY + gapY), 24, ghostPaint);
    canvas.drawCircle(Offset(startX + (3*gapX), startY + gapY), 24, ghostPaint);

    // Row 3
    for(int i=0; i<4; i++) canvas.drawCircle(Offset(startX + (i*gapX), startY + (2*gapY)), 24, ghostPaint);

    // 6. Brightness Slider
    final sliderRect = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 380, 300, 46), const Radius.circular(23));
    canvas.drawRRect(sliderRect, Paint()..color = isDark ? const Color(0xFF444444) : const Color(0xFFDCDCDC));
    canvas.drawCircle(const Offset(46, 403), 10, ghostPaint);

    // 7. Arrow dashed line (Simplified)
    // We skip the complex dashed path drawing for simplicity, the "Added" badge serves the purpose.
  }

  void _drawText(Canvas canvas, String text, double x, double y, double size, FontWeight weight, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Inter')),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height)); // Y is baseline roughly
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

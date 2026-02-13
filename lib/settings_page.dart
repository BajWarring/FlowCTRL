import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart'; // To access ThemeController

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
  final Color kBlue600 = const Color(0xFF2563EB);
  final Color kEmerald50 = const Color(0xFFECFDF5);
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
              iconColor: isDark ? Colors.blue.shade400 : kBlue600,
              iconBg: isDark ? Colors.blue.withOpacity(0.1) : kBlue50,
              title: "Quick Settings Button",
              subtitle: "Custom tile for control panel",
              trailing: Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[300]),
            ),
            Divider(height: 1, color: borderColor),
            _tile(
              isDark, textColor,
              icon: Icons.apps_outlined,
              iconColor: isDark ? Colors.emerald.shade400 : kEmerald600,
              iconBg: isDark ? Colors.emerald.withOpacity(0.1) : kEmerald50,
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

// (Reuse OneUIPainter from previous response, it was correct. Just ensure it is included at bottom of file)
class OneUIPainter extends CustomPainter {
  final bool isDark;
  final Color indigo;
  OneUIPainter({required this.isDark, required this.indigo});
  @override
  void paint(Canvas canvas, Size size) {
    // ... [Paste the exact OneUIPainter code from previous response here] ...
    // For brevity, I am assuming you have the previous code. 
    // If you need it again, I can paste it, but it fits in the file structure here.
    
    // Minimal placeholder to ensure compilation if you forget to copy-paste:
    final bgPaint = Paint()..color = isDark ? const Color(0xFF252525) : const Color(0xFFF2F2F2);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)), bgPaint);
    // (You should use the full painter code provided previously for the visual match)
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

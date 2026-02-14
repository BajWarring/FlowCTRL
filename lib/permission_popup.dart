import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

class PermissionPopup extends StatefulWidget {
  final VoidCallback onDismiss; // To skip check manually

  const PermissionPopup({super.key, required this.onDismiss});

  @override
  State<PermissionPopup> createState() => _PermissionPopupState();
}

class _PermissionPopupState extends State<PermissionPopup> {
  bool _showInstructions = false;

  void _toggleView() {
    setState(() {
      _showInstructions = !_showInstructions;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We assume parent provides the dark mode context via Theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: MediaQuery.of(context).size.width * 0.9,
          height: _showInstructions ? 550 : 380, // Dynamic height
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showInstructions
                  ? InstructionView(onBack: _toggleView, onOpenSettings: _openSettings)
                  : RequestView(onInstructionsTap: _toggleView, onAllowTap: _openSettings, onSkip: widget.onDismiss),
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings() async {
    await FlutterAccessibilityService.requestAccessibilityPermission();
  }
}

// === VIEW 1: REQUEST ===
class RequestView extends StatelessWidget {
  final VoidCallback onInstructionsTap;
  final VoidCallback onAllowTap;
  final VoidCallback onSkip;

  const RequestView({super.key, required this.onInstructionsTap, required this.onAllowTap, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF312E81).withOpacity(0.3) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              size: 32,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 24),
          Text("Permission Required", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A), fontFamily: 'Inter'), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text("FlowCTRL needs accessibility permission to detect when you open distracting apps.", style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5, fontFamily: 'Inter'), textAlign: TextAlign.center),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAllowTap,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
              child: const Text("Allow Permission", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onInstructionsTap,
            child: Text("See Instructions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5))),
          ),
          // Hidden option for manual override
          GestureDetector(
             onTap: onSkip,
             child: Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text("Skip Check (Dev)", style: TextStyle(fontSize: 10, color: Colors.grey.withOpacity(0.5))),
             ),
          )
        ],
      ),
    );
  }
}

// === VIEW 2: INSTRUCTIONS ===
class InstructionView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;

  const InstructionView({super.key, required this.onBack, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgContent = isDark ? Colors.black : const Color(0xFFF2F2F2);
    final headerBg = isDark ? const Color(0xFF121212) : Colors.white;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(color: headerBg, border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)))),
          child: Row(children: [
            InkWell(onTap: onBack, borderRadius: BorderRadius.circular(20), child: Padding(padding: const EdgeInsets.all(4.0), child: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black))),
            const SizedBox(width: 16),
            Text("How to Enable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontFamily: 'Inter')),
          ]),
        ),
        Expanded(
          child: Container(
            color: bgContent,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _step(context, 1, "Tap ", "Accessibility", const SamsungRowVisual(icon: Icons.accessibility_new, iconColor: Colors.white, iconBg: Color(0xFF00BFA5), title: "Accessibility", showChevron: true)),
                const SizedBox(height: 24),
                _step(context, 2, "Tap ", "Installed apps", const SamsungRowVisual(title: "Installed apps", subtext: "3 services", showChevron: true, noIcon: true)),
                const SizedBox(height: 24),
                // STEP 3: CUSTOM APP ICON
                _step(context, 3, "Select ", "FlowCTRL", SamsungRowVisual(
                  customIcon: const FlowCtrlSmallIcon(), // <--- USING YOUR CUSTOM ICON HERE
                  iconBg: const Color(0xFF4F46E5),
                  title: "FlowCTRL",
                  subtext: "Off",
                  showChevron: true,
                )),
                const SizedBox(height: 24),
                _step(context, 4, "Turn Toggle ", "ON", const SamsungRowVisual(title: "Off", noIcon: true, customTrailing: AnimatedToggle())),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: headerBg, border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)))),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenSettings,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
              child: const Text("Open Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _step(BuildContext context, int step, String text, String highlight, Widget visual) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 24, height: 24, alignment: Alignment.center, decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], shape: BoxShape.circle), child: Text(step.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
        const SizedBox(width: 12),
        RichText(text: TextSpan(style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black, fontFamily: 'Inter'), children: [TextSpan(text: text), TextSpan(text: highlight, style: const TextStyle(color: Color(0xFF6366F1)))]))
      ]),
      const SizedBox(height: 12),
      Container(width: double.infinity, decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]), child: visual),
    ]);
  }
}

class SamsungRowVisual extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color? iconBg;
  final Color? iconColor;
  final String title;
  final String? subtext;
  final bool showChevron;
  final bool noIcon;
  final Widget? customTrailing;

  const SamsungRowVisual({super.key, this.icon, this.customIcon, this.iconBg, this.iconColor, required this.title, this.subtext, this.showChevron = false, this.noIcon = false, this.customTrailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        if (!noIcon) ...[
          Container(
            width: 36, height: 36, 
            decoration: BoxDecoration(color: iconBg ?? Colors.blue, borderRadius: BorderRadius.circular(10)),
            child: customIcon ?? Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)), if (subtext != null) Text(subtext!, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]))])),
        if (customTrailing != null) customTrailing! else if (showChevron) Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
      ]),
    );
  }
}

// === CUSTOM PAINTER FOR APP ICON IN INSTRUCTIONS ===
class FlowCtrlSmallIcon extends StatelessWidget {
  const FlowCtrlSmallIcon({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: SmallIconPainter());
  }
}

class SmallIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // A simplified version of your ic_launcher_foreground geometry
    // fit into 36x36 box
    final paint = Paint()..color = Colors.white;
    // Scale everything to fit 36x36
    final center = Offset(size.width/2, size.height/2);
    
    // Draw Umbrella Top
    final p = Path();
    p.moveTo(center.dx, center.dy - 10);
    p.lineTo(center.dx - 10, center.dy - 4);
    p.lineTo(center.dx + 10, center.dy - 4);
    p.close();
    canvas.drawPath(p, paint);
    
    // Handle
    canvas.drawRect(Rect.fromCenter(center: Offset(center.dx, center.dy+2), width: 2, height: 10), paint);
    
    // Hook
    final hook = Path();
    hook.moveTo(center.dx, center.dy+7);
    hook.quadraticBezierTo(center.dx, center.dy+10, center.dx+3, center.dy+10);
    canvas.drawPath(hook, Paint()..color = Colors.white ..style = PaintingStyle.stroke ..strokeWidth = 2);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedToggle extends StatefulWidget {
  const AnimatedToggle({super.key});
  @override
  State<AnimatedToggle> createState() => _AnimatedToggleState();
}

class _AnimatedToggleState extends State<AnimatedToggle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _colorAnimation = ColorTween(begin: const Color(0xFFE0E0E0), end: const Color(0xFF4F46E5)).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)));
    _slideAnimation = Tween<double>(begin: 2, end: 24).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeInOut)));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Container(width: 50, height: 28, decoration: BoxDecoration(color: _colorAnimation.value, borderRadius: BorderRadius.circular(14)), child: Stack(alignment: Alignment.centerLeft, children: [Positioned(left: _slideAnimation.value, child: Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)])))]))
    );
  }
}

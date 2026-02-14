import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'main.dart';
import 'settings_page.dart';
import 'permission_popup.dart'; 

class DashboardScreen extends StatefulWidget {
  final ThemeController themeController;

  const DashboardScreen({super.key, required this.themeController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isServiceEnabled = false; 
  bool _isBlockingEnabled = true; 
  bool _isYouTubeBlocked = true; 
  bool _isInstagramBlocked = true;

  Timer? _monitorTimer;
  late AnimationController _spinController;

  // Colors
  final Color kIndigo = const Color(0xFF4F46E5);
  final Color kIndigoLight = const Color(0xFF818CF8);
  final Color kSlate950 = const Color(0xFF020617);
  final Color kSlate900 = const Color(0xFF0F172A);
  final Color kSlate800 = const Color(0xFF1E293B);
  final Color kGray900 = const Color(0xFF111827);
  final Color kGray400 = const Color(0xFF9CA3AF);
  final Color kBgLight = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); 
    _loadState();
    _startPermissionMonitor();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitorTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // FIX: Add small delay to prevent crash when returning from Settings
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkPermissionNow();
      });
    }
  }

  void _startPermissionMonitor() {
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkPermissionNow();
    });
  }

  Future<void> _checkPermissionNow() async {
    try {
      // FIX: Wrapped in try-catch to handle plugin instability
      bool osPermission = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      final prefs = await SharedPreferences.getInstance();
      bool serviceRunning = prefs.getBool('service_active') ?? false;
      bool actuallyEnabled = osPermission || serviceRunning;

      if (actuallyEnabled != _isServiceEnabled) {
        if (mounted) setState(() => _isServiceEnabled = actuallyEnabled);
      }
    } catch (e) {
      debugPrint("Permission Check Error: $e");
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBlockingEnabled = prefs.getBool('isBlockingEnabled') ?? true;
      _isYouTubeBlocked = prefs.getBool('isYouTubeBlocked') ?? true;
      _isInstagramBlocked = prefs.getBool('isInstagramBlocked') ?? true;
    });
    // Run sync logic once on load
    _syncMasterState(); 
    _checkPermissionNow();
  }

  // --- LOGIC: MASTER BUTTON SYNC ---
  void _syncMasterState() {
    // If BOTH apps are off, Master should be OFF.
    if (!_isYouTubeBlocked && !_isInstagramBlocked) {
      if (_isBlockingEnabled) _toggleMaster(false);
    }
    // If ANY app is ON, Master should be ON (if it was off).
    else if ((_isYouTubeBlocked || _isInstagramBlocked) && !_isBlockingEnabled) {
      _toggleMaster(true);
    }
  }

  Future<void> _toggleMaster(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlockingEnabled', newValue);
    setState(() => _isBlockingEnabled = newValue);
    
    // Optional: If Master turned OFF, UI visually updates.
    // If Master turned ON, we leave the individual switches as they were.
  }

  Future<void> _toggleYouTube(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isYouTubeBlocked', newValue);
    setState(() => _isYouTubeBlocked = newValue);
    _syncMasterState(); // Check if we need to update Master
  }

  Future<void> _toggleInstagram(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isInstagramBlocked', newValue);
    setState(() => _isInstagramBlocked = newValue);
    _syncMasterState(); // Check if we need to update Master
  }

  // Helpers
  bool get _isDark => widget.themeController.value;
  Color get _bgColor => _isDark ? kSlate950 : kBgLight;
  Color get _cardColor => _isDark ? kSlate900 : Colors.white;
  Color get _textColor => _isDark ? Colors.white : kGray900;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      _buildAppsList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!_isServiceEnabled) 
             Positioned.fill(
               child: PermissionPopup(
                 onDismiss: () => setState(() => _isServiceEnabled = true), 
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _cardColor, 
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 10), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("FlowCTRL", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textColor, letterSpacing: -0.5)),
          IconButton(
            icon: Icon(Icons.settings, color: _isDark ? kGray400 : Colors.grey),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingsPage(themeController: widget.themeController)),
              );
            }, 
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 60), 
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(_isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text("SCROLL BLOCK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kGray400, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(_isBlockingEnabled ? "Distractions are blocked" : "Focus mode is currently off", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _isBlockingEnabled ? kIndigo : _textColor)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _toggleMaster(!_isBlockingEnabled),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isBlockingEnabled) Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: kIndigo.withOpacity(0.4), blurRadius: 50, spreadRadius: 10)])),
                if (_isBlockingEnabled) AnimatedBuilder(animation: _spinController, builder: (context, child) => Transform.rotate(angle: _spinController.value * 2 * math.pi, child: Container(width: 184, height: 184, decoration: BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Colors.transparent, Colors.transparent, kIndigo.withOpacity(0.8), kIndigo], stops: const [0.0, 0.6, 0.9, 1.0]))))),
                Container(width: 172, height: 172, decoration: BoxDecoration(color: _cardColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isBlockingEnabled ? "ON" : "OFF", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _isBlockingEnabled ? kIndigo : kGray400, letterSpacing: 1)), const SizedBox(height: 4), Text(_isBlockingEnabled ? "Blocking Active" : "Tap to turn ON", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _isBlockingEnabled ? kIndigoLight : kGray400))])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("MANAGED APPS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kGray400, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: _isDark ? kSlate800 : Colors.grey.shade100), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))]),
            child: Column(children: [
              _buildAppItem(
                icon: Icons.play_arrow_rounded, 
                iconColor: Colors.red, 
                bgIconColor: Colors.red.withOpacity(0.1), 
                name: "YouTube", 
                desc: "Block shorts", 
                isOn: _isYouTubeBlocked, 
                onToggle: (val) => _toggleYouTube(val)
              ),
              Container(height: 1, color: _isDark ? kSlate800 : Colors.grey.shade50),
              _buildAppItem(
                icon: Icons.camera_alt_outlined, 
                iconColor: Colors.pink, 
                bgIconColor: Colors.pink.withOpacity(0.1), 
                name: "Instagram", 
                desc: "Block reels", 
                isOn: _isInstagramBlocked, 
                onToggle: (val) => _toggleInstagram(val)
              ),
            ]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppItem({required IconData icon, required Color iconColor, required Color bgIconColor, required String name, required String desc, required bool isOn, required Function(bool) onToggle}) {
    return Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: _textColor)), Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey))])), GestureDetector(onTap: () => onToggle(!isOn), child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 50, height: 28, decoration: BoxDecoration(color: isOn ? kIndigo : (_isDark ? kSlate800 : Colors.grey.shade300), borderRadius: BorderRadius.circular(20)), child: Stack(children: [AnimatedPositioned(duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack, left: isOn ? 24 : 2, top: 2, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 2)]))) ]))) ]));
  }
}

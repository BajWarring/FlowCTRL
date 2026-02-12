import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  // --- State Variables ---
  bool _isServiceEnabled = false; // Is the Android Permission given?
  bool _isBlockingEnabled = true; // Is the "Blocker" turned ON?
  Timer? _monitorTimer;
  late AnimationController _spinController;

  // --- Constants ---
  final Color kIndigo = const Color(0xFF4F46E5);
  final Color kIndigoLight = const Color(0xFF818CF8);
  final Color kGray900 = const Color(0xFF111827);
  final Color kGray400 = const Color(0xFF9CA3AF);
  final Color kBgWhite = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Detect App Resume
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); 
    
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

  // Detect when user comes back from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionNow();
    }
  }

  // --- Logic ---

  void _startPermissionMonitor() {
    // Check frequently (every 500ms) to ensure popup disappears instantly
    _monitorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _checkPermissionNow();
    });
  }

  Future<void> _checkPermissionNow() async {
    bool isRunning = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (isRunning != _isServiceEnabled) {
      if (mounted) {
        setState(() {
          _isServiceEnabled = isRunning;
        });
      }
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBlockingEnabled = prefs.getBool('isBlockingEnabled') ?? true;
    });
    // Check permission immediately on load
    _checkPermissionNow();
  }

  Future<void> _toggleBlocking(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlockingEnabled', newValue);
    setState(() {
      _isBlockingEnabled = newValue;
    });
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Outer background
      body: Center(
        child: Container(
          // The "Mobile Simulation" Container
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 850),
          decoration: BoxDecoration(
            color: kBgWhite,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 50,
                offset: const Offset(0, 25),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
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
                
                // Overlay Logic: Only show if service is NOT enabled
                if (!_isServiceEnabled) 
                  Positioned.fill(
                    child: _buildPermissionOverlay(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white, // Match hero section color to hide gaps
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10), // Reduced top padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "FlowCTRL",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kGray900,
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () {
               // Settings placeholder
            },
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      // Increased bottom padding to ensure button sits completely inside
      padding: const EdgeInsets.only(top: 20, bottom: 60), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            "SCROLL BLOCK",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kGray400,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isBlockingEnabled ? "Distractions are blocked" : "Focus mode is currently off",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _isBlockingEnabled ? kIndigo : kGray900,
            ),
          ),
          const SizedBox(height: 40),

          // THE BIG BUTTON
          GestureDetector(
            onTap: () => _toggleBlocking(!_isBlockingEnabled),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. The Glow (Only when active)
                if (_isBlockingEnabled)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kIndigo.withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                // 2. The Rotating Light Loop
                if (_isBlockingEnabled)
                  AnimatedBuilder(
                    animation: _spinController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _spinController.value * 2 * math.pi,
                        child: Container(
                          width: 184,
                          height: 184,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                Colors.transparent,
                                Colors.transparent,
                                kIndigo.withOpacity(0.8),
                                kIndigo,
                              ],
                              stops: const [0.0, 0.6, 0.9, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 3. The Inner White Button
                Container(
                  width: 172,
                  height: 172,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      // Inner white highlight
                       BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isBlockingEnabled ? "ON" : "OFF",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _isBlockingEnabled ? kIndigo : kGray400,
                          letterSpacing: 1,
                        ),

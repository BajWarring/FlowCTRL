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

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // --- State Variables ---
  bool _isServiceEnabled = false; // Is the Android Permission given?
  bool _isBlockingEnabled = true; // Is the "Blocker" turned ON?
  Timer? _monitorTimer;
  late AnimationController _spinController;

  // --- Constants from your CSS ---
  final Color kIndigo = const Color(0xFF4F46E5);
  final Color kIndigoLight = const Color(0xFF818CF8);
  final Color kGray900 = const Color(0xFF111827);
  final Color kGray400 = const Color(0xFF9CA3AF);
  final Color kBgWhite = const Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Infinite spin for the light
    
    _loadState();
    _startPermissionMonitor();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _startPermissionMonitor() {
    // Check permission every 1 second to auto-dismiss the popup
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool isRunning = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
      if (isRunning != _isServiceEnabled) {
        if (mounted) {
          setState(() {
            _isServiceEnabled = isRunning;
          });
        }
      }
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBlockingEnabled = prefs.getBool('isBlockingEnabled') ?? true;
    });
  }

  Future<void> _toggleBlocking(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    // We save to 'isBlockingEnabled' because that's what the Kotlin code reads
    await prefs.setBool('isBlockingEnabled', newValue);
    setState(() {
      _isBlockingEnabled = newValue;
    });
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          // The "Mobile Simulation" Container from CSS
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
                
                // The Permission Popup Overlay
                if (!_isServiceEnabled) _buildPermissionOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
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
      padding: const EdgeInsets.only(top: 48, bottom: 56),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          // Status Text
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
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _isBlockingEnabled ? _spinController.value * 2 * math.pi : 0,
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isBlockingEnabled ? "Blocking Active" : "Tap to turn ON",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _isBlockingEnabled ? kIndigoLight : kGray400,
                        ),
                      ),
                    ],
                  ),
                ),
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
          Text(
            "MANAGED APPS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kGray400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: const [
                 BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))
              ]
            ),
            child: Column(
              children: [
                _buildAppItem(
                  icon: Icons.play_arrow_rounded,
                  iconColor: Colors.red,
                  bgIconColor: Colors.red.shade50,
                  name: "YouTube",
                  desc: "Block shorts",
                  isOn: _isBlockingEnabled, // Linked to main toggle
                  onToggle: (val) => _toggleBlocking(val),
                ),
                Container(height: 1, color: Colors.grey.shade50),
                _buildAppItem(
                  icon: Icons.camera_alt_outlined,
                  iconColor: Colors.pink,
                  bgIconColor: Colors.pink.shade50,
                  name: "Instagram",
                  desc: "Block reels",
                  isOn: false, // Disabled for now
                  onToggle: (val) {}, // No op
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem({
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required String name,
    required String desc,
    required bool isOn,
    required Function(bool) onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: kGray900,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Custom Mini Toggle
          GestureDetector(
            onTap: () => onToggle(!isOn),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: isOn ? kIndigo : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    left: isOn ? 24 : 2,
                    top: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black12, blurRadius: 2)
                        ]
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- The Permission Overlay ---
  Widget _buildPermissionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6), // Dim background
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app_rounded, size: 60, color: Color(0xFF4F46E5)),
              const SizedBox(height: 20),
              Text(
                "Permission Required",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kGray900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "FlowCTRL needs Accessibility Service to detect when Shorts are playing.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await FlutterAccessibilityService.requestAccessibilityPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Enable in Settings",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

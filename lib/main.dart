import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

void main() {
  runApp(const FlowCTRLApp());
}

class FlowCTRLApp extends StatelessWidget {
  const FlowCTRLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowCTRL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark, // Dark mode looks cooler for tools
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isServiceEnabled = false;
  bool _blockerActive = true;
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Listen for app resume
    _loadState();
    _startMonitoring(); // Start the auto-checker
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitorTimer?.cancel();
    super.dispose();
  }

  // Detect when user switches back to this app from Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  void _startMonitoring() {
    // Check every 1 second. This ensures if the user enables it via floating window
    // or split screen, the UI updates instantly without restarting.
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
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
      _blockerActive = prefs.getBool('isBlockingEnabled') ?? true;
    });
    // Run an initial check immediately
    _checkPermissions();
  }

  Future<void> _toggleBlocker(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    // Native code reads "flutter.isBlockingEnabled"
    // Dart automatically adds the "flutter." prefix.
    await prefs.setBool('isBlockingEnabled', value);
    setState(() {
      _blockerActive = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlowCTRL'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isServiceEnabled 
          ? _buildDashboard() 
          : _buildPermissionScreen(),
    );
  }

  // 1. The Screen displayed when permissions are missing
  Widget _buildPermissionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.accessibility_new_rounded, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 30),
            const Text(
              "Setup Required",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              "To block Shorts, FlowCTRL needs to see when YouTube is open. We don't read your typing or passwords.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text("Open Accessibility Settings"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await FlutterAccessibilityService.requestAccessibilityPermission();
                },
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _checkPermissions,
              child: const Text("I already enabled it", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // 2. The Screen displayed when everything is working (The Toggle)
  Widget _buildDashboard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _blockerActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _blockerActive ? Colors.green : Colors.red,
                width: 2
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _blockerActive ? Icons.check_circle : Icons.pause_circle,
                  color: _blockerActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  _blockerActive ? "BLOCKING ACTIVE" : "PAUSED",
                  style: TextStyle(
                    color: _blockerActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 60),

          // Big Toggle Button
          GestureDetector(
            onTap: () => _toggleBlocker(!_blockerActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blockerActive ? Colors.deepPurpleAccent : Colors.grey[800],
                boxShadow: [
                  BoxShadow(
                    color: _blockerActive ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.transparent,
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 80,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          
          const SizedBox(height: 60),
          
          const Text(
            "Tap the button to toggle",
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

import 'dart:async'; // Import added for Timer
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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

class _HomeScreenState extends State<HomeScreen> {
  bool _isServiceEnabled = false;
  bool _blockerActive = true;
  Timer? _permissionCheckTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    // Start checking for permission every 1 second
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _permissionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool isRunning = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    
    // Only update UI if state changed to avoid flickering
    if (isRunning != _isServiceEnabled) {
      setState(() {
        _isServiceEnabled = isRunning;
      });
      
      // If permission is granted and dialog is likely open, this rebuild will close it
      // purely by virtue of the UI conditional below switching to the main content.
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _blockerActive = prefs.getBool('isBlockingEnabled') ?? true;
    });
  }

  Future<void> _toggleBlocker(bool value) async {
    final prefs = await SharedPreferences.getInstance();
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
        backgroundColor: Colors.deepPurple[100],
      ),
      body: Center(
        child: _isServiceEnabled
            ? _buildControlPanel()
            : _buildPermissionRequest(),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _blockerActive ? Icons.shield : Icons.shield_outlined,
          size: 100,
          color: _blockerActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 30),
        Text(
          _blockerActive ? "Blocker Active" : "Blocker Paused",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Switch(
          value: _blockerActive,
          onChanged: _toggleBlocker,
          activeColor: Colors.green,
        ),
        const SizedBox(height: 50),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Service is Running.\nOpen YouTube Shorts to test.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        )
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.accessibility_new, size: 80, color: Colors.orange),
        const SizedBox(height: 20),
        const Text(
          "Permission Required",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "FlowCTRL needs Accessibility Service to detect and block Shorts content.",
            textAlign: TextAlign.center,
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await FlutterAccessibilityService.requestAccessibilityPermission();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text("Open Settings to Enable"),
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        const Text("Waiting for permission...", style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

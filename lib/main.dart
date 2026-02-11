import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:permission_handler/permission_handler.dart';

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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isServiceEnabled = false;
  bool _blockerActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when user comes back to app
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    // Check if Accessibility Service is running
    bool isRunning = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    setState(() {
      _isServiceEnabled = isRunning;
    });

    if (!isRunning) {
      _showPermissionDialog();
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Key must match the one used in Kotlin (flutter.isBlockingEnabled)
      _blockerActive = prefs.getBool('isBlockingEnabled') ?? true;
    });
  }

  Future<void> _toggleBlocker(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBlockingEnabled', value);
    setState(() {
      _blockerActive = value;
    });
    // Note: The native service reads this SharedPref value
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("FlowCTRL needs Accessibility Service to detect and block Shorts."),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.accessibility_new, color: Colors.red),
              title: const Text("Accessibility Service"),
              subtitle: const Text("Tap to enable in Settings"),
              onTap: () async {
                // Open Accessibility Settings
                await FlutterAccessibilityService.requestAccessibilityPermission();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
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
            ? Column(
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
                      "Open YouTube to test. If a Short appears, FlowCTRL will automatically navigate back.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

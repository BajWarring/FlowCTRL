import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'splash_screen.dart'; // Import the new splash screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  
  runApp(FlowCTRLApp(initialDarkMode: isDark));
}

class ThemeController extends ValueNotifier<bool> {
  ThemeController(super.value);

  Future<void> toggle() async {
    value = !value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }
}

class FlowCTRLApp extends StatefulWidget {
  final bool initialDarkMode;
  const FlowCTRLApp({super.key, required this.initialDarkMode});

  @override
  State<FlowCTRLApp> createState() => _FlowCTRLAppState();
}

class _FlowCTRLAppState extends State<FlowCTRLApp> {
  late ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController(widget.initialDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _themeController,
      builder: (context, isDark, child) {
        
        SystemChrome.setSystemUIOverlayStyle(
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark
        );

        return MaterialApp(
          title: 'FlowCTRL',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF9FAFB),
          ),
          // Changed 'home' to SplashScreen
          home: SplashScreen(themeController: _themeController),
        );
      },
    );
  }
}

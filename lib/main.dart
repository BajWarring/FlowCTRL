import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

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
        fontFamily: 'Inter', // Will fallback to default if not installed
        scaffoldBackgroundColor: const Color(0xFFE5E7EB), // The outer grey bg
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

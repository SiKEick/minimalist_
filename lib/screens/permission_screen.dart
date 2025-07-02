import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'main_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool? isGranted = await UsageStats.checkUsagePermission();
    if (isGranted == true) {
      _navigateToHome();
    } else {
      setState(() {
        isChecking = false;
      });
      // Show dialog directly
      Future.microtask(() => _showPermissionDialog());
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FocusModeHomePage()),
    );
  }

  void _openSettings() {
    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "To show your app usage data and enable focus mode features, "
          "please grant 'Usage Access' permission in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Just close dialog
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _openSettings(); // Then go to settings
            },
            child: const Text("Go to Settings"),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for app resume (e.g., returning from settings)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startPermissionCheckLoop();
    });
  }

  void _startPermissionCheckLoop() async {
    await Future.delayed(const Duration(seconds: 1));
    bool? isGranted = await UsageStats.checkUsagePermission();
    if (isGranted == true) {
      _navigateToHome();
    } else {
      // Keep checking until granted
      _startPermissionCheckLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isChecking
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}

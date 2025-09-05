import 'dart:io';
import 'package:flutter/material.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';
import 'package:minimalist_text2/screens/Name_input_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool isChecking = true;
  bool _navigated = false; // ✅ prevent multiple navigations

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ✅ Listen for app resume after settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_navigated) {
      _checkPermission();
    }
  }

  /// ✅ Main permission check (sequential flow)
  Future<void> _checkPermission() async {
    if (_navigated) return; // stop if already navigated

    bool? usageGranted = await UsageStats.checkUsagePermission();

    if (usageGranted != true) {
      Future.microtask(() => _showUsageDialog());
      setState(() => isChecking = false);
      return;
    }

    bool overlayGranted = await _checkOverlayPermission();

    if (!overlayGranted) {
      Future.microtask(() => _showOverlayDialog());
      setState(() => isChecking = false);
      return;
    }

    // ✅ Both granted
    _navigateToHome();
  }

  /// ✅ Navigate to home if name exists, otherwise go to name input
  void _navigateToHome() async {
    if (_navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final String? name = prefs.getString('user_name');
    if (!mounted) return;

    if (name != null && name.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FocusModeHomePage(userName: name),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NameInputScreen(),
        ),
      );
    }
  }

  /// ✅ Check overlay permission via MethodChannel
  Future<bool> _checkOverlayPermission() async {
    if (Platform.isAndroid) {
      try {
        final bool granted =
            await const MethodChannel('overlay_permission_channel')
                .invokeMethod('hasOverlayPermission');
        return granted;
      } catch (e) {
        debugPrint("Overlay check error: $e");
        return false;
      }
    }
    return true; // iOS doesn’t need this
  }

  /// ✅ Open usage access settings
  void _openUsageAccessSettings() {
    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  /// ✅ Open overlay settings
  void _openOverlaySettings() {
    const intent = AndroidIntent(
      action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  /// ✅ Show usage dialog
  void _showUsageDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Usage Access Required"),
        content: const Text(
          "Please grant 'Usage Access' permission in settings to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog only
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openUsageAccessSettings();
            },
            child: const Text("Grant"),
          ),
        ],
      ),
    );
  }

  /// ✅ Show overlay dialog
  void _showOverlayDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Overlay Permission Required"),
        content: const Text(
          "Please grant 'Display over other apps' permission in settings to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openOverlaySettings();
            },
            child: const Text("Grant"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: isChecking
            ? const CircularProgressIndicator()
            : const Text(
                "Waiting for permissions...",
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}

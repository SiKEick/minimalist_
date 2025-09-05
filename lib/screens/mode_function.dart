import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ModeFunctionScreen extends StatefulWidget {
  final String modeTitle;
  const ModeFunctionScreen({Key? key, required this.modeTitle})
      : super(key: key);

  @override
  _ModeFunctionScreenState createState() => _ModeFunctionScreenState();
}

class _ModeFunctionScreenState extends State<ModeFunctionScreen> {
  Duration _selectedDuration = Duration(minutes: 30);
  final Duration _initialDuration = Duration(minutes: 30);
  static const MethodChannel _platform = MethodChannel('focus_mode_channel');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<Application> _allInstalledApps = []; // Full app list
  List<Application> _installedApps = []; // Filtered list
  Map<String, bool> _selectedApps = {};
  bool _isModeActive = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  String? _savedPassword;

  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _getInstalledApps();
    _loadModeState();
  }

  Future<void> _getInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeSystemApps: false,
    );
    setState(() {
      _allInstalledApps = apps;
      _installedApps = apps;
      for (var app in apps) {
        _selectedApps[app.packageName] = false;
      }
    });
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      List<Application> filtered = _allInstalledApps.where((app) {
        return app.appName.toLowerCase().contains(_searchQuery);
      }).toList();

      // If nothing matches, show full list
      _installedApps = filtered.isEmpty ? _allInstalledApps : filtered;
    });
  }

  Future<void> _loadModeState() async {
    String? active = await _secureStorage.read(key: "isModeActive");
    if (active == "true") {
      String? remaining = await _secureStorage.read(key: "remainingTime");
      String? password = await _secureStorage.read(key: "focus_password");
      setState(() {
        _isModeActive = true;
        _remainingSeconds = int.tryParse(remaining ?? "0") ?? 0;
        _savedPassword = password;
      });
      if (_remainingSeconds > 0) {
        _startCountdownTimer();
      }
    }
  }

  Future<void> _saveModeState() async {
    await _secureStorage.write(
        key: "isModeActive", value: _isModeActive.toString());
    await _secureStorage.write(
        key: "remainingTime", value: _remainingSeconds.toString());
  }

  Future<void> _clearModeState() async {
    await _secureStorage.delete(key: "isModeActive");
    await _secureStorage.delete(key: "remainingTime");
    await _secureStorage.delete(key: "focus_password");
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _saveModeState();
      } else {
        timer.cancel();
        await _stopFocusMode();
      }
    });
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          setState(() {
            _selectedDuration = _initialDuration;
          });
          Navigator.pop(context);
          return false;
        },
        child: Container(
          height: 250,
          color: Colors.black,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: _selectedDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    setState(() {
                      _selectedDuration = newDuration;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDuration = _initialDuration;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.red, fontSize: 18)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_selectedDuration < _initialDuration) {
                        _showTimeWarning();
                        setState(() {
                          _selectedDuration = _initialDuration;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("OK",
                        style: TextStyle(color: Colors.blue, fontSize: 18)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Invalid Time"),
        content: const Text("Time can't be set to less than 30 minutes."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _startFocusMode() async {
    if (_isModeActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Focus Mode is already running!")),
      );
      return;
    }

    List<String> blockedApps = _selectedApps.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    if (blockedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one app.")),
      );
      return;
    }

    String? password = await _askPassword();
    if (password == null || password.isEmpty) return;

    await _secureStorage.write(key: "focus_password", value: password);

    setState(() {
      _isModeActive = true;
      _remainingSeconds = _selectedDuration.inSeconds;
      _savedPassword = password;
    });

    _saveModeState();
    _startCountdownTimer();

    try {
      await _platform.invokeMethod('startFocusMode', {
        'password': password,
        'blockedApps': blockedApps,
        'duration': _selectedDuration.inSeconds,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Focus Mode Started!")),
      );
    } catch (e) {
      print("Error starting focus mode: $e");
    }
  }

  Future<void> _stopFocusMode() async {
    TextEditingController controller = TextEditingController();

    String? enteredPassword = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Password to Stop"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Enter your password"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (enteredPassword == null || enteredPassword.isEmpty) return;

    if (enteredPassword == _savedPassword) {
      setState(() {
        _isModeActive = false;
        _remainingSeconds = 0;
        _savedPassword = null;
      });
      _countdownTimer?.cancel();
      await _clearModeState();

      try {
        await _platform.invokeMethod('stopFocusMode');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Focus Mode Stopped.")),
        );
      } catch (e) {
        print("Error stopping focus mode: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect password!")),
      );
    }
  }

  Future<String?> _askPassword() async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Focus Mode Password"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Enter password"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.modeTitle),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    "Set Timer",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: _showTimePicker,
                  ),
                ),
              ],
            ),
            Text(
              _isModeActive
                  ? _formatTime(_remainingSeconds)
                  : "${_selectedDuration.inHours.toString().padLeft(2, '0')}:${(_selectedDuration.inMinutes % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            _installedApps.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Distracting Apps",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _searchController,
                              onChanged: _filterApps,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Search apps",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                prefixIcon: const Icon(Icons.search,
                                    color: Colors.white),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: _allInstalledApps.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : _installedApps.isEmpty
                                      ? const Center(
                                          child: Text(
                                            "No apps found",
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        )
                                      : ListView(
                                          children: _installedApps.map((app) {
                                            return CheckboxListTile(
                                              title: Text(
                                                app.appName,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                              value: _selectedApps[
                                                  app.packageName],
                                              onChanged: _isModeActive
                                                  ? null
                                                  : (bool? value) {
                                                      setState(() {
                                                        _selectedApps[app
                                                                .packageName] =
                                                            value!;
                                                      });
                                                    },
                                              activeColor: Colors.blue,
                                              checkColor: Colors.white,
                                            );
                                          }).toList(),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            _isModeActive
                ? ElevatedButton(
                    onPressed: _stopFocusMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text("Stop Focus Mode"),
                  )
                : ElevatedButton(
                    onPressed: _startFocusMode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                    ),
                    child: const Text("Start Focus Mode"),
                  ),
          ],
        ),
      ),
    );
  }
}
//hi

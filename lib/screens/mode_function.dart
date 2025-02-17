import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:device_apps/device_apps.dart';

class ModeFunctionScreen extends StatefulWidget {
  final String modeTitle;

  const ModeFunctionScreen({
    Key? key,
    required this.modeTitle,
  }) : super(key: key);

  @override
  _ModeFunctionScreenState createState() => _ModeFunctionScreenState();
}

class _ModeFunctionScreenState extends State<ModeFunctionScreen> {
  Duration _selectedDuration = Duration(minutes: 30); // Default duration
  final Duration _initialDuration = Duration(minutes: 30);

  // List to hold installed apps names
  List<String> _installedApps = [];

  // A map to store the selection state of each app
  Map<String, bool> _selectedApps = {};

  @override
  void initState() {
    super.initState();
    _getInstalledApps();
  }

  // Method to get the installed apps on the device
  Future<void> _getInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false); // Exclude system apps
    List<String> appNames = apps.map((app) => app.appName).toList();

    setState(() {
      _installedApps = appNames; // Store app names in _installedApps
      _installedApps.forEach((app) {
        _selectedApps[app] = false; // Initialize checkbox state for each app
      });
    });
  }

  void _showTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          // Reset to the initial duration when the back button is pressed
          setState(() {
            _selectedDuration = _initialDuration;
          });
          Navigator.pop(context);
          return false; // Prevent the modal from closing by default
        },
        child: GestureDetector(
          onTap: () {}, // Prevent tapping outside to close the modal
          child: Container(
            height: 250,
            color: Colors.black,
            child: GestureDetector(
              onTap:
                  () {}, // Prevent tapping inside the timer picker from closing it
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm, // Hours and minutes
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
                      // Cancel button: Reset to initial time
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDuration = _initialDuration;
                          });
                          Navigator.pop(context); // Close the modal
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      ),
                      // OK button: Validate and keep the selected time
                      TextButton(
                        onPressed: () {
                          if (_selectedDuration < _initialDuration) {
                            // Show warning if time is less than 30 minutes
                            _showTimeWarning();
                            setState(() {
                              _selectedDuration =
                                  _initialDuration; // Reset to initial time
                            });
                          } else {
                            Navigator.pop(context); // Close the modal
                          }
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(color: Colors.blue, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTimeWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Invalid Time"),
        content: Text("Time can't be set to less than 30 minutes."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the warning dialog
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
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
                Center(
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
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: _showTimePicker,
                  ),
                ),
              ],
            ),
            Text(
              "${_selectedDuration.inHours.toString().padLeft(2, '0')}:${(_selectedDuration.inMinutes % 60).toString().padLeft(2, '0')}",
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            // Scrollable Card for distracting apps with checkboxes
            _installedApps.isEmpty
                ? Center(
                    child:
                        CircularProgressIndicator()) // Show loading indicator
                : Expanded(
                    child: Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Distracting Apps",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            // Use a flexible widget so it takes up available space
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _installedApps.map((app) {
                                    return CheckboxListTile(
                                      title: Text(
                                        app,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      value: _selectedApps[app],
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _selectedApps[app] = value!;
                                        });
                                      },
                                      activeColor: Colors.blue,
                                      checkColor: Colors.white,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

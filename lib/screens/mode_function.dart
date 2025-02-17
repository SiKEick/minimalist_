import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
            Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                print("Proceed with ${_selectedDuration.inMinutes} min");
              },
              child: Text("Next: Select Apps to Block"),
            ),
          ],
        ),
      ),
    );
  }
}

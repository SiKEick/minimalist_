import 'package:flutter/material.dart';
import 'package:minimalist_text2/screens/mode_selection.dart';
import 'package:minimalist_text2/Top5App.dart';
import 'package:flutter/services.dart';
import 'package:minimalist_text2/screens/Name_input_screen.dart';

class FocusModeHomePage extends StatefulWidget {
  final String userName;
  const FocusModeHomePage({super.key, required this.userName});
  static const String id = 'FocusModeHomePage';

  @override
  _FocusModeHomePageState createState() => _FocusModeHomePageState();
}

class _FocusModeHomePageState extends State<FocusModeHomePage> {
  // Initial modes
  List<Map<String, String>> modes = [
    {'title': 'STUDY MODE', 'subtitle': 'Focus on learning.'},
    {'title': 'WORK MODE', 'subtitle': 'Boost your productivity.'},
    {'title': 'EXERCISE MODE', 'subtitle': 'Track your workout.'},
  ];
  static const platform = MethodChannel('com.example.app/usage');
  String screenTime = "Loading...";

  @override
  void initState() {
    super.initState();
    _getTotalScreenTime();
  }

  Future<void> _getTotalScreenTime() async {
    try {
      final int result = await platform.invokeMethod(
        'getTotalScreenTime',
        DateTime.now().millisecondsSinceEpoch, // Pass today's timestamp
      );

      Duration duration = Duration(milliseconds: result);
      String formattedTime =
          "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
      setState(() {
        screenTime = formattedTime;
      });
    } on PlatformException catch (e) {
      setState(() {
        screenTime = "Failed to get screen time: ${e.message}";
      });
    }
  }

  // Method to update the modes list
  void _updateModes(List<Map<String, String>> newModes) {
    setState(() {
      modes = newModes;
    });
  }

  void ShowModeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.grey[900],
      builder: (BuildContext context) {
        return ModeSelectionSheet(
          modes: modes, // Pass the modes list
          updateModes: _updateModes, // Pass the updateModes function
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset:
            true, // Keeps the screen responsive when keyboard appears
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics:
                    AlwaysScrollableScrollPhysics(), // Prevents unwanted overflow
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight, // Ensures scrolling if needed
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Greeting Section
                        Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome,',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${widget.userName}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Screen Time & Graph Section
                        Card(
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child:
                                        _infoColumn('SCREEN TIME', screenTime)),
                                Expanded(
                                  child: _infoColumn('LAST HOUR', '-3.8%',
                                      color: Colors.green),
                                ),
                                Expanded(child: _infoColumn('PICKUPS', '20')),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4, // Adjusts dynamically
                          child: Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Top5App()),
                          ),
                        ),
                        // Start Focus Mode Section
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Focus Mode',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Spacer(),
                                  IconButton(
                                    onPressed: () => ShowModeSelection(context),
                                    icon: Icon(Icons.play_circle_fill),
                                    color: Colors.white,
                                    iconSize: 60,
                                    highlightColor: Colors.grey[900],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper function to create information columns
  Widget _infoColumn(String title, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20),
        ),
      ],
    );
  }
}

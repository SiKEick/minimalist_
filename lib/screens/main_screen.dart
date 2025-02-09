import 'package:flutter/material.dart';
import 'package:minimalist_text2/screens/mode_selection.dart';
import 'package:minimalist_text2/Top5App.dart';

class FocusModeHomePage extends StatefulWidget {
  const FocusModeHomePage({super.key});
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
        resizeToAvoidBottomInset: true,
        // Keeps the screen responsive when keyboard appears
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                // Prevents unwanted overflow
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
                                  'Morning, Jane.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 35,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '9.3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                  ),
                                ),
                                Text(
                                  'DEEP FOCUS',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Screen Time & Graph Section
                        Expanded(
                          flex: 4, // Adjusts dynamically
                          child: Card(
                            color: Colors.grey[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _infoColumn('SCREEN TIME', '53m 22s'),
                                      _infoColumn('LAST HOUR', '-3.8%',
                                          color: Colors.green),
                                      _infoColumn('PICKUPS', '20'),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Top5App()
                                ],
                              ),
                            ),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FOCUS MODE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                        ),
                                      ),
                                      Text(
                                        'Last Focused 21 minutes ago',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.fromLTRB(0, 0, 16, 18),
                                  onPressed: () => ShowModeSelection(context),
                                  icon: Icon(Icons.play_circle_fill),
                                  color: Colors.white,
                                  highlightColor: Colors.grey[900],
                                  iconSize: 60,
                                ),
                              ],
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

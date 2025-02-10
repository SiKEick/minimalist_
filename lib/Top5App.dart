import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Top5App extends StatefulWidget {
  const Top5App({super.key});

  @override
  _Top5AppState createState() => _Top5AppState();
}

class _Top5AppState extends State<Top5App> {
  static const platform = MethodChannel('com.example.app/usage');
  List<Map<String, dynamic>> topApps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUsageStats();
  }

  Future<void> _getUsageStats() async {
    try {
      final List<dynamic> usageStats =
          await platform.invokeMethod('getUsageStats');
      final List<Map<String, dynamic>> top5Apps = usageStats.take(5).map((app) {
        return {
          "appName": app["appName"] ?? 'Unknown App',
          "totalTimeInForeground": app["totalTimeInForeground"] ?? 0,
        };
      }).toList();
      setState(() {
        topApps = top5Apps;
        isLoading = false;
      });
    } on PlatformException catch (e) {
      print("Failed to get usage stats: '${e.message}'.");
    }
  }

  String formatTime(int totalTimeInForeground) {
    int hours = totalTimeInForeground ~/ 3600000;
    int minutes = (totalTimeInForeground % 3600000) ~/ 60000;
    return '${hours}hr ${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Details',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        isLoading
            ? Center(child: CircularProgressIndicator())
            : Expanded(
                child: Column(
                  children: topApps
                      .map((app) => Expanded(
                            child: Container(
                              child: Row(
                                children: [
                                  // Icon column
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Icon(
                                      Icons.android,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  // App name column
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(4, 0, 0, 0),
                                      child: Text(
                                        app["appName"],
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 22),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                  // Screen time column
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        formatTime(
                                            app["totalTimeInForeground"]),
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
      ],
    );
  }
}

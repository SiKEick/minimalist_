import 'dart:convert';
import 'dart:typed_data';
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

      setState(() {
        topApps = usageStats.take(5).map((app) {
          return {
            "appName": app["appName"] ?? 'Unknown App',
            "totalTimeInForeground": app["totalTimeInForeground"] ?? 0,
            "icon": app["icon"] ?? "",
          };
        }).toList();
        isLoading = false;
      });

      // Debugging print
      for (var app in topApps) {
        print(
            "App: ${app['appName']}, Icon: ${app['icon'].isEmpty ? 'No Icon' : 'Has Icon'}");
      }
    } on PlatformException catch (e) {
      print("Failed to get usage stats: '${e.message}'");
    }
  }

  String formatTime(int totalTimeInForeground) {
    int hours = totalTimeInForeground ~/ 3600000;
    int minutes = (totalTimeInForeground % 3600000) ~/ 60000;
    return '${hours} hr ${minutes} min';
  }

  Widget getAppIcon(String? base64Icon, {double size = 40}) {
    if (base64Icon == null || base64Icon.isEmpty) {
      return Icon(Icons.android,
          color: Colors.white, size: size); // Default icon
    }
    try {
      Uint8List bytes = base64Decode(base64Icon);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } catch (e) {
      print("Error decoding icon: $e");
      return Icon(Icons.android, color: Colors.white, size: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Details',
          style: TextStyle(color: Colors.white, fontSize: 22),
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
                                    child: getAppIcon(app["icon"], size: 35),
                                  ),
                                  // App name column
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(6, 0, 0, 0),
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

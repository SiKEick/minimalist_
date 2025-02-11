import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const platform = MethodChannel('com.example.app/usage');
  List<Map<String, dynamic>> allApps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getAllUsageStats();
  }

  Future<void> _getAllUsageStats() async {
    try {
      final List<dynamic> usageStats =
          await platform.invokeMethod('getUsageStats');

      setState(() {
        allApps = usageStats.map((app) {
          return {
            "appName": app["appName"] ?? 'Unknown App',
            "totalTimeInForeground": app["totalTimeInForeground"] ?? 0,
            "icon": app["icon"] ?? "",
          };
        }).toList();
        isLoading = false;
      });
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
      return Icon(Icons.android, color: Colors.white, size: size);
    }
    try {
      Uint8List bytes = base64Decode(base64Icon);
      return Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } catch (e) {
      return Icon(Icons.android, color: Colors.white, size: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("All Apps Usage"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: allApps.length,
              itemBuilder: (context, index) {
                final app = allApps[index];
                return ListTile(
                  leading: getAppIcon(app["icon"], size: 40),
                  title: Text(
                    app["appName"],
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Text(
                    formatTime(app["totalTimeInForeground"]),
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              },
            ),
    );
  }
}

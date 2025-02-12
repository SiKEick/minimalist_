import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // For date formatting

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const platform = MethodChannel('com.example.app/usage');
  List<Map<String, dynamic>> allApps = [];
  Map<String, int> dailyScreenTime = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now(); // Default to today

  @override
  void initState() {
    super.initState();
    _getAllUsageStats(selectedDate);
  }

  Future<void> _getAllUsageStats(DateTime date) async {
    try {
      // Get total screen time
      final int totalScreenTime =
          await platform.invokeMethod('getTotalScreenTime');

      // Get all apps' usage data
      final List<dynamic> usageStats =
          await platform.invokeMethod('getAllUsageStats');

      setState(() {
        allApps = usageStats.map((app) {
          return {
            "appName": app["appName"] ?? 'Unknown App',
            "totalTimeInForeground": app["totalTimeInForeground"] ?? 0,
            "icon": app["icon"] ?? "",
          };
        }).toList();

        // Store total daily screen time
        String formattedDate = DateFormat('EEE, MMM d').format(date);
        dailyScreenTime[formattedDate] = totalScreenTime;

        isLoading = false;
      });
    } on PlatformException catch (e) {
      print("Failed to get usage stats: '${e.message}'");
    }
  }

  String formatTime(int totalTimeInForeground) {
    int hours = totalTimeInForeground ~/ 3600000;
    int minutes = (totalTimeInForeground % 3600000) ~/ 60000;
    if (hours == 0) {
      return '${minutes} min';
    } else {
      return '${hours} hr ${minutes} min';
    }
  }

  bool _canMoveForward() {
    DateTime today = DateTime.now();
    DateTime selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime current = DateTime(today.year, today.month, today.day);
    return selected.isBefore(current); // Ensures you can't move beyond today
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

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      isLoading = true;
      _getAllUsageStats(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Activity Details",
          style: TextStyle(fontSize: 27),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total screen time
            Center(
              child: Column(
                children: [
                  Text(
                    "${formatTime(dailyScreenTime[DateFormat('EEE, MMM d').format(selectedDate)] ?? 0)}",
                    style: TextStyle(color: Colors.white, fontSize: 30),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Date navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _changeDate(-1),
                ),
                Text(
                  DateFormat('EEE, MMM d').format(selectedDate),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios,
                      color: _canMoveForward() ? Colors.white : Colors.grey),
                  onPressed: _canMoveForward() ? () => _changeDate(1) : null,
                ),
              ],
            ),
            SizedBox(height: 10),

            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: allApps.length,
                      itemBuilder: (context, index) {
                        final app = allApps[index];
                        return ListTile(
                          leading: getAppIcon(app["icon"], size: 35),
                          title: Text(
                            app["appName"],
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          trailing: Text(
                            formatTime(app["totalTimeInForeground"]),
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

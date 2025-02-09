import 'package:flutter/material.dart';

class Top5App extends StatefulWidget {
  const Top5App({super.key});

  @override
  _Top5AppState createState() => _Top5AppState();
}

class _Top5AppState extends State<Top5App> {
  List<Map<String, dynamic>> topApps = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Used Apps Today',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            SizedBox(height: 16),
            topApps.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: topApps
                        .map((app) => ListTile(
                              leading: Icon(Icons.android, color: Colors.white),
                              title: Text(app["packageName"],
                                  style: TextStyle(color: Colors.white)),
                              subtitle: Text(
                                  "Time used: ${(app["screenTime"] ~/ 60000)} min",
                                  style: TextStyle(color: Colors.grey)),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}

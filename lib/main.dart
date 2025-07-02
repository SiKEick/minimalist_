import 'package:flutter/material.dart';
import 'package:minimalist_text2/screens/permission_screen.dart';

void main() {
  runApp(const PhoneFocus());
}

class PhoneFocus extends StatelessWidget {
  const PhoneFocus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.dark()),
      home: const PermissionScreen(),
    );
  }
}

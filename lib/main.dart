import 'package:flutter/material.dart';
import 'package:minimalist_text2/screens/main_screen.dart';

void main() {
  runApp(const PhoneFocus());
}

class PhoneFocus extends StatelessWidget {
  const PhoneFocus({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.dark()),
      initialRoute: FocusModeHomePage.id,
      routes: {FocusModeHomePage.id: (context) => const FocusModeHomePage()},
    );
  }
}

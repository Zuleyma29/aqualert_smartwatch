import 'package:flutter/material.dart';
import 'screens/tome_agua.dart';

void main() {
  runApp(const AqualertApp());
}

class AqualertApp extends StatelessWidget {
  const AqualertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Aqualert',
      debugShowCheckedModeBanner: false,
      home: TomeAguaScreen(),
    );
  }
}

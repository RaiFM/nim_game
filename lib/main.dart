import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(NimGameApp());
}

class NimGameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nim Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
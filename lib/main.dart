import 'package:flutter/material.dart';
import 'login.dart'; // Pastikan nama file UI kamu benar-benar 'login.dart'

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Healthify',
      theme: ThemeData(
        fontFamily: 'Arial',
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Di sini kita panggil Class 'LoginScreen' yang ada di dalam file login.dart
      home: const LoginScreen(), 
    );
  }
}


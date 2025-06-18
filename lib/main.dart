import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:catatsaku_full/models/database.dart';
import 'package:catatsaku_full/pages/main_page.dart';
import 'package:catatsaku_full/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  final db = AppDb(); // Buat instance database

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLoggedIn = prefs.getString('user_email') != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CatatSaku',
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? MainPage(db: db) : const WelcomeScreen(),
    );
  }
}

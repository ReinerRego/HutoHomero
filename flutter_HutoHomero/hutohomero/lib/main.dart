import 'package:flutter/material.dart';
import 'package:hutohomero/choose_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final String? savedUsername = prefs.getString('username');
  final String? savedPassword = prefs.getString('password');

  runApp(savedUsername != null && savedPassword != null
      ? const MyApp()
      : const ChooseApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 93, 223, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Charter hűtőhőmerő'),
    );
  }
}

class ChooseApp extends StatelessWidget {
  const ChooseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Choosing Page',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 93, 223, 255)
        ),
        useMaterial3: true,
      ),
      home: const ChoosePage(),
    );
  }
}



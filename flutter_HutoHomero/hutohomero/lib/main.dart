import 'package:flutter/material.dart';
import 'package:hutohomero/choose_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home/home.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
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
      title: 'Charter Hűtőhőmérő',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 93, 223, 255)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Charter Hűtőhőmérő'),
    );
  }
}

class ChooseApp extends StatelessWidget {
  const ChooseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Charter Hűtőhőmérő',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 93, 223, 255)),
        useMaterial3: true,
      ),
      home: const ChoosePage(),
    );
  }
}

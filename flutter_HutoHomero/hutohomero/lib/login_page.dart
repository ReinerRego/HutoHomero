import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hutohomero/home.dart';
import 'package:hutohomero/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    final String url = 'http://51.20.165.73:5000/login';
    final Map<String, dynamic> data = {
      'username': usernameController.text,
      'password': passwordController.text,
    };

    final String jsonData = json.encode(data);

    final response = await http.post(
      Uri.parse(url),
      body: jsonData,
      headers: {'Content-Type': 'application/json'},
    );

    print('Response body: ${response.body}');
    print('statusCode: ${response.statusCode}');
    final responseData = json.decode(response.body);
    final status = responseData['status'];

    if (response.statusCode == 200) {
      // Save login details to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('username', usernameController.text);
      prefs.setString('password', passwordController.text);

      runApp(const MyApp());
    }
    if (response.statusCode == 401) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Helytelen adatok'),
            content: const Text(
                'A felhasznalóneved vagy a jelszavadat rosszul írtad be.'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hiba!'),
            content: const Text(
                'Ismeretlen hiba történt! (unreachable)'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
    void clearSavedCredentials() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('username');
      prefs.remove('password');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved credentials removed for debugging.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 338,
              height: 150,
              child: Stack(
                children: [
                  const Positioned(
                    left: 0,
                    top: 42,
                    child: SizedBox(
                      width: 274,
                      height: 61,
                      child: Text(
                        'Üdvözlünk újra!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    top: 89,
                    child: SizedBox(
                      width: 338,
                      height: 61,
                      child: Text(
                        'Kérlek írd be a felhasználóneved\nés a jelszavad.',
                        style: TextStyle(
                          color: Color(0xFF565656),
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 144,
                      height: 34,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 1,
                            child: Container(
                              width: 29,
                              height: 33,
                              clipBehavior: Clip.antiAlias,
                              decoration: const BoxDecoration(),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Image(image: AssetImage('assets/snowflake.png'))],
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 38,
                            top: 0,
                            child: SizedBox(
                              width: 106,
                              height: 34,
                              child: Text(
                                'Charter\nHűtőhőmérő',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () {
                login();
              },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

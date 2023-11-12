// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController wifiPasswordController = TextEditingController();
  final TextEditingController postDelayController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  Future<String> checkAvailability() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.4.1/available'));
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['available'];
      }
    } catch (e) {
      print('Error checking availability: $e');
    }
    return 'no';
  }

  Future<void> showInputDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String url = 'http://192.168.4.1/setup';

    final String? savedUsername = prefs.getString('username');
    final String? savedPassword = prefs.getString('password');

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: checkAvailability().timeout(const Duration(seconds: 5)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                title: Text('Eszköz ellenőrzése'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 23.0),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              print(snapshot.error);
              return AlertDialog(
                title: const Text('Az eszköz elérhetetlen.'),
                content: const Text(
                    'Nem tudtuk elérni az eszközödet időben. Biztos vagy benne, hogy csatlakozva vagy hozzá?'),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            } else if (snapshot.data == 'yes') {
              return AlertDialog(
                title: const Text('Hűtőhőmérő beállításai'),
                content: Column(
                  children: <Widget>[
                    TextField(
                      controller: ssidController,
                      decoration: const InputDecoration(labelText: 'SSID'),
                    ),
                    TextField(
                      controller: wifiPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'WiFi Password'),
                    ),
                    TextField(
                      controller: postDelayController,
                      decoration:
                          const InputDecoration(labelText: 'Post Delay'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                  ],
                ),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      sendRequest();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Mentés'),
                  ),
                ],
              );
            } else {
              return AlertDialog(
                title: const Text('Az eszköz elérhetetlen.'),
                content: const Text(
                    'Biztos vagy benne, hogy csatlakozva vagy az eszköz WiFi hálózatára?'),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  Future<void> sendRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final String url = 'http://192.168.4.1/setup';

    final String? savedUsername = prefs.getString('username');
    final String? savedPassword = prefs.getString('password');

    print(postDelayController.text);

    final String postDelayText = postDelayController.text.trim();

    // Remove quotes and parse the value as an integer
    final int postDelay = int.parse(postDelayText);

    final Map<String, dynamic> data = {
      'username': savedUsername,
      'password': savedPassword,
      'ssid': ssidController.text,
      'wifiPassword': wifiPasswordController.text,
      'postDelay': postDelay,
      'locazion' : locationController.text
    };
    final String jsonData = json.encode(data);
    final response = await http.post(
      Uri.parse(url),
      body: jsonData,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      // Handle successful response
      print('Request successful');
    } else {
      // Handle error
      print('Request failed with status code: ${response.statusCode}');
    }
  }

  // Add this method to remove saved credentials
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

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(
            255, 93, 223, 255), // Set the background color of the app bar
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearSavedCredentials,
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // No need for the button here
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showInputDialog(context);
        },
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
    );
  }
}

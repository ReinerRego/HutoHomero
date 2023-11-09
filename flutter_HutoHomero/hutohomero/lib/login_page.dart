import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hutohomero/home.dart';
import 'package:hutohomero/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  if (usernameController.text.length < 4) {
      _showErrorDialog('Hiba!',
          'A felhasználónévnek legalább 4 karakter hosszúnak kell lennie.');
      setState(() {
        isLoading = false;
      });
      return;
    }

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
            content: const Text('Helytelenül adtad meg az adataidat.'),
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
            content: const Text('Ismeretlen hiba történt! (unreachable)'),
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
    //Setting SysemUIOverlay
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: true,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.dark));

//Setting SystmeUIMode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top]);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: SvgPicture.string('''
             <svg width="428" height="503" viewBox="0 0 428 503" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M299.376 257.475C300.448 248.466 301 239.298 301 230C301 102.975 198.025 0 71 0C-56.0255 0 -159 102.975 -159 230C-159 341.492 -79.6698 434.456 25.6241 455.525C24.5517 464.534 24 473.702 24 483C24 610.026 126.975 713 254 713C381.026 713 484 610.026 484 483C484 371.508 404.67 278.544 299.376 257.475Z" fill="url(#paint0_linear_52_11)"/>
  <defs>
    <linearGradient id="paint0_linear_52_11" x1="162.5" y1="0" x2="162.5" y2="713" gradientUnits="userSpaceOnUse">
      <stop stop-color="#B7EEFF" stop-opacity="0.812874"/>
      <stop offset="0.270833" stop-color="#B3E4FF" stop-opacity="0.582261"/>
      <stop offset="0.776042" stop-color="#D7F8FF" stop-opacity="0"/>
    </linearGradient>
  </defs>
</svg>
              ''',
                width: MediaQuery.of(context).size.width * 1,
                alignment: Alignment.bottomLeft,
                fit: BoxFit.none),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10.0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).padding.top + 60),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.18,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: MediaQuery.of(context).size.height * 0.04,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 1,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.07,
                                height:
                                    MediaQuery.of(context).size.height * 0.04,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset('assets/snowflake.png')
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: MediaQuery.of(context).size.width * 0.09,
                              top: 0,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                height:
                                    MediaQuery.of(context).size.height * 0.04,
                                child: Text(
                                  'Charter\nHűtőhőmérő',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
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
                      SizedBox(
                          height: MediaQuery.of(context).size.width * 0.020),
                      SizedBox(
                        child: Text(
                          'Üdvözlünk újra!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: MediaQuery.of(context).size.width * 0.075,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            height: 0,
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.width * 0.020),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Text(
                          'Kérlek írd be az adataidat a folytatáshoz.',
                          style: TextStyle(
                            color: const Color(0xFF565656),
                            fontSize: MediaQuery.of(context).size.width * 0.045,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.width * 0.47),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 59),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                              labelText: 'Felhasználónév',
                              labelStyle: TextStyle(
                                // Add this to set the label font style
                                color: Colors.black,
                                fontFamily:
                                    'Montserrat', // Replace with the desired font family
                                fontSize:
                                    14.0, // Replace with the desired font size
                                fontWeight: FontWeight
                                    .w700, // Replace with the desired font weight
                              ),
                              border: UnderlineInputBorder(),
                              focusColor: Colors.black,
                              hoverColor: Colors.black,
                              fillColor: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Jelszó',
                            labelStyle: TextStyle(
                              // Add this to set the label font style
                              color: Colors.black,
                              fontFamily:
                                  'Montserrat', // Replace with the desired font family
                              fontSize:
                                  14.0, // Replace with the desired font size
                              fontWeight: FontWeight
                                  .w700, // Replace with the desired font weight
                            ),
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width * 0.1),
                      ElevatedButton(
                        onPressed: () {
                          login();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          elevation: 3,
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width *
                              0.32, // This makes the button take up the available width
                          child: const Center(
                            child: Text(
                              'Folytatás',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      SizedBox(
                        child: Text(
                          'Elfelejtetted a jelszavad?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF6B6B6B),
                            fontSize: MediaQuery.of(context).size.width *
                                0.035, // Adjust the multiplier as needed
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            height: 0,
                          ),
                        ),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.004),
                      SizedBox(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Nincs még fiókod? ',
                                style: TextStyle(
                                  color: const Color(0xFF6B6B6B),
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.035, // Adjust the multiplier as needed
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w300,
                                  height: 0,
                                ),
                              ),
                              TextSpan(
                                text: 'Hozz létre egyet!',
                                style: TextStyle(
                                  color: const Color(0xFF6B6B6B),
                                  fontSize: MediaQuery.of(context).size.width *
                                      0.035, // Adjust the multiplier as needed
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  height: 0,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

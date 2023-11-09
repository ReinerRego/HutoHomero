import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hutohomero/home.dart';
import 'package:hutohomero/main.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  Future<void> register() async {
    final String url = 'http://51.20.165.73:5000/register';
    final Map<String, dynamic> data = {
      'username': usernameController.text,
      'password': passwordController.text,
      'email': emailController.text,
    };

    final String jsonData = json.encode(data);
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(emailController.text);
    print(emailValid);
    final response = await http.post(
      Uri.parse(url),
      body: jsonData,
      headers: {'Content-Type': 'application/json'},
    );

    print('Response body: ${response.body}');
    print('statusCode: ${response.statusCode}');
    final responseData = json.decode(response.body);
    final status = responseData['status'];

    if (response.statusCode == 201) {
      // Save register details to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('username', usernameController.text);
      prefs.setString('password', passwordController.text);

      runApp(const MyApp());
    }
    if (response.statusCode == 400) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hiba!'),
            content: const Text('Ez a felhasználónév már foglalt.'),
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
            content: const Text('Ismeretlen hiba történt!'),
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
             <svg width="422" height="530" viewBox="0 0 422 530" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M270.376 257.475C271.448 248.466 272 239.298 272 230C272 102.975 169.025 0 42 0C-85.0255 0 -188 102.975 -188 230C-188 341.492 -108.67 434.456 -3.37593 455.525C-4.44833 464.534 -5 473.702 -5 483C-5 610.026 97.9745 713 225 713C352.026 713 455 610.026 455 483C455 371.508 375.67 278.544 270.376 257.475Z" fill="url(#paint0_linear_35_3)"/>
  <defs>
    <linearGradient id="paint0_linear_35_3" x1="133.5" y1="0" x2="133.5" y2="713" gradientUnits="userSpaceOnUse">
      <stop stop-color="#C9FFD5" stop-opacity="0.812874"/>
      <stop offset="0.666667" stop-color="#D7FFE2" stop-opacity="0.276174"/>
      <stop offset="1" stop-color="#F2FFD7" stop-opacity="0"/>
    </linearGradient>
  </defs>
</svg>
              ''',
                width: MediaQuery.of(context).size.width * 1,
                alignment: Alignment.bottomLeft,
                fit: BoxFit.none),
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
                          'Üdvözlünk!',
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
                SizedBox(height: MediaQuery.of(context).size.width * 0.37),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 59),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: emailController,
                          obscureText: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
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
                      const SizedBox(height: 20),
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
                      SizedBox(
                          height: MediaQuery.of(context).size.width * 0.27),
                      ElevatedButton(
                        onPressed: () {
                          register();
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
                              0.60, // This makes the button take up the available width
                          child: const Center(
                            child: Text(
                              'Regisztrálás & Folytatás',
                              style: TextStyle(
                                fontSize: 18,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
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

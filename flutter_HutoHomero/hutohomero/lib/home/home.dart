// ignore_for_file: use_build_context_synchronously, prefer_function_declarations_over_variables
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:list_picker/list_picker.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

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
  List<String> ipList = [];
  List<String> wifiNetworks = [];
  String selectedWifi = "";

  Future<void> _startWifiScan(BuildContext context) async {
    final canStartScan = await WiFiScan.instance.canStartScan();
    if (canStartScan == CanStartScan.yes) {
      final result = await WiFiScan.instance.startScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Wi-Fi scan started: $result"),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot start Wi-Fi scan: $canStartScan"),
        ),
      );
    }
  }

  Future<void> _printWifiNetworks(BuildContext context) async {
    final canGetScannedResults = await WiFiScan.instance.canGetScannedResults();
    if (canGetScannedResults == CanGetScannedResults.yes) {
      final results = await WiFiScan.instance.getScannedResults();
      print("Scanned Wi-Fi networks:");
      for (final network in results) {
        print("${network.ssid} - ${network.level} dBm");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Scanned Wi-Fi networks printed to terminal"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Cannot get scanned Wi-Fi results: $canGetScannedResults"),
        ),
      );
    }
  }

  Future<void> mDNS() async {
    // Parse the command line arguments.
    var factory = (dynamic host, int port,
        {bool reuseAddress = true, bool reusePort = true, int ttl = 100}) {
      return RawDatagramSocket.bind(host, port,
          reuseAddress: true, reusePort: false, ttl: 100);
    };

    var client = MDnsClient(rawDatagramSocketFactory: factory);

    const String name = '_hutohomero._tcp.local';
    // Start the client with default options.
    await client.start();

    // Get the PTR record for the service.
    await for (final PtrResourceRecord ptr in client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      await for (final SrvResourceRecord srv
          in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName))) {
        final String bundleId = ptr.domainName;
        print('Dart observatory instance found at '
            '${srv.target}:${srv.port}:${srv.name} for "$bundleId".');

        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv4(srv.target))) {
          print('IP: ${ip.address.address}');
          if (!ipList.contains(ip.address.address)) {
            ipList.add(ip.address.address);
          }
        }
      }
    }
    client.stop();

    print('Done.');
    for (String instanceInfo in ipList) {
      print(instanceInfo);
      fetchData(instanceInfo);
    }
  }

  Future<String> checkAvailability() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.4.1/available'));
      if (response.statusCode == 200) {
        await _startWifiScan(context);
        final responseData = json.decode(response.body);
        return responseData['available'];
      }
    } catch (e) {
      print('Error checking availability: $e');
    }
    return 'no';
  }

  bool _isDialogShowing = false;
  bool _pressedCancel = false;
  String wifiString = "";
  Future<void> showInputDialog(BuildContext context) async {
    _isDialogShowing = true;
    final prefs = await SharedPreferences.getInstance();
    const String url = 'http://192.168.4.1/setup';

    final String? savedUsername = prefs.getString('username');
    final String? savedPassword = prefs.getString('password');
    String selectedWifi = "";
    showDialog(
      barrierDismissible: false,
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
                title: const Text(
                  'Hűtőhőmérő beállításai',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        ListPickerField(
                          label: "WiFi hálózat",
                          items: wifiNetworks,
                          controller: ssidController,
                        ),
                        TextField(
                          controller: wifiPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'WiFi jelszó',
                            contentPadding: EdgeInsets.all(
                                10.0), // Adjust the padding as needed
                          ),
                        ),
                        TextField(
                          controller: postDelayController,
                          decoration: const InputDecoration(
                            labelText: 'Feltöltések közötti idő (ms)',
                            contentPadding: EdgeInsets.all(
                                10.0), // Adjust the padding as needed
                          ),
                        ),
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Eszköz neve',
                            contentPadding: EdgeInsets.all(
                                10.0), // Adjust the padding as needed
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _isDialogShowing = false;
                      _pressedCancel = true;
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Mégse',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _isDialogShowing = false;
                      Navigator.of(context).pop();
                      Navigator.pop(context);
                      sendRequest();
                    },
                    child: const Text(
                      'Mentés',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text('Adatok elküldése'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 23.0),
            ],
          ),
        );
      },
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      const String url = 'http://192.168.4.1/setup';
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
        'identifier': locationController.text
      };

      final String jsonData = json.encode(data);

      // Print the JSON data
      print('JSON Data: $jsonData');

      final response = await http.post(
        Uri.parse(url),
        body: jsonData,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Handle successful response
        print('Request successful');
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Adatátvétel sikeres!'),
              content: const Text('Sikeresen átküldtük az adatokat.'),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Handle error
        print('Request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle errors
      print('Error: $e');

      // Close the loading dialog
      Navigator.pop(context);

      // Show an error dialog or handle errors as needed
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Hiba'),
            content: Text('Egy hiba történt!: $e'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
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

  String _latestWifiSSID = "";
  Future<void> _getWifiName(BuildContext context) async {
    try {
      final info = NetworkInfo();
      String? wifiName = await info.getWifiName();
      if (wifiName != null && !wifiName.contains("CharterHutohomero")) {
        _latestWifiSSID = wifiName;
      }
      if (wifiName != null &&
          wifiName.contains("CharterHutohomero") &&
          _isDialogShowing != true &&
          _latestWifiSSID != wifiName) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            _isDialogShowing = true;
            return AlertDialog(
              title: const Text("Találtunk egy eszközt!"),
              content: const Text('Szeretnéd beállítani?'),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    _isDialogShowing = false;
                    _pressedCancel = true;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Nem, később'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _isDialogShowing = true;
                    Navigator.of(context).pop();
                    showInputDialog(context);
                  },
                  child: const Text('Eszköz beállítása'),
                ),
              ],
            );
          },
        );
        final wifiList = await WiFiScan.instance.getScannedResults();
        setState(() {
          wifiNetworks = wifiList
              .where((network) => !network.ssid.startsWith("CharterHutohomero"))
              .map((network) => network.ssid)
              .toList();
        });
        _latestWifiSSID = wifiName;
      }
    } catch (e) {
      print("Error getting WiFi name: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    // Run getWifiName every 2 seconds
    Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      _getWifiName(context);
    });
  }

  Future<void> fetchData(String ipAddress) async {
    final response = await http.get(Uri.parse('http://$ipAddress/info'));
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the data
      final data = jsonDecode(response.body);
      print('Data from $ipAddress: $data');
    } else {
      // If the server did not return a 200 OK response,
      // print an error message.
      print('Failed to load data from $ipAddress');
    }
  }

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        shadowColor: const Color.fromARGB(0, 143, 143, 143),
        elevation: 4,
        title: Image.asset('assets/snowflake.png', height: 40),
        backgroundColor: const Color.fromARGB(255, 137, 251, 255),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: mDNS,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ... existing code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async => _startWifiScan(context),
                  child: const Text('Start Wi-Fi Scan'),
                ),
                ElevatedButton(
                  onPressed: () async => _printWifiNetworks(context),
                  child: const Text('Print Wi-Fi Networks'),
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 137, 251, 255),
              ),
              accountName: const Text(
                'Rego',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
              accountEmail: const Text(
                "regokoppany@gmail.com",
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.black),
              ),
              currentAccountPicture:
                  Image.asset('assets/usericon.png', height: 10),
            ),
            ListTile(
              title: const Stack(
                children: <Widget>[
                  Icon(Icons
                      .add_circle), // Wrap Icons.add_circle with Icon widget
                  Center(
                    child: Text(
                      "Eszköz beállítása",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                showInputDialog(context);
              },
            ),
            ListTile(
              title: const Stack(
                children: <Widget>[
                  Icon(Icons
                      .refresh_rounded), // Wrap Icons.add_circle with Icon widget
                  Center(
                    child: Text(
                      "Eszközök keresése",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                mDNS();
              },
            ),
            ListTile(
              title: const Stack(
                children: <Widget>[
                  Icon(Icons
                      .logout_rounded), // Wrap Icons.add_circle with Icon widget
                  Center(
                    child: Text(
                      "Kijelentkezés",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 17.0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              onTap: () {
                clearSavedCredentials();
              },
            ),
            // Add more ListTile widgets for additional drawer items
          ],
        ),
      ),
    );
  }
}

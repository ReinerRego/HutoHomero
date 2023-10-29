#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include <Hash.h>
#include <ESP8266mDNS.h>

const char *defaultUsername = "defaultUser";
const char *defaultPassword = "defaultPassword";
const char *defaultSSID = "defaultSSID";
const char *defaultWiFiPassword = "defaultWiFiPassword";
String accessToken = "0";
int defaultPostDelay = 0;
String macStr = "default";
String macSHA1 = "default";
int previousMillis = 0;    // Store the last time a task was executed

String hostnamePrefix = "CharterHutohomero-";
String combinedHostname = "default";
const char *serverAddress = "192.168.0.11";
ESP8266WebServer server(80);

bool loadSettings(char *data);
void saveSettings(const char *username, const char *password, const char *ssid, const char *wifiPassword, int postDelay);
void handleReset();
void handleSetup();
void setupMode();
void factoryReset();
float readTemperature();
String login(const char *username, const char *password);
void postData();

void setup()
{
  macStr = WiFi.macAddress();
  macSHA1 = sha1(macStr);
  combinedHostname = hostnamePrefix + macSHA1.substring(0, 8).c_str();

  LittleFS.begin();
  Serial.begin(115200);
  Serial.println(combinedHostname);
  // Load the settings from the config file
  char configFileData[512]; // Adjust the size as needed
  if (loadSettings(configFileData))
  {
    DynamicJsonDocument jsonDoc(512);
    DeserializationError error = deserializeJson(jsonDoc, configFileData);

    if (!error)
    {
      const char *ssid = jsonDoc["ssid"] | defaultSSID;
      const char *wifiPassword = jsonDoc["wifiPassword"] | defaultWiFiPassword;
      defaultUsername = jsonDoc["username"];
      defaultPassword = jsonDoc["password"];
      defaultPostDelay = jsonDoc["postDelay"];
      // Try connecting to Wi-Fi with the loaded credentials
      WiFi.mode(WIFI_STA);
      WiFi.hostname(combinedHostname);
      WiFi.begin(ssid, wifiPassword);
      while (WiFi.status() != WL_CONNECTED)
      {
        delay(1000);
        Serial.println("Connecting to WiFi...");
      }
      Serial.println("Connected to WiFi");

      if (MDNS.begin(combinedHostname))
      {
        Serial.println("mDNS responder started");
      }
      else
      {
        Serial.println("Error setting up mDNS responder");
      }

      delay(1000);
      String tempAccessToken = login(defaultUsername, defaultPassword);
      while (tempAccessToken == "102" || tempAccessToken == "103" || tempAccessToken == "104")
      {
        tempAccessToken = login(defaultUsername, defaultPassword);
        delay(5000);
      }
      accessToken = tempAccessToken;
    }
  }
  else
  {
    // If the settings file couldn't be loaded, enter "setup mode" and create an AP
    Serial.println("Failed to load settings. Entering setup mode.");

    // Add the server.on for "/setup" route
    server.on("/setup", HTTP_POST, handleSetup);
    setupMode();
  }

  server.on("/reset", HTTP_GET, handleReset);
  server.on("/factoryReset", HTTP_GET, factoryReset);

  server.begin();
  delay(1000);
}

void loop()
{
  server.handleClient();
  if (strcmp(defaultUsername, "defaultUser") != 0)
  {
    int currentMillis = millis(); // Get the current time
    if (currentMillis - previousMillis >= defaultPostDelay)
    {
      postData();
      previousMillis = currentMillis;
    }
  }
}
void setupMode()
{
  const char *apSsid = combinedHostname.c_str();
  Serial.println(apSsid);
  WiFi.softAP(apSsid);
  Serial.println("Access Point (AP) mode. Connect to the AP to configure settings.");

  WiFiClient client;
  while (!client && WiFi.status() == WL_CONNECTED)
  {
    // Wait for a client to connect and send the setup data
    client = server.client();
    delay(1000); // Adjust the delay as needed
  }

  if (client)
  {
    // A client is connected; handle the setup data
    while (client.connected())
    {
      if (client.available())
      {
        server.handleClient();
      }
    }

    // Handle the setup data and save settings
    DynamicJsonDocument jsonDoc(512);
    DeserializationError error = deserializeJson(jsonDoc, server.arg("plain"));

    if (!error)
    {
      const char *username = jsonDoc["username"] | defaultUsername;
      const char *password = jsonDoc["password"] | defaultPassword;
      const char *ssid = jsonDoc["ssid"] | defaultSSID;
      const char *wifiPassword = jsonDoc["wifiPassword"] | defaultWiFiPassword;
      int postDelay = jsonDoc["postDelay"] | defaultPostDelay;

      // Save the settings to LittleFS
      saveSettings(username, password, ssid, wifiPassword, postDelay);

      // Send a success response
      server.send(200, "text/plain", "Settings saved successfully. Rebooting...");
      Serial.println("Settings saved successfully. Rebooting...");
      delay(1000);
      ESP.restart();
    }
    else
    {
      server.send(400, "text/plain", "Failed to parse JSON");
    }
  }
}

float readTemperature()
{
  const int numReadings = 1500;
  float sum = 0;

  for (int i = 0; i < numReadings; i++)
  {
    float analogValue = analogRead(A0);
    float millivolts = (analogValue / 1024.0) * 3300;
    float celsius = millivolts / 10 - 5;
    sum += celsius;
    delay(1);
  }

  // Calculate the average temperature.
  float averageTemperature = sum / numReadings;
  return averageTemperature;
}

void handleSetup()
{
  // Handle the JSON setup data and save settings
  DynamicJsonDocument jsonDoc(512);
  DeserializationError error = deserializeJson(jsonDoc, server.arg("plain"));

  if (!error)
  {
    const char *username = jsonDoc["username"] | defaultUsername;
    const char *password = jsonDoc["password"] | defaultPassword;
    const char *ssid = jsonDoc["ssid"] | defaultSSID;
    const char *wifiPassword = jsonDoc["wifiPassword"] | defaultWiFiPassword;
    int postDelay = jsonDoc["postDelay"] | defaultPostDelay;

    // Save the settings to LittleFS
    saveSettings(username, password, ssid, wifiPassword, postDelay);

    // Send a success response
    server.send(200, "text/plain", "Settings saved successfully. Rebooting...");
    Serial.println("Settings saved successfully. Rebooting...");
    delay(300);
    ESP.restart();
  }
  else
  {
    server.send(400, "text/plain", "Failed to parse JSON");
  }
}

void handleReset()
{
  // Handle the reset logic
  Serial.println("Restarting...");
  delay(1000);
  ESP.restart();
}

bool loadSettings(char *data)
{
  File configFile = LittleFS.open("/config.txt", "r");
  if (configFile)
  {
    int bytesRead = configFile.readBytes(data, 512); // Adjust the size as needed
    configFile.close();
    data[bytesRead] = '\0'; // Null-terminate the data
    return true;
  }
  return false;
}
void factoryReset()
{
  // Delete all files in / directory
  Dir dir = LittleFS.openDir("/");
  while (dir.next())
  {
    String pathStr = "/" + dir.fileName();
    if (pathStr != "/")
    {
      LittleFS.remove(pathStr);
    }
  }
  server.send(200, "text/plain", "Factory reset was successful. Rebooting...");
  Serial.println("Factory reset was successful. Rebooting...");
  delay(1000);
  ESP.restart();
}
void saveSettings(const char *username, const char *password, const char *ssid, const char *wifiPassword, int postDelay)
{
  File configFile = LittleFS.open("/config.txt", "w");
  if (configFile)
  {
    DynamicJsonDocument jsonDoc(512);
    jsonDoc["username"] = username;
    jsonDoc["password"] = password;
    jsonDoc["ssid"] = ssid;
    jsonDoc["wifiPassword"] = wifiPassword;
    jsonDoc["postDelay"] = postDelay;

    serializeJson(jsonDoc, configFile);
    configFile.close();
  }
}

String login(const char *username, const char *password)
{
  WiFiClient client;
  String tempAccessToken = "";

  DynamicJsonDocument doc(128);
  doc["username"] = username;
  doc["password"] = password;

  Serial.println("Logging in..");
  Serial.print("Username: ");
  Serial.println(defaultUsername);
  Serial.print("Password: ");
  Serial.println(defaultPassword);

  String jsonData;
  serializeJson(doc, jsonData);

  // Send the JSON data to the server
  HTTPClient http;
  http.begin(client, serverAddress, 5000, "/login");

  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(jsonData);

  if (httpCode > 0)
  {
    String payload = http.getString();
    Serial.println("HTTP Response Code: " + String(httpCode));
    Serial.println("Response Data: " + payload);

    // Parse the JSON response to extract the access_token
    DynamicJsonDocument responseDoc(128);
    DeserializationError error = deserializeJson(responseDoc, payload);
    if (!error)
    {
      if (responseDoc["status"].as<String>() == "invalidLogin")
      {
        return "104";
      }
      else
      {
        tempAccessToken = responseDoc["access_token"].as<String>();
        return tempAccessToken;
      }
    }
    else
    {
      Serial.println("Failed to parse JSON response");
      return "103";
    }
  }
  else
  {
    Serial.println("HTTP request failed");
    return "102";
  }

  http.end();
}
void postData()
{
  WiFiClient client;
  DynamicJsonDocument doc(1024);
  doc["humidity"] = String(0);
  doc["temperature"] = String(readTemperature());
  doc["pressure"] = String(0);
  doc["location"] = "default";
  doc["access_token"] = accessToken;

  Serial.println("Posting data..");

  String jsonData;
  serializeJson(doc, jsonData);
  Serial.println(jsonData);

  // Send the JSON data to the server
  HTTPClient http;
  http.begin(client, serverAddress, 5000, "/postData");

  http.addHeader("Content-Type", "application/json");
  int httpCode = http.POST(jsonData);

  if (httpCode > 0)
  {
    String payload = http.getString();
    Serial.println("HTTP Response Code: " + String(httpCode));
    Serial.println("Response Data: " + payload);

    // Parse the JSON response to extract the access_token
    DynamicJsonDocument responseDoc(128);
    DeserializationError error = deserializeJson(responseDoc, payload);
    if (!error)
    {
      Serial.println("Posted!");
    }
    else
    {
      Serial.println("Failed to parse JSON response");
    }
  }
  else
  {
    Serial.println("HTTP request failed");
  }

  http.end();
}
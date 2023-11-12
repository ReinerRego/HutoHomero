#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <ESP8266HTTPClient.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include <Hash.h>
#include <ESP8266mDNS.h>
#include <SPI.h>
#include <Wire.h>
#include "SSD1306Wire.h"
#include "fonts.h"
#include "images.h"
#define SCREEN_WIDTH 128    // OLED display width, in pixels
#define SCREEN_HEIGHT 64    // OLED display height, in pixels
#define OLED_RESET -1       // Reset pin not used
#define SCREEN_ADDRESS 0x3C // I2C address of the OLED screen

SSD1306Wire display(0x3C, SDA, SCL);

const char *defaultUsername = "defaultUser";
const char *defaultPassword = "defaultPassword";
const char *defaultSSID = "defaultSSID";
const char *defaultWiFiPassword = "defaultWiFiPassword";
const char *defaultLocation = "default";
String accessToken = "0";
int defaultPostDelay = 0;
String macStr = "default";
String macSHA1 = "default";
int previousMillis = 0;
int previousMillis2 = 0;
int lastProgress = 0;
String hostnamePrefix = "CharterHutohomero-";
String combinedHostname = "default";
const char *serverAddress = "51.20.165.73";
ESP8266WebServer server(80);
int waitingTime = 30;
float lastTemp = 0;
const char* version = "V1.0";
const char* defaultIdentifier = "defaultIdentifier";

bool loadSettings(char *data);
void saveSettings(const char *username, const char *password, const char *ssid, const char *wifiPassword, int postDelay, const char* identifier);
void handleReset();
void handleSetup();
void setupMode();
void factoryReset();
void available();
float readTemperature();
String login(const char *username, const char *password);
void postData();
void drawProgress(int progress, String topMessage, String message);
void info();

void setup()
{
  Serial.begin(115200);
  display.init();
  display.mirrorScreen();
  display.flipScreenVertically();
  display.setTextAlignment(TEXT_ALIGN_CENTER);
  display.setFont(Roboto_12);
  display.drawString(64, 0, "Charter HH ");
  drawProgress(1, "Charter HH", "");
  display.display();
  macStr = WiFi.macAddress();
  macSHA1 = sha1(macStr);
  combinedHostname = hostnamePrefix + macSHA1.substring(0, 8).c_str();

  LittleFS.begin();
  drawProgress(16, "Charter HH", "Fajlrendszer inditasa...");
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
      defaultIdentifier = jsonDoc["identifier"];
      Serial.println(defaultPostDelay);
      WiFi.mode(WIFI_STA);
      WiFi.hostname(combinedHostname);
      WiFi.begin(ssid, wifiPassword);
      drawProgress(32, "Charter HH", "WiFi-hez csatlakozas...");
      while (WiFi.status() != WL_CONNECTED)
      {
        Serial.println("Connecting to WiFi...");
      }
      Serial.println("Connected to WiFi");
      drawProgress(48, "Charter HH", "WiFi-hez csatlakozva!");
      if (MDNS.begin(combinedHostname))
      {
        Serial.println("mDNS responder started");
        MDNS.addService("hutohomero", "tcp", 80);
      }
      else
      {
        Serial.println("Error setting up mDNS responder");
        drawProgress(64, "Charter HH", "mDNS hiba!");

        while (true)
        {
          ESP.wdtFeed();
        }
      }
      drawProgress(80, "Charter HH", "Bejelentkezes...");
      String tempAccessToken = login(defaultUsername, defaultPassword);
      while (tempAccessToken == "102" || tempAccessToken == "103" || tempAccessToken == "104")
      {
        tempAccessToken = login(defaultUsername, defaultPassword);
      }
      accessToken = tempAccessToken;
    }
    drawProgress(90, "Charter HH", "Bejelentkezve!");
  }
  else
  {
    // If the settings file couldn't be loaded, enter "setup mode" and create an AP
    Serial.println("Failed to load settings. Entering setup mode.");

    // Add the server.on for "/setup" route
    server.on("/setup", HTTP_POST, handleSetup);
    drawProgress(100, "Charter HH", "Folytassa az alkalmazasban!");
    setupMode();
  }

  server.on("/reset", HTTP_GET, handleReset);
  server.on("/factoryReset", HTTP_GET, factoryReset);
  server.on("/available", HTTP_GET, available);
  server.on("/info", HTTP_GET, info);

  server.begin();
  if (strcmp(defaultUsername, "defaultUser") != 0)
  {
    delay(1000);
    drawProgress(100, "Charter HH", "Kesz!");
    delay(1000);
    display.clear();
    display.display();
  }

  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

  readTemperature();
}

void loop()
{
  if (strcmp(defaultUsername, "defaultUser") != 0)
  {
    MDNS.update();
    int currentMillis2 = millis(); // Get the current time
    if (currentMillis2 - previousMillis2 >= waitingTime)
    {
      display.normalDisplay();
      display.clear();
      display.drawXbm(0, -1, 128, 64, image_data_wifiConnected);
      display.setFont(Roboto_10);
      macStr = WiFi.macAddress();
      macSHA1 = sha1(macStr);
      macSHA1 = macSHA1.substring(0, 8).c_str();
      display.drawString(104, 1, macSHA1);
      display.drawLine(3, 15, 125, 15);
      display.setFont(Open_Sans_SemiBold_27);
      int widht = 64;
      float temperatureFloat = readTemperature();
      display.drawString(widht, 20, String(temperatureFloat).substring(0, 4) + "C");
      int widht2 = display.getStringWidth(String(temperatureFloat).substring(0, 4) + "C");
      display.drawCircle((widht + widht2 / 2) + 6, 30, 2);
      display.drawCircle((widht + widht2 / 2) + 6, 30, 3);
      lastTemp = temperatureFloat;
      display.display();
      previousMillis2 = currentMillis2;
      waitingTime = 30000;
    }
    int currentMillis = millis(); // Get the current time
    if (currentMillis - previousMillis >= defaultPostDelay)
    {
      MDNS.update();
      postData();
      previousMillis = currentMillis;
    }
    bool inverted = false;
    while (WiFi.status() != WL_CONNECTED)
    {
      delay(1000);
      display.clear();
      display.drawXbm(0, -1, 128, 64, image_data_wifiConnected);
      display.setFont(Roboto_10);
      macStr = WiFi.macAddress();
      macSHA1 = sha1(macStr);
      macSHA1 = macSHA1.substring(0, 8).c_str();
      display.drawString(104, 1, macSHA1);
      display.drawLine(3, 15, 125, 15);
      display.setFont(Roboto_16);
      display.drawString(64, 20, "Nincs WiFi jel!");
      display.setFont(Roboto_12);
      display.drawString(64, 40, "Ujraprobalkozas...");
      if (inverted)
      {
        display.normalDisplay();
        inverted = false;
      }
      else
      {
        display.invertDisplay();
        inverted = true;
      }
      display.display();
    }
  }
  server.handleClient();
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
    Serial.println(server.arg("plain"));
    if (!error)
    {
      const char *username = jsonDoc["username"] | defaultUsername;
      const char *password = jsonDoc["password"] | defaultPassword;
      const char *ssid = jsonDoc["ssid"] | defaultSSID;
      const char *wifiPassword = jsonDoc["wifiPassword"] | defaultWiFiPassword;
      Serial.println(String(jsonDoc["postDelay"]));
      Serial.println(String(jsonDoc["ssid"]));
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
  const int numReadings = 1200;
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
    Serial.println(defaultLocation);
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
void saveSettings(const char *username, const char *password, const char *ssid, const char *wifiPassword, int postDelay, const char* identifier)
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
    jsonDoc["postDelay"] = identifier;
    Serial.println("savesettings ");
    Serial.println(postDelay);

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
      Serial.println("Failusernameed to parse JSON response");
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
  doc["location"] = "defaultLocation";
  Serial.println(defaultLocation);
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

const int progressValueMax = 100;
const int animationInterval = 100; // Adjust as needed

void drawProgress(int progressValue, String topMessage, String message)
{
  if (progressValue < 0 || progressValue > 100)
  {
    return; // Ensure progressValue is within a valid range
  }
  display.clear();
  display.setFont(Roboto_10);
  display.drawString(64, 23, message);
  Serial.println(message);
  display.setFont(Roboto_12);
  display.drawString(64, 0, topMessage);
  for (int progress = lastProgress; progress <= progressValue; progress++)
  {
    int delayValue = map(progress, lastProgress, progressValue, 1, 400);
    display.drawProgressBar(14, 43, 102, 14, progress);
    display.display();
    lastProgress = progress;
    delay(delayValue);
  }
}

void available()
{
  DynamicJsonDocument doc(256);
  doc["available"] = "yes";

  String jsonData;
  serializeJson(doc, jsonData);
  Serial.println(jsonData);

  server.send(200, "text/plain", jsonData);
}

void info()
{
  DynamicJsonDocument doc(256);
  doc["username"] = defaultUsername;
  doc["lastTemp"] = lastTemp;
  doc["identifier"] = defaultIdentifier;
  doc["uptime"] = String(millis());
  doc["version"] = version;
  String jsonData;
  serializeJson(doc, jsonData);
  Serial.println(jsonData);

  server.send(200, "text/plain", jsonData);
}
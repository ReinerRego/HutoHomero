#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ArduinoJson.h>
#include <Adafruit_NeoPixel.h>

#define ledPin D2

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(1, ledPin, NEO_GRB + NEO_KHZ800);

const char* ssid = "GalaktikusKapu";
const char* password = "Jelszo1234";
const char* serverIP = "192.168.0.11";
const int serverPort = 80;

const char* apiKey = "2023ESPCHARTER";

void setup() {
  pixels.begin();  // This initializes the NeoPixel library.

  Serial.begin(115200);
  WiFi.begin(ssid, password);
  WiFi.setAutoReconnect(true);

  Serial.println("\n");
  Serial.println("\n");
  Serial.println("Connecting...");
  Serial.println("");

  for (int i = 0; i <= 5; i++) {
    setColor(0, 0, 255, 0, 100);
    delay(300);
    setColor(0, 0, 0, 0, 100);
    delay(300);
  }

  while (WiFi.status() != WL_CONNECTED) {
    for (int i = 3; i <= 100; i++) {
      setColor(0, 138, 43, 226, i);
      delay(10);
    }

    for (int i = 100; i >= 3; i--) {
      setColor(0, 138, 43, 226, i);
      delay(10);
    }0
  }

  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());

  for (int i = 3; i >= 0; i--) {
    setColor(0, 138, 43, 226, i);
    delay(10);
  }
  delay(300);
  for (int i = 0; i <= 100; i++) {
    setColor(0, 0, 191, 255, i);
    delay(36);
  }
}

void loop() {
  // Generate random sensor data
  float temperature = random(20, 30);  // Random temperature between 20 and 30
  float humidity = random(40, 60);     // Random humidity between 40 and 60
  float pressure = random(950, 1050);  // Random pressure between 950 and 1050

  // Send the POST request
  WiFiClient client;
  if (client.connect(serverIP, serverPort)) {
    String payload = "api_key=" + String(apiKey) + "&sensor_name=Sensor1" + "&location=Living Room" + "&temperature=" + String(temperature) + "&humidity=" + String(humidity) + "&pressure=" + String(pressure);

    Serial.println("Sending POST request...");
    client.println("POST /insert_data.php HTTP/1.1");
    client.println("Host: " + String(serverIP));
    client.println("Connection: close");
    client.println("Content-Type: application/x-www-form-urlencoded");
    client.println("Content-Length: " + String(payload.length()));
    client.println();
    client.println(payload);

    // Read and print the response
    String response;
    while (client.available()) {
      response = client.readStringUntil('\r');
      Serial.print(response);
    }
    Serial.println();
    Serial.println("Request completed.");
    client.stop();

    // Check if the response contains "Error"
    if (response.indexOf("Error") != -1 | response.indexOf("Invalid") != -1) {
      for (int i = 0; i <= 5; i++) {
        setColor(0, 255, 0, 0, 100);
        delay(200);
        setColor(0, 0, 0, 0, 100);
        delay(200);
      }
    }
  } else {
    Serial.println("Failed to connect to the server.");
  }

  // After a successful DB write
  setColor(0, 255, 255, 255, 100);  // Set LED color to white
  delay(100);
  setColor(0, 0, 191, 255, 100);  // Set LED color to cyan

  delay(5000);  // Wait for 5 seconds before sending the next request

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Lost connection to wifi.");
    Serial.println("Trying to reconnect...");
    while (WiFi.status() != WL_CONNECTED) {
      setColor(0, 255, 0, 0, 100);
      delay(100);
      setColor(0, 0, 0, 0, 100);
      delay(100);
      setColor(0, 255, 0, 0, 100);
      delay(100);
      setColor(0, 0, 0, 0, 100);
      delay(2000);
    }
    Serial.println("Reconnected, continuing..");
  }
}
  // Function to control the LED color and brightness
  void setColor(int pixel, uint8_t red, uint8_t green, uint8_t blue, uint8_t brightness) {
    pixels.setPixelColor(pixel, pixels.Color(red, green, blue));  // Set the color of the LED
    pixels.setBrightness(brightness);                             // Set the brightness of the LED
    pixels.show();                                                // Show the updated LED color and brightness
  }

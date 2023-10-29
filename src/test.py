import requests
import json

# Define the ESP8266 IP address and the data to send
esp8266_ip = "http://192.168.4.1/setup"
data = {
    "username": "Rego",
    "password": "Alma0116",
    "ssid": "GalaktikusKapu",
    "wifiPassword": "Jelszo1234",
    "postDelay": 300000
}

# Convert the data to JSON format
json_data = json.dumps(data)

# Set the headers for the POST request
headers = {'Content-Type': 'application/json'}

# Send the POST request to the ESP8266
response = requests.post(esp8266_ip, data=json_data, headers=headers)

# Print the response from the ESP8266
print(response.text)

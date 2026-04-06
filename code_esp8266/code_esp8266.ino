#include <ArduinoJson.h>
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include <ESP8266WebServer.h>
#include <Firebase_ESP_Client.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <EEPROM.h>

ESP8266WebServer server(80);

String deviceID = String(ESP.getChipId(), HEX);
String uid = "";

#define EEPROM_SIZE 32

// Cấu hình Firebase
#define FIREBASE_HOST "farmer-4a13c-default-rtdb.asia-southeast1.firebasedatabase.app" 
#define FIREBASE_AUTH "qthybZHKxBA0wo4xaSDXP484vbQqQ9pBy3uB6J4q" 

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// Nút Flash để reset
#define FLASH_BUTTON 0

bool shouldReset = false;
// Biến lưu dữ liệu
int t, h, l, d, ttb, toi, kho, uot, temp_tuoi;
int gettoi, getkho, getuot, method, TTBom;
unsigned long TG_cho_gui_DL = 5;
unsigned long TG_dem_gui_DL = 0;
unsigned long TG_da_dem = 0;

void saveToEEPROM(int addr, String data) {
  for (int i = 0; i < data.length(); i++) {
    EEPROM.write(addr + i, data[i]);
  }
  EEPROM.write(addr + data.length(), '\0');  // Ký tự kết thúc chuỗi
  EEPROM.commit();
}

String readFromEEPROM(int addr) {
  String data = "";
  char ch;
  for (int i = 0; i < EEPROM_SIZE; i++) {
    ch = EEPROM.read(addr + i);
    if (ch == '\0') break;
    data += ch;
  }
  return data;
}

void setupServer() {
  server.on("/setUID", HTTP_POST, handleSetUID);
  server.on("/getDeviceID", HTTP_GET, handleGetID);

  server.begin();
  Serial.println("HTTP server started");
}

void handleSetUID() {
    if (server.hasArg("plain")) {
        uid = server.arg("plain");
        saveToEEPROM(0, server.arg("plain")); // Lưu UID vào biến
        Serial.println("Received UID: " + uid);
        server.send(200, "text/plain", "UID stored successfully");
    } else {
        server.send(400, "text/plain", "No UID received");
    }
}

// Hàm xử lý gửi ESP ID về Flutter
void handleGetID() {
    server.send(200, "text/plain", deviceID);
}

void setupFirebase() {
  config.database_url = FIREBASE_HOST;
  config.signer.tokens.legacy_token = FIREBASE_AUTH; // Sử dụng Database Secret
  
  Firebase.reconnectWiFi(true);

  // Khởi tạo Firebase
  Firebase.begin(&config, &auth);
  Serial.println("Firebase initialized");
}

void setup() {
    Serial.begin(9600);
    EEPROM.begin(EEPROM_SIZE);
    WiFi.persistent(true); 
    WiFi.setAutoConnect(true);
    uid = readFromEEPROM(0);

    int retry=0, config_done=0;
    WiFi.mode(WIFI_STA);
    WiFi.begin();
    pinMode(16, OUTPUT);
    digitalWrite(16, LOW);

    // check whether WiFi connection can be established
    Serial.println("Attempt to connect to WiFi network…");
    while(WiFi.status() != WL_CONNECTED)
    {
      Serial.print(".");
      delay(500);
      if (retry++ >= 20) // timeout for connection is 10 seconds
      {
        Serial.println("“Connection timeout expired! Start SmartConfig…”");
        WiFi.beginSmartConfig();
        // forever loop: exit only when SmartConfig packets have been received
        while (true)
        {
          delay(500);
          Serial.print(".");
          if (WiFi.smartConfigDone())
          {
          Serial.println("“nSmartConfig successfully configured”");
          config_done=1;
          break; // exit from loop
          }
          toggleLED();
        }
          if (config_done==1)
          break;
      }     
    }
    digitalWrite(16, HIGH);

    while(WiFi.status() != WL_CONNECTED)
    {
      delay(50);
    }
    Serial.println("");
    WiFi.printDiag(Serial);
    Serial.println(WiFi.localIP());
    setupFirebase();
    Serial.print("Waiting for Firebase");
    int attempts = 0;
    while (!Firebase.ready()) {
      delay(500);
      Serial.print(".");
      if (fbdo.errorReason() != "") {
        Serial.println("\nFirebase error: " + fbdo.errorReason());
      }
      attempts++;
      if (attempts > 20) {
        Serial.println("\nFailed to connect to Firebase. Restarting...");
        ESP.restart();
      }
    }
    Serial.println("\nFirebase ready!");
    setupServer();
}

void loop() {
  server.handleClient();
  checkResetButton();
  if (WiFi.status() != WL_CONNECTED) {  
      Serial.println("WiFi mất kết nối, đang thử lại...");
      reconnectWiFi();    
  }
  TG_da_dem = millis() - TG_dem_gui_DL;
  if (TG_da_dem > (TG_cho_gui_DL * 1000)) {
    StaticJsonDocument<128> doc1;
    doc1["toi"] = gettoi;
    doc1["kho"] = getkho;
    doc1["uot"] = getuot;
    doc1["temp_tuoi"] = temp_tuoi;
    doc1["method"] = method;
    doc1["TTBom"] = TTBom;
    char output[128];
    serializeJson(doc1, output);
    Serial.println(output);
    TG_dem_gui_DL = millis();
  }

  if (Serial.available()) {
    String line = Serial.readStringUntil('\n');
    StaticJsonDocument<128> doc_in;
    DeserializationError error = deserializeJson(doc_in, line);
    if (error) {
      Serial.print("JSON error: ");
      Serial.println(error.c_str());
      return;
    }
    t = doc_in["t"];
    h = doc_in["h"];
    l = doc_in["l"];
    d = doc_in["d"];
    ttb = doc_in["ttb"];
    toi = doc_in["troi_Toi"];
    uot = doc_in["datUot"];
    kho = doc_in["datKho"];

    // Gửi dữ liệu lên Firebase
    sendData(t, h, l, d, ttb, toi, uot, kho);
    getControlData();
  }
}

void reconnectWiFi() {
    int retry = 0;
    WiFi.disconnect(true);
    delay(1000);
    WiFi.begin();
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(500);
        if (++retry > 120) { // Nếu sau 20 giây vẫn chưa kết nối được thì restart
            Serial.println("\nWiFi failed to reconnect.");
            ESP.restart();
        }
    }
    Serial.println("\nWiFi reconnected!");
}


void checkResetButton() {
  if (digitalRead(FLASH_BUTTON) == LOW) {
    Serial.println("Resetting WiFi and stored data...");
      WiFi.disconnect();
        for (int i = 0; i < EEPROM_SIZE; i++) {
            EEPROM.write(i, 0);  // Ghi dữ liệu 0 vào toàn bộ EEPROM
        }
        EEPROM.commit();

        Serial.println("EEPROM cleared! Restarting...");
        delay(1000);
        ESP.restart();
  }
}

void toggleLED()
{
static int pinStatus=LOW;

if (pinStatus==HIGH)
pinStatus=LOW;
else
pinStatus=HIGH;

digitalWrite(16, pinStatus);
}

void getControlData() {
  if (Firebase.ready()) {
    // Lấy giá trị của gettoi
    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/gettoi/")) {
      gettoi = fbdo.intData();
    } else {
      Serial.println("Failed to get 'gettoi': " + fbdo.errorReason());
    }

    // Lấy giá trị của getkho
    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/getkho")) {
      getkho = fbdo.intData();
    } else {
      Serial.println("Failed to get 'getkho': " + fbdo.errorReason());
    }

    // Lấy giá trị của getuot
    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/getuot")) {
      getuot = fbdo.intData();
    } else {
      Serial.println("Failed to get 'getuot': " + fbdo.errorReason());
    }

    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/gettemp")) {
      temp_tuoi = fbdo.intData();
    } else {
      Serial.println("Failed to get 'getuot': " + fbdo.errorReason());
    }

    // Lấy giá trị của method
    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/method")) {
      method = fbdo.intData();
    } else {
      Serial.println("Failed to get 'method': " + fbdo.errorReason());
    }

    // Lấy giá trị của TTBom
    if (Firebase.RTDB.getInt(&fbdo, "/controlData/"+ uid +"/"+deviceID+"/TTBom")) {
      TTBom = fbdo.intData();
    } else {
      Serial.println("Failed to get 'TTBom': " + fbdo.errorReason());
    }
  }
}


void sendData(float temp, float hum, float lux, float amDat, int ttb, int toi, int uot, int kho) {
  if (Firebase.ready()) {
    FirebaseJson json;
    json.set("temperature", temp);
    json.set("humidity", hum);
    json.set("lux", lux);
    json.set("soilMoisture", amDat);
    json.set("ttb", ttb);
    json.set("toi", toi);
    json.set("uot", uot);
    json.set("kho", kho);

    if (Firebase.RTDB.setJSON(&fbdo, "/sensorData/" + uid + "/"+deviceID, &json)) {
      Serial.println("Data sent to Firebase");
    } else {
      Serial.println("Firebase error: " + fbdo.errorReason());
    }
  }
}

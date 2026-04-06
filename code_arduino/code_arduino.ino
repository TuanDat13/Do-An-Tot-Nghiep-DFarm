
#include <DHT.h>   
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>
#include <ArduinoJson.h>

#define RX_PIN 5
#define TX_PIN 6
SoftwareSerial mySerial(RX_PIN, TX_PIN);

#define tinHieu_AS A0
#define tinHieu_doAmDat A1   
#define nguonBom 3 
#define duPhong 4
#define cd_thuCong 7

bool tt_cdTuoi = true;
unsigned long TG_moc = 0;
unsigned long TG_cho = 5000; 
// unsigned long TG_hientai;
int state1 = 0;

const int DHTPIN = 2;      
const int DHTTYPE = DHT22; 
DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27,16,2);

int doAmDat;
int anhSang;
int t;
int h;

int troi_Toi = 40;
int datKho = 40;
int datUot = 60;
int temp_tuoi = 25;

boolean trangThaiBom = 0;
boolean TTduPhong = 0;

// Biến cho timer
unsigned long thoiGianChoDocCamBien = 2000; // ==> Thời gian đọc cảm biến (s)
unsigned long thoiGianBatDauDem = 0;
// unsigned long thoiGianTroiQua = 0;

unsigned long TG_cho_gui_DL = 10000;
unsigned long TG_dem_gui_DL= 0;
// unsigned long TG_da_dem = 0;

unsigned long luuTGBOM = 0;
bool bomDangChay = false;

int method;
int TTBomServer;

void setup()
{
  pinMode(nguonBom, OUTPUT);
  pinMode(duPhong, OUTPUT);
  dieuKhienBom();
  Serial.begin(9600);
  mySerial.begin(9600);
  lcd.init();                    
  lcd.backlight();
  lcd.begin(16, 2);
  dht.begin();  
  docCamBien();
  thoiGianBatDauDem = millis();
  TG_dem_gui_DL = millis();
  lcd.clear();
  lcd.setCursor(0, 1);
  lcd.print("Vui long cho ...");
}


void loop()
{   
  int tt_nutBam = digitalRead(cd_thuCong);
  if(tt_nutBam == HIGH) {
    tt_cdTuoi = !tt_cdTuoi;
    trangThaiBom = !trangThaiBom;
  }
  // Serial.println("start loop");
    unsigned long currentMillis = millis();
    // thoiGianTroiQua = currentMillis - thoiGianBatDauDem;
    if (currentMillis - thoiGianBatDauDem > thoiGianChoDocCamBien)
    {
      thoiGianBatDauDem = currentMillis;
      // Serial.println("Doc cam bien ");
      docCamBien();
      // Serial.println("show data");
      printData();
      // Serial.println("data lcd");
      showDataLCD(); 
      // Serial.println("Doc cam bien and show data");
    }
    dieuKhienBom();
  

  if(method == 1 && tt_cdTuoi) {
    trangThaiBom = TTBomServer;
  } else if (method ==0 && tt_cdTuoi){
    autoControlPlantation();
      if (anhSang > troi_Toi || doAmDat >= datUot || t >= temp_tuoi) {
        //digitalWrite(nguonBom, HIGH);
        trangThaiBom = 0;
        // bomDangChay = false;
        // luuTGBOM = 0;
      }
  }
  //  else {
  //     autoControlPlantation();
  //     if (anhSang > troi_Toi || doAmDat >= datUot) {
  //       //digitalWrite(nguonBom, HIGH);
  //       trangThaiBom = 0;
  //       // bomDangChay = false;
  //       // luuTGBOM = 0;
  //     }
  //   }
  // TG_da_dem = millis() - TG_dem_gui_DL;
  if(currentMillis - TG_dem_gui_DL > TG_cho_gui_DL) 
  {
    TG_dem_gui_DL = currentMillis;
    StaticJsonDocument<128> doc;
    doc["t"] = t;
    doc["h"] = h;
    doc["l"] = anhSang;
    doc["d"] = doAmDat;
    doc["ttb"] = trangThaiBom;
    doc["troi_Toi"] = troi_Toi;
    doc["datUot"] = datUot;
    doc["datKho"] = datKho;
    char output[128];
    serializeJson(doc, output);
    Serial.println(output);
    // Serial.println("Sent data to serial");
  }
  // delay(1000);
  if (Serial.available()) {
    String jsonString = Serial.readStringUntil('\n');
    StaticJsonDocument<128> doc_in1;
    DeserializationError error = deserializeJson(doc_in1, jsonString);

    if (error) {
      Serial.print("deserializeJson() failed: ");
      Serial.println(error.f_str());
      return;
    }
    troi_Toi = doc_in1["toi"];
    datKho = doc_in1["kho"];
    datUot = doc_in1["uot"];
    temp_tuoi = doc_in1["temp_tuoi"];
    method = doc_in1["method"];
    TTBomServer = doc_in1["TTBom"];
    // Serial.println("Received data from serial");
  }
  // Serial.print("Free Memory: ");
  // Serial.println(freeMemory());
// Serial.println("Loop iteration complete");
delay(1000);
}

int getAnhSang(int anaPin)
{
  int anaValue = 0;
  for (int i = 0; i < 10; i++) // Đọc giá trị cảm biến 10 lần và lấy giá trị trung bình
  {
    anaValue += analogRead(anaPin);
    delay(50);
  }
  anaValue = anaValue / 10;
  anaValue = map(anaValue, 1023, 0, 0, 100);
  return anaValue;
}

int getDoAmDat(int anaPin)
{
  int i = 0;
  int anaValue = 0;
  for (i = 0; i < 10; i++)  //
  {
    anaValue += analogRead(anaPin); //Đọc giá trị cảm biến độ ẩm đất
    delay(50);   // Đợi đọc giá trị ADC
  }
  anaValue = anaValue / (i);
  anaValue = map(anaValue, 1023, 0, 0, 100); //Ít nước:0%  ==> Nhiều nước 100%
  return anaValue;
}

void docCamBien()
{ 
  // Serial.println("read Hum");     
  h = dht.readHumidity(); 
  // Serial.println("read Tem");
  t = dht.readTemperature(); 
  // Serial.println("read AS");
  anhSang = getAnhSang(tinHieu_AS); 
  // Serial.println("read DAT");        
  doAmDat = getDoAmDat(tinHieu_doAmDat);   
}

void showDataLCD(void)
{
  // TG_hientai = millis();
  unsigned long currentMillis = millis();
  if(currentMillis - TG_moc >= TG_cho) {
    TG_moc = currentMillis;

    if(state1 ==0) {
      lcd.clear();
      lcd.setCursor(0, 1);
      lcd.print(" DO.AM% = ");
  		lcd.print(h);
  		lcd.println("  % ");

  		lcd.setCursor(1, 0);
  		lcd.print(" NH.DO = ");
  		lcd.print(t);
  		lcd.println(" *C ");
      state1 = 1;
    } else if(state1 ==1) {
      lcd.clear();
      lcd.setCursor(0, 1);
      lcd.print(" AM.DAT% = ");
      lcd.print(doAmDat);
      lcd.println("  %   ");
      lcd.setCursor(1, 0);
      lcd.print("A.SANG% = ");
      lcd.print(anhSang);
      lcd.println(" %  ");
      state1 = 2;

    } else if(state1 ==2) {
      lcd.clear();
      lcd.setCursor(0, 1);
      lcd.print("  BOM.NC = ");
      lcd.print(trangThaiBom);
      lcd.println("      ");
      lcd.setCursor(1, 0);
      lcd.print("DU PHONG = ");
      lcd.print(TTduPhong);
      lcd.println("    ");
      state1 = 3;
    }
     else if(state1 ==3) {
      lcd.clear();
      lcd.setCursor(0, 1);
      lcd.print("DK.Tuoi= ");
      lcd.print(datKho);
      lcd.println(" %   ");
      lcd.setCursor(0, 0);
      lcd.print("NĐ.Tuoi= ");
      lcd.print(temp_tuoi);
      lcd.println(" nS   ");
      
      state1 = 4;
    } else if(state1 ==4) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("DK.Ngat= ");
      lcd.print(datUot);
      lcd.println(" %     ");
      lcd.setCursor(0, 1);
      lcd.print("DK.AS = ");
      lcd.print(troi_Toi);
      lcd.println(" %    ");
      state1 = 0;
    }
  }
}

void printData(void)
{
  Serial.print("Do am: ");
  Serial.print(h);
  Serial.print(" %\t");
  Serial.print("Nhiet do: ");
  Serial.print(t);
  Serial.print(" *C\t");
  Serial.print("Anh sang: ");
  Serial.print(anhSang);
  Serial.print(" %\t");
  Serial.print("Do am dat: ");
  Serial.print(doAmDat);
  Serial.println(" %");
}

void dieuKhienBom()
{
  if (trangThaiBom == 1) digitalWrite(nguonBom, LOW);
  if (trangThaiBom == 0) digitalWrite(nguonBom, HIGH);

  if (TTduPhong == 1) digitalWrite(duPhong, LOW);
  if (TTduPhong == 0) digitalWrite(duPhong, HIGH);
}

// void turnPumpOn()
// {
//   digitalWrite(nguonBom, LOW);
//   trangThaiBom = 1;
//   delay (temp_tuoi * 1000);
//   digitalWrite(nguonBom, HIGH);
//   trangThaiBom = 0;
// }

void turnPumpOn() {
  // if (!bomDangChay) {
    //digitalWrite(nguonBom, LOW);
    trangThaiBom = 1;
    // luuTGBOM = millis();
    // bomDangChay = true;
  // }
}

void autoControlPlantation()
{
  if (doAmDat <= datKho && anhSang <= troi_Toi && t <= temp_tuoi)
  {
    turnPumpOn();
  }
}
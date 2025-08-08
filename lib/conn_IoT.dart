import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:esp_smartconfig/esp_smartconfig.dart';
import 'package:wifi_info_plugin_plus/wifi_info_plugin_plus.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
import 'service_device.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProvisioningScreen extends StatefulWidget {
  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  WifiInfoWrapper? _wifiObject;
  DeviceService deviceService = DeviceService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  final bssid = TextEditingController();
  final deviceName = TextEditingController();
  String? espIp; 
  String? deviceID ;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

    Future<void> fetchDeviceID() async {
      String? id = await deviceService.getDeviceID(espIp);
      if (id != null) {
        setState(() {
          deviceID = id; // Gán giá trị deviceID vào biến
        });
      } else {
        setState(() {
          deviceID = "Không lấy được deviceID";
        });
      }
    }

    Future<void> updateUID() async {
      String uid = _auth.currentUser!.uid;
      if (uid.isNotEmpty) {
        bool success = await deviceService.setUID(espIp, uid);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cập nhật UID thành công!")),
          );
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi khi cập nhật UID")),
          );
        }
      }
    }

  Future<void> updateDeviceMethod(String uid, String? deviceID) async {
    await _dbRef.child("controlData/$uid/$deviceID").set({
      "method": 0,
      "TTBom": 0,
      "getkho": 0,
      "getuot": 0,
      "gettoi": 0,
      "gettemp":0, 
    }).then((_) {
      print("Cập nhật thành công!");
    }).catchError((error) {
      print("Lỗi: $error");
    });
  }

  Future<void> saveDeviceID(String uid, String? deviceID, String deviceName) async {
    try {
      // Tạo tham chiếu đến Collection cam bien -> Document (UID) -> Collection (deviceID)
      await _firestore
          .collection("cam bien") // Collection cam bien
          .doc(uid) // Document với UID
          .collection("device id") // Collection với deviceID
          .doc(deviceID) // Document với deviceID
          .set({
        "id": deviceID,
        "name": deviceName,
      });

      print("DeviceID đã được lưu thành công!");
    } catch (e) {
      print("Lỗi khi lưu deviceID: $e");
    }
  }


  Future<void> initPlatformState() async {
    WifiInfoWrapper? wifiObject;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      wifiObject = await WifiInfoPlugin.wifiDetails;
    } on PlatformException {}
    if (!mounted) return;

    setState(() {
      _wifiObject = wifiObject;
      ssidController.text = _wifiObject != null ? _wifiObject!.ssid.toString().replaceAll('"', '')  : "...";
      bssid.text = _wifiObject != null ? _wifiObject!.bssId.toString() : "...";
    });
  }

  Future<void> _startProvisioning() async {
    final provisioner = Provisioner.espTouch();

    provisioner.listen((response) {
      Navigator.of(context).pop(response);
    });

    provisioner.start(ProvisioningRequest.fromStrings(
      ssid: ssidController.text,
      bssid: '00:00:00:00:00:00',
      password: passwordController.text,
    ));

    ProvisioningResponse? response = await showDialog<ProvisioningResponse>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Truyền thông tin'),
          content: const Text('Bắt đầu truyền. Đợi...'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Dừng',style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );

    if(provisioner.running) {
      provisioner.stop();
    }

    if (response != null) {
      _onDeviceProvisioned(response);
    }
  }

  _onDeviceProvisioned(ProvisioningResponse response) async {
    // String uid = _auth.currentUser!.uid;
    setState(() {
      espIp = response.ipAddressText; // Lưu IP vào biến
    });

    // await fetchDeviceID(); 
    // await updateUID();
    // await updateDeviceMethod(uid, deviceID);
    // await saveDeviceID(uid, deviceID, deviceName.text);

    // if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thiết bị DFarm'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Thiết bị kết nối thành công đến mạng ${ssidController.text}.'),
              SizedBox.fromSize(size: const Size.fromHeight(20)),
              const Text('Thiết bị:'),
              Text('IP: ${espIp}'),
              // Text('DeviceID: ${deviceID}'),
              Text('BSSID: ${response.bssidText}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK',style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    String uid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black), 
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước
          },
        ),
        title: const Text(
          'Thêm thiết bị',
          style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView( // Đảm bảo nội dung nằm trong vùng hiển thị của màn hình
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Đẩy nội dung lên trên
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // const Text('Thêm thiết bị',
                // textAlign: TextAlign.center
                // ,style: TextStyle(fontSize: 25),),
                SizedBox(height: 20),
                Center(child: Icon(Icons.cell_tower, size: 50, color: Colors.green)),
                SizedBox(height: 10),
                
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Tên mạng (SSID)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                TextField(
                  cursorColor: Colors.green[300],
                  controller: ssidController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder( // Viền xám mặc định
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),

                ),
                SizedBox(height: 10,),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'BSSID',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                TextField(
                  cursorColor: Colors.green[300],
                  controller: bssid,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder( // Viền xám mặc định
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),

                ),
                SizedBox(height: 10,),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Mật khẩu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                TextField(
                  cursorColor: Colors.green[300],
                  obscureText: true,
                  controller: passwordController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder( // Viền xám mặc định
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),

                ),
                SizedBox(height: 10,),
                Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Tên thiết bị',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                TextField(
                  cursorColor: Colors.green[300],
                  controller: deviceName,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    enabledBorder: OutlineInputBorder( // Viền xám mặc định
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                  ),

                ),
                
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _startProvisioning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      overlayColor:Colors.white,
                    ),
                    child: const Text('Bắt đầu thêm'),
                  ),
                ),
                if (espIp != null) ...[
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await fetchDeviceID(); 
                        await updateUID();
                        await updateDeviceMethod(uid, deviceID);
                        await saveDeviceID(uid, deviceID, deviceName.text);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          overlayColor:Colors.white,
                        ),
                      child: const Text("Kết nối thiết bị"),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    bssid.dispose();
    deviceName.dispose();
    super.dispose();
  }
}
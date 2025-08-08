import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diary.dart';
import 'user_page.dart';
import 'test.dart';
import 'AddPlantPage.dart';
import 'EditPlantPage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';


class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  // List<Widget> get _pages => [
  //   _buildMainPage(),
  //   PlantJournalScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? "",),
  //   NotificationPage(),
  //   UserScreen(),
  // ];

  List<Widget> get _pages => [
    SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDeviceDropdown(), // Dropdown chọn thiết bị
            _sensorData == null
                ? CircularProgressIndicator(color: Colors.lightGreen)
                : _buildSensorData(Theme.of(context).colorScheme),
            _buildControlSettings(Theme.of(context).colorScheme),
          ],
        ),
      ),
    ),
    PlantJournalScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? ""),
    NotificationPage(),
    UserScreen(),
  ];


  /// Hàm xử lý khi nhấn vào tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late DatabaseReference _databaseReference;
  Map<String, dynamic>? _sensorData;
  String? selectedDeviceId; 
  List<Map<String, dynamic>> devices = []; 
  Map<String, dynamic>? _controlData, plantData;
  List<String> growthStages = [];
  String idCay = "";
  String giaiDoan = "";
  final ValueNotifier<double> _getTemp = ValueNotifier(25);
  final ValueNotifier<double> _getToi = ValueNotifier(60);
  final ValueNotifier<double> _getKho = ValueNotifier(40);
  final ValueNotifier<double> _getUot = ValueNotifier(70);
  final Map<String, String> plantStages = {
    'Germination': 'Cây mầm',
    'Seedling Stage': 'Cây con',
    'Vegetative Growth / Root or Tuber Development': 'Tăng trưởng',
    'Flowering': 'Ra hoa',
    'Pollination': 'Thụ phấn',
    'Fruit/Grain/Bulb Formation': 'Ra quả',
    'Maturation': 'Trưởng thành',
    'Harvest': 'Thu hoạch',
  };

  final Map<String, String> plantNames = {
    'Tomato': 'Cà chua',
    'Carrot': 'Cà rốt',
    'Wheat': 'Lúa mì',
    'Chilli': 'Ớt',
    'Potato': 'Khoai tây',
  };

  final Map<String, String> plantToInt = {
    'Carrot': '0',
    'Chilli': '1',
    'Potato': '2',
    'Tomato': '3',
    'Wheat': '4',
  };

  final Map<String, String> stagesToInt = {
    'Flowering': '0',
    'Fruit/Grain/Bulb Formation': '1',
    'Germination': '2',
    'Harvest': '3',
    'Maturation': '4',
    'Pollination': '5',
    'Seedling Stage': '6',
    'Vegetative Growth / Root or Tuber Development': '7',
  };

  final Map<String, String> soilToInt = {
    'Alluvial Soil': '0',
    'Black Soil': '1',
    'Chalky Soil': '2',
    'Clay Soil': '3',
    'Loam Soil': '4',
    'Red Soil': '5',
    'Sandy Soil': '6',
  };

  bool isApiRunning = false;
  String predictionResult = "Chưa có dữ liệu";
  Timer? _apiTimer;

  @override
  void initState() {
    super.initState();
    // _fetchDevices();
    _listenToDeviceChanges();
    _fetchGGrowthStages(); 
    checkServiceStatus();
  }

  Future<void> _fetchGGrowthStages() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('cay_trong_mau')
          .doc('MsPkBzB5p3YTEwlBTj8YueyHAgg2')
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          growthStages = List<String>.from(data['mau_GD'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching plant data: $e');
    }
  }

  /// Lấy danh sách thiết bị từ Firestore
  // Future<void> _fetchDevices() async {  
  //   QuerySnapshot snapshot = await FirebaseFirestore.instance
  //       .collection('cam bien')
  //       .doc(widget.uid)
  //       .collection('device id')
  //       .get();
  //     List<Map<String, dynamic>> deviceList = snapshot.docs.map((doc) {
  //     final data = doc.data() as Map<String, dynamic>?; // Ép kiểu dữ liệu về Map<String, dynamic>
  //     return {
  //       'name': data != null && data.containsKey('name') ? data['name'] : 'Thiết bị không tên',
  //       'id': doc.id,
  //       'idCay': data != null && data.containsKey('idCay') ? data['idCay'] : 'Thiết bị không tên',
  //     };
  //   }).toList();
  //   if (mounted) {
  //     setState(() {
  //       devices = deviceList;
  //       if (devices.isNotEmpty) {
  //         selectedDeviceId = devices.first['id']; // Chọn thiết bị đầu tiên mặc định
  //         _updateIDCay();
  //         _setupRealtimeListener();
  //         _setupControlListener();
  //       }
  //     });
  //   }
  // }

// Kiểm tra xem background service có đang chạy không
  Future<void> checkServiceStatus() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    setState(() {
      isApiRunning = isRunning;
    });
  }

  // Hàm gọi API
  Future<void> _callPredictionApi() async {
    final url = Uri.parse("https://dinoktd-apiwatering2.hf.space/predict/");

    Map<String, dynamic> requestData = {
      "crop_ID": int.parse(plantToInt[plantData!['ten_cay']].toString()),
      "soil_type": int.parse(soilToInt[plantData!['loai_dat']].toString()),
      "Seedling_Stage": int.parse(stagesToInt[plantData!['giai_doan']].toString()),
      "MOI": int.parse(_sensorData!['soilMoisture'].toString()),
      "temp": int.parse(_sensorData!['temperature'].toString()),
      "humidity": int.parse(_sensorData!['humidity'].toString()),
      "light": int.parse(_sensorData!['lux'].toString()),
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Kết quả từ API: $responseData");
        if(_controlData!['TTBom'] != responseData) {
          _databaseReference.update({'TTBom': responseData}).then((_) {
            setState(() {
              _controlData!['TTBom'] = responseData; // Cập nhật UI
            });
            print("Cập nhật TTBom thành công!");
          }).catchError((error) {
            print(" Lỗi khi cập nhật TTBom: $error");
          });
        }
      } else {
        print("Lỗi API: Mã lỗi ${response.statusCode}");
        setState(() {
          predictionResult = "Lỗi API: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        predictionResult = "Lỗi kết nối API: $e";
      });
    }
  }

  // Bật/Tắt API nền khi nhấn Switch
  void _toggleApiService(bool value) async {
    final service = FlutterBackgroundService();
    if (value) {
      service.startService();
    } else {
      service.invoke("stopService");
    }
    setState(() {
      isApiRunning = value;
    });
  }

  void _listenToDeviceChanges() {
    FirebaseFirestore.instance
        .collection('cam bien')
        .doc(widget.uid)
        .collection('device id')
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> deviceList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?; 
        return {
          'name': data?['name'] ?? 'Thiết bị không tên',
          'id': doc.id,
          'idCay': data?['idCay'] ?? 'Không có ID cây',
        };
      }).toList();

      if (mounted) {
        setState(() {
          devices = deviceList;
          if (devices.isNotEmpty) {
            selectedDeviceId = devices.first['id'];
            _updateIDCay();
            _setupRealtimeListener();
            _setupControlListener();
          }
        });
      }
    });
  }

  void _updateIDCay() {
    final selectedDevice = devices.firstWhere(
      (device) => device['id'] == selectedDeviceId,
      orElse: () => {'idCay': null},
    );

    setState(() {
      idCay = selectedDevice['idCay']; // Cập nhật idCay theo thiết bị đang chọn
    });
  }

  /// Lắng nghe dữ liệu từ Firebase Realtime Database
  void _setupRealtimeListener() {
    if (selectedDeviceId == null) return;
    _databaseReference = FirebaseDatabase.instance
        .ref()
        .child('sensorData')
        .child(widget.uid)
        .child(selectedDeviceId!); // Truy cập đúng thiết bị

    _databaseReference.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _sensorData = Map<String, dynamic>.from(data as Map);
        });
      } else {
        print('No data available.');
      }
    });
  }

  void _setupControlListener() {
    if (selectedDeviceId == null) return;
    
    _databaseReference = FirebaseDatabase.instance
        .ref()
        .child('controlData')
        .child(widget.uid)
        .child(selectedDeviceId!); // Truy cập đúng thiết bị

    _databaseReference.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        setState(() {
          _controlData = Map<String, dynamic>.from(data as Map);
          // final newData = Map<String, dynamic>.from(data as Map);

          _getTemp.value = (_controlData?['gettemp'] ?? 25).toDouble();
          _getToi.value = (_controlData?['gettoi'] ?? 60).toDouble();
          _getKho.value = (_controlData?['getkho'] ?? 40).toDouble();
          _getUot.value = (_controlData?['getuot'] ?? 70).toDouble();
        
        });
      } else {
        print('No control data available.');
      }
    });
  }

  Widget _buildControlSettings(ColorScheme colorScheme) {
    if (_controlData == null) {
      return CircularProgressIndicator(color: colorScheme.primary);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cài đặt tưới',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Bơm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  // SizedBox(height: 10,),
                  Text(
                    _controlData!['TTBom'] == 1 ? 'Bật' : 'Tắt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _controlData!['TTBom'] == 1 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Chế độ tưới',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // SizedBox(height: 10,),
                      SizedBox(
                        height: 20,
                        width: 45,
                        child: Transform.scale(
                          scale: 0.7,
                          child: Switch(
                            value: _controlData!['method'] == 1,
                            onChanged: (bool value) {
                              // setState(() {
                                _showConfirmDialog(value);
                              // });
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                        _controlData!['method'] == 1 ? 'Tự Động' : 'Bán Tự Động',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold, 
                          color: _controlData!['method'] == 1 ? Colors.green : Colors.blueGrey,
                          ),
                      ),
                ],
              ),
            ],
          ),
          if (_controlData!['method'] == 0) ...[
            const Divider(),
            _buildControlSlider(_getTemp, 'Nhiệt độ tưới', 0.0, 40.0),
            _buildControlSlider(_getToi, 'Ánh sáng tưới', 0.0, 100.0),
            _buildControlSlider(_getKho, 'Độ ẩm đất thấp', 0.0, 100.0),
            _buildControlSlider(_getUot, 'Độ ẩm đất cao', 0.0, 100.0),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: _showConfirmDialogBTD,
                child: Text("Cập nhật"),
                style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        overlayColor:Colors.white,
                      ),
              ),
            ),
          ] else ...[
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () => _showConfirmUDDialog(context, _controlData!['TTBom'] == 0),
                  child: Text(
                    _controlData!['TTBom'] == 1 ? 'Tắt Bơm' : 'Bật Bơm'
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ]
        ],
      ),
    );
  }

  void _showConfirmUDDialog(BuildContext context, bool isTurningOn) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bo góc hộp thoại
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Màu nền hộp thoại
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Xác nhận",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  isTurningOn 
                      ? "Bạn có chắc chắn muốn bật bơm không?" 
                      : "Bạn có chắc chắn muốn tắt bơm không?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Hủy", style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Màu theo trạng thái
                        
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed: () {
                        _updateModel(isTurningOn ? 1 : 0);
                        Navigator.pop(context);
                      },
                      child: Text("Xác nhận", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  void _updateModel(int result) async {
    final url = Uri.parse("https://dinoktd-apiwatering2.hf.space/update/"); // Thay bằng API thực tế

    // Dữ liệu mô phỏng, thay bằng dữ liệu thực tế của bạn
    Map<String, dynamic> inputData = {
      "crop_ID": int.parse(plantToInt[plantData!['ten_cay']].toString()),
      "soil_type": int.parse(soilToInt[plantData!['loai_dat']].toString()),
      "Seedling_Stage": int.parse(stagesToInt[plantData!['giai_doan']].toString()),
      "MOI": int.parse(_sensorData!['soilMoisture'].toString()),
      "temp": int.parse(_sensorData!['temperature'].toString()),
      "humidity": int.parse(_sensorData!['humidity'].toString()),
      "light": int.parse(_sensorData!['lux'].toString()),
      "result": result,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(inputData),
      );

      if (response.statusCode == 200) {
        print("Mô hình đã được cập nhật thành công!");
      } else {
        print("Lỗi cập nhật: ${response.body}");
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
    }
  }

  void _showConfirmDialog(bool newValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bo góc hộp thoại
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Màu nền hộp thoại
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Chuyển chế độ",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  newValue
                      ? "Chuyển sang chế độ tự động?"
                      : "Chuyển sang chế độ thủ công?",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng hộp thoại
                      },
                      child: Text("Hủy", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng hộp thoại
                        _updateMethod(newValue); // Cập nhật Firebase
                      },
                      child: Text("Xác nhận", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  void _updateMethod(bool value) async {
    if (_databaseReference == null || selectedDeviceId == null) return;

    final newMethod = value ? 1 : 0;

    if(value) {
      _toggleApiService(value);
      _apiTimer?.cancel(); // Dừng timer cũ nếu có
      _apiTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
        await _callPredictionApi();
      });
    }  else {
      _toggleApiService(false);

      _apiTimer?.cancel();
    }

    _databaseReference.update({'method': newMethod}).then((_) {
      setState(() {
        _controlData!['method'] = newMethod; // Cập nhật UI
      });
      print("Cập nhật method thành công!");
    }).catchError((error) {
      print(" Lỗi khi cập nhật method: $error");
    });
  }

  void _showConfirmDialogBTD() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bo góc hộp thoại
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Màu nền hộp thoại
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Thay đổi điều kiện",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "Xác nhận thay đổi điều kiện tưới?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng hộp thoại
                      },
                      child: Text("Hủy", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Đóng hộp thoại
                        _updateControlData(); // Cập nhật Firebase
                      },
                      child: Text("Xác nhận", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  void _showConfirmStageDialog(BuildContext context, String nextStage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Bo góc hộp thoại
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white, // Màu nền hộp thoại
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Chuyển giai đoạn?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  "Bạn có chắc muốn chuyển sang giai đoạn '$nextStage'?",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Hủy", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Đóng hộp thoại trước khi cập nhật

                        await FirebaseFirestore.instance
                            .collection('cay_trong')
                            .doc(widget.uid)
                            .collection('cay_trong_id')
                            .doc(idCay)
                            .update({'giai_doan': nextStage});

                        setState(() {
                          // Cập nhật giao diện nếu cần
                          // giaiDoan = nextStage;
                        });

                        print("✅ Đã chuyển sang giai đoạn: $nextStage");
                      },
                      child: Text("Xác nhận", style: TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }

  void _updateControlData() {
    if (_controlData == null || selectedDeviceId == null) return;

    final newData = {
      'gettemp': _getTemp.value.toInt(),
      'gettoi': _getToi.value.toInt(),
      'getkho': _getKho.value.toInt(),
      'getuot': _getUot.value.toInt(),
    };

    _databaseReference!.update(newData).then((_) {
      print("✅ Dữ liệu đã được cập nhật thành công!");
    }).catchError((error) {
      print("❌ Lỗi khi cập nhật dữ liệu: $error");
    });
  }

  Widget _buildControlSlider(ValueNotifier<double> valueNotifier, String label, double min, double max) {
    return ValueListenableBuilder<double>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
                TextSpan(
                  text: '$label: ', // Phần đầu văn bản (không đậm)
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blueGrey),
                  children: [
                    TextSpan(
                      text: '${value.toInt()}', // Phần số (đậm)
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              label: value.toInt().toString(),
              activeColor: Colors.green, 
              inactiveColor: Colors.grey,
              thumbColor: const Color.fromARGB(255, 232, 232, 232),
              onChanged: (newValue) {
                valueNotifier.value = newValue; // Chỉ thay đổi UI, chưa lưu vào Firebase
              },
            ),
          ],
        );
      },
    );
  }

  // Widget _buildMainPage() {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   return SingleChildScrollView(  
  //     child: Center(
  //       child: Column(
  //         children: [
  //           const SizedBox(height: 16),
  //           _buildDeviceDropdown(), // Dropdown chọn thiết bị
  //           // const SizedBox(height: 16),
  //           _sensorData == null
  //               ? CircularProgressIndicator(color: colorScheme.primary)
  //               : _buildSensorData(colorScheme),        
  //           _buildControlSettings(colorScheme), 
  //         ],
  //       ),
  //     ),
  //   );
  // }
  // @override
  // Widget build(BuildContext context) {
  //   final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text(
  //         'DFarm',
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold, 
  //           color: Colors.green, 
  //           ),
  //         ),
  //       centerTitle: true,
  //       backgroundColor: Colors.white,
  //       automaticallyImplyLeading: false,
  //       elevation: 5, // Đổ bóng (mặc định là 4, có thể chỉnh)
  //       shadowColor: Colors.black.withOpacity(0.4),
  //     ),
  //     backgroundColor: colorScheme.background,
  //     body: _pages[_selectedIndex],
  //     bottomNavigationBar: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.black, // Màu nền
  //         boxShadow: [
  //           BoxShadow(
  //             color: const Color.fromARGB(255, 77, 77, 77).withOpacity(0.2), 
  //             blurRadius: 18, 
  //             spreadRadius: 0, 
  //             offset: Offset(0, -0.5), 
  //           ),
  //         ],
  //       ),
  //       child: BottomNavigationBar(
  //         items: const [
  //           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
  //           BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Nhật ký'),
  //           BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
  //           BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Người dùng'),
  //         ],
  //         currentIndex: _selectedIndex,
  //         selectedItemColor: Colors.lightGreen,
  //         unselectedItemColor: Colors.grey, 
  //         backgroundColor: Colors.black, // Màu nền thanh menu
  //         elevation: 10,    
  //         showSelectedLabels: false,  // Ẩn label của tab được chọn
  //         showUnselectedLabels: false,
  //         onTap: _onItemTapped,
  //       ),
  //     ),
  //   );
  // }

  @override
Widget build(BuildContext context) {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
  return Scaffold(
    appBar: _selectedIndex == 0 // Chỉ hiện AppBar khi ở trang chủ
        ? AppBar(
          automaticallyImplyLeading: false,
            title: Image.asset(
                    'assets/logo_removebg2.png',
                    height: 35,
                    // width: 100, 
                  ),
            centerTitle: true,
            backgroundColor: Colors.white,
            // elevation: 2,
            shadowColor: Colors.black.withOpacity(0.4),
          )
        : null,
    backgroundColor: colorScheme.background,
    body: _selectedIndex == 0
        ? SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildDeviceDropdown(),
                  _sensorData == null
                      ? CircularProgressIndicator(color: colorScheme.primary)
                      : _buildSensorData(colorScheme),
                  _buildControlSettings(colorScheme),
                ],
              ),
            ),
          )
        : _pages[_selectedIndex], // Trang khác giữ nguyên
    bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Nhật ký'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Thông báo'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Người dùng'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.lightGreen,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,  // Ẩn label của tab được chọn
      showUnselectedLabels: false,
      onTap: _onItemTapped,
    ),
  );
}

  /// Dropdown chọn thiết bị
  Widget _buildDeviceDropdown() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          const Text(
            'Chọn thiết bị', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 3),
          Container(
            // height: 40,
            decoration: BoxDecoration(
              color: Colors.white, // Nền dropdown
              borderRadius: BorderRadius.circular(12), // Bo góc viền
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(66, 132, 132, 132), 
                  blurRadius: 5, 
                  spreadRadius: 0.5,
                  offset: Offset(0, 0), 
                ),
              ],
            ),
            child: DropdownMenu<String>(
              textAlign: TextAlign.center,
              // width: MediaQuery.of(context).size.width * 0.40, 
              menuStyle: MenuStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white), 
                surfaceTintColor: WidgetStateProperty.all(Colors.white), 
                shadowColor: WidgetStateProperty.all(Colors.black26), 
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                elevation: WidgetStateProperty.all(4),
                alignment: Alignment.bottomLeft, 
              ),
              textStyle: const TextStyle(fontSize: 14, color: Colors.black),
              inputDecorationTheme: const InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)), 
                  borderSide: BorderSide.none, 
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              ),
              initialSelection: selectedDeviceId,
              onSelected: (newValue) {
                setState(() {
                  selectedDeviceId = newValue;
                  _updateIDCay();
                  _setupRealtimeListener();
                  _setupControlListener();
                });
              },
              dropdownMenuEntries: devices.map((device) {
                final deviceId = device['id'] is String ? device['id'] : device['id'].toString();
                return DropdownMenuEntry<String>(
                  value: deviceId,
                  label: device['name'] ?? 'Thiết bị không tên',
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị thông số cảm biến
  Widget _buildSensorData(ColorScheme colorScheme) {
    return Container(
      // color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Thông Số Cảm Biến',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const Divider(),
          SizedBox(
            width: 210,
            // height: 125,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true, 
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, // Khoảng cách giữa các cột
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                _buildSensorText('Nhiệt độ', '${_sensorData!['temperature']}°C', colorScheme),
                _buildSensorText('Độ ẩm', '${_sensorData!['humidity']}%', colorScheme),
                _buildSensorText('Độ ẩm đất', '${_sensorData!['soilMoisture']}%', colorScheme),
                _buildSensorText('Ánh sáng', '${_sensorData!['lux']}%', colorScheme),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder<DocumentSnapshot>(
            future: idCay.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('cay_trong')
                    .doc(widget.uid)
                    .collection('cay_trong_id')
                    .doc(idCay)
                    .get()
                : null, 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              // Nếu idCay rỗng hoặc dữ liệu không tồn tại, hiển thị nút "Thêm cây"
              if (idCay.isEmpty || !snapshot.hasData || (snapshot.data != null && !snapshot.data!.exists)) {
                return TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPlantPage(sensorId: selectedDeviceId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.green,),
                  label: const Text('Thêm cây trồng', style: TextStyle(color: Colors.green),),
                );
              }

              plantData = snapshot.data!.data() as Map<String, dynamic>;
              String tenCayEN = plantData!['ten_cay'] ?? 'unknown';
              String giaiDoanEN = plantData!['giai_doan'] ?? 'unknown';
              // Chuyển sang tiếng Việt bằng Map
              String tenCay = plantNames[tenCayEN] ?? 'Không có thông tin';
              giaiDoan = plantStages[giaiDoanEN] ?? 'Chưa có';
              int currentIndex = growthStages.indexOf(giaiDoanEN);
              bool isLastStage = currentIndex == growthStages.length - 1;
              
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Cây trồng',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            tenCay,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'Giai đoạn',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            giaiDoan,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      // Nút chỉnh sửa
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[200],
                        child: IconButton(
                          iconSize: 16,
                          icon: const Icon(Icons.edit, color: Colors.black), 
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPlantPage(
                                  uid: widget.uid,
                                  idCay: idCay,
                                  deviceID: selectedDeviceId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      onPressed: isLastStage
                          ? null
                          : () {
                              if (currentIndex < growthStages.length - 1) {
                                String nextStage = growthStages[currentIndex + 1];
                                String giaiDoanVN = plantStages[nextStage] ?? 'unknown';
                                _showConfirmStageDialog(context, nextStage);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLastStage ? Colors.grey[200] : Colors.green[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(isLastStage ? "Đạt giai đoạn cuối" : "Chuyển giai đoạn"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Widget hiển thị từng thông số cảm biến
  Widget _buildSensorText(String label, String value, ColorScheme colorScheme) {
    return SizedBox(
      child: Container(
        // constraints: BoxConstraints(minHeight: 10, minWidth: 80, maxHeight: 20),
        // padding: EdgeInsets.symmetric(vertical: 8), // Giữ khoảng cách hợp lý
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), 
              blurRadius: 4,
              offset: Offset(0, 2), 
            ),
          ],
        ),
        child: Column(
          // mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[600],
              ),
            ),
            // SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

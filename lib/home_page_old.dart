import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'diary.dart';
import 'user_page.dart';
import 'conn_IoT.dart';
import 'test.dart';
import 'AddPlantPage.dart';

class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0; // Biến lưu trạng thái tab đang chọn

  /// Danh sách các trang tương ứng với từng tab
  List<Widget> get _pages => [
  _buildMainPage(),
  PlantJournalScreen(uid: FirebaseAuth.instance.currentUser?.uid ?? "",),
  // WiFiConfigScreen(),
  // ProvisioningScreen(),
  // WifiProvisioningScreen(),
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
  String? selectedDeviceId; // Lưu deviceId đang chọn
  List<Map<String, dynamic>> devices = []; // Lưu danh sách thiết bị [{name: ..., id: ...}]
  Map<String, dynamic>? _controlData;
  
  String idCay = "";


  @override
  void initState() {
    super.initState();
    _fetchDevices(); // Lấy danh sách thiết bị từ Firestore
  }

  /// Lấy danh sách thiết bị từ Firestore
  Future<void> _fetchDevices() async {  
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('cam bien')
        .doc(widget.uid)
        .collection('device id')
        .get();


      List<Map<String, dynamic>> deviceList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?; // Ép kiểu dữ liệu về Map<String, dynamic>
      return {
        'name': data != null && data.containsKey('name') ? data['name'] : 'Thiết bị không tên',
        'id': doc.id,
        'idCay': data != null && data.containsKey('idCay') ? data['idCay'] : 'Thiết bị không tên',
      };
    }).toList();

    if (mounted) {
      setState(() {
        devices = deviceList;
        if (devices.isNotEmpty) {
          selectedDeviceId = devices.first['id']; // Chọn thiết bị đầu tiên mặc định
          _updateIDCay();
          _setupRealtimeListener();
          _setupControlListener();
        }
      });
    }
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cài Đặt Tưới',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const Divider(),

          // Hàng cho Bơm và Phương pháp tưới
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Điều chỉnh Bơm (hiển thị Bật hoặc Tắt)
              Column(
                children: [
                  Text(
                    'Bơm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _controlData!['TTBom'] == 1 ? 'Bật' : 'Tắt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _controlData!['TTBom'] == 1 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

              // Điều chỉnh phương pháp tưới
              Column(
                children: [
                  Text(
                    _controlData!['method'] == 1 ? 'Tưới tự động' : 'Tưới bán tự động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _controlData!['method'] == 1,
                    onChanged: (bool value) {
                      setState(() {
                        _controlData!['method'] = value ? 1 : 0;
                      });
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),

          const Divider(),

          // Điều chỉnh ngưỡng khô
          _buildControlSlider('getkho', 'Ngưỡng khô', (_controlData!['getkho'] ?? 40).toDouble(), // Ép kiểu về double khi sử dụng
    0.0,  // Đảm bảo min là double
    100.0),

          // Điều chỉnh ngưỡng tưới
          _buildControlSlider('gettoi', 'Ngưỡng tưới', (_controlData!['gettoi'] ?? 40).toDouble(), // Ép kiểu về double khi sử dụng
    0.0,  // Đảm bảo min là double
    100.0),

          // Điều chỉnh ngưỡng ướt
          _buildControlSlider('getuot', 'Ngưỡng ướt', (_controlData!['getuot'] ?? 40).toDouble(), // Ép kiểu về double khi sử dụng
    0.0,  // Đảm bảo min là double
    100.0),

          ElevatedButton(
            onPressed: _updateControlData,
            child: Text("Cập nhật"),
          ),
        ],
      ),
    );
  }



  void _updateControlData() {
    if (_controlData == null || selectedDeviceId == null) return;

    FirebaseDatabase.instance
        .ref()
        .child('controlData')
        .child(widget.uid)
        .child(selectedDeviceId!)
        .set(_controlData)
        .then((_) {
          print("Dữ liệu tưới đã cập nhật thành công!");
        })
        .catchError((error) {
          print("Lỗi cập nhật dữ liệu: $error");
        });
  }


  Widget _buildControlSlider(String key, String label, double value, double min, double max) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          label: value.toInt().toString(),
          onChanged: (newValue) {
            setState(() {
              _controlData![key] = newValue.toInt();
            });
          },
        ),
      ],
    );
  }

  Widget _buildMainPage() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(  
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildDeviceDropdown(), // Dropdown chọn thiết bị
            const SizedBox(height: 16),
            _sensorData == null
                ? CircularProgressIndicator(color: colorScheme.primary)
                : _buildSensorData(colorScheme),
            const SizedBox(height: 16),
            _buildControlSettings(colorScheme), 
            // Thêm các phần tử khác nếu cần
          ],
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);

  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'DFarm',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold, 
          color: Colors.green, 
          ),
        ),
      centerTitle: true,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
    ),
    backgroundColor: colorScheme.background,
    body: _pages[_selectedIndex],
    // body: SingleChildScrollView(  // Bọc trong SingleChildScrollView
    //   child: Center(
    //     child: Column(
    //       children: [
    //         const SizedBox(height: 16),
    //         _buildDeviceDropdown(), // Dropdown chọn thiết bị
    //         const SizedBox(height: 16),
    //         _sensorData == null
    //             ? CircularProgressIndicator(color: colorScheme.primary)
    //             : _buildSensorData(colorScheme),
    //         const SizedBox(height: 16),
    //         _buildControlSettings(colorScheme), 
    //         // Thêm các phần tử khác nếu cần
    //       ],
    //     ),
    //   ),
    // ),
    bottomNavigationBar: BottomNavigationBar(
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
    return devices.isEmpty
        ? const CircularProgressIndicator()
        : DropdownButton<String>(
            value: selectedDeviceId,
            onChanged: (newValue) {
              setState(() {
                selectedDeviceId = newValue;
                _updateIDCay();
                _setupRealtimeListener(); 
                _setupControlListener();// Cập nhật dữ liệu theo thiết bị mới
              });
            },
            items: devices.map((device) {
              final deviceId = device['id'] is String ? device['id'] : device['id'].toString(); // Kiểm tra và chuyển sang String nếu cần
              return DropdownMenuItem<String>(
                value: deviceId,
                child: Text(device['name'] ?? 'Thiết bị không tên'),
              );
            }).toList(),
          );
    }

  /// Hiển thị thông số cảm biến
  Widget _buildSensorData(ColorScheme colorScheme) {
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const Divider(),
          _buildSensorText('Nhiệt độ', '${_sensorData!['temperature']}°C', colorScheme),
          _buildSensorText('Độ ẩm', '${_sensorData!['humidity']}%', colorScheme),
          _buildSensorText('Độ ẩm đất', '${_sensorData!['soil_moisture']}%', colorScheme),
          _buildSensorText('Ánh sáng', '${_sensorData!['light']} lux', colorScheme),
          const Divider(),
          FutureBuilder<DocumentSnapshot>(
            future: idCay.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('cay trong')
                    .doc(widget.uid)
                    .collection('cay trong id')
                    .doc(idCay)
                    .get()
                : null, // Nếu idCay rỗng, trả về null tránh lỗi
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
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm cây trồng'),
                );
              }

              var plantData = snapshot.data!.data() as Map<String, dynamic>;

              return Column(
                children: [
                  Text(
                    'Cây Trồng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plantData['ten_cay'] ?? 'Không có thông tin',
                    style: const TextStyle(fontSize: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 18, color: colorScheme.onSurface),
      ),
    );
  }
}

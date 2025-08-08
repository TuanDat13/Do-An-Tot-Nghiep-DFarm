import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddPlantPage extends StatefulWidget {
  final String? sensorId;
  const AddPlantPage({Key? key, required this.sensorId}) : super(key: key);

  @override
  _AddPlantPageState createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> plantTypes = [];
  List<String> growthStages = [];
  List<String> soilTypes = [];

  String? selectedPlant;
  String? selectedStage;
  String? selectedSoil;
  TextEditingController dateController = TextEditingController();
  TextEditingController ngayThu = TextEditingController();
  DateTime? selectedDate;

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

  final Map<String, String> soil = {
    'Clay Soil': 'Đất sét',
    'Sandy Soil': 'Đất cát',
    'Red Soil': 'Đất đỏ',
    'Loam Soil': 'Đất thịt pha',
    'Black Soil': 'Đất đen',
    'Alluvial Soil': 'Đất phù sa',
    'Chalky Soil': 'Đất phấn',
    
  };

  @override
  void initState() {
    super.initState();
    _fetchPlantData();
  }

  Future<void> _fetchPlantData() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('cay_trong_mau')
          .doc('MsPkBzB5p3YTEwlBTj8YueyHAgg2')
          .get();

      if (docSnapshot.exists) {
        var data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          plantTypes = List<String>.from(data['mau_cay'] ?? []);
          growthStages = List<String>.from(data['mau_GD'] ?? []);
          soilTypes = List<String>.from(data['mau_dat'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching plant data: $e');
    }
  }

  Future<void> _savePlant() async {
    String uid = _auth.currentUser!.uid;
    if (selectedPlant == null || selectedStage == null || selectedSoil == null || dateController == null || ngayThu == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin!")));
      return;
    }
    List<String> dateParts = dateController.text.split('/');
      if (dateParts.length == 3) {
        int day = int.parse(dateParts[0]);
        int month = int.parse(dateParts[1]);
        int year = int.parse(dateParts[2]);

        DateTime selectedDate = DateTime(year, month, day);

        try {
          DocumentReference newPlantRef = FirebaseFirestore.instance
              .collection('cay_trong')
              .doc(uid)
              .collection('cay_trong_id')
              .doc();

          await newPlantRef.set({
            'ten_cay': selectedPlant,
            'giai_doan': selectedStage,
            'loai_dat': selectedSoil,
            'ngay_trong': Timestamp.fromDate(selectedDate),
            'so_ngay_thu_hoach': ngayThu.text,
            'trangThai': true,
          });
          await FirebaseFirestore.instance.collection('cam bien').doc(uid).collection('device id').doc(widget.sensorId).set({
            'idCay': newPlantRef.id,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lưu cây trồng thành công!")));
          Navigator.pop(context);
        } catch (e) {
          print('Error saving plant: $e');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi lưu cây trồng!")));
        }
      }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận"),
          content: const Text("Bạn có chắc chắn muốn thêm cây trồng này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
                _savePlant(); 
              },
              child: const Text("Xác nhận", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black), // Đổi icon quay lại
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước
          },
        ),
        title: const Text(
          'Thêm Cây Trồng',
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
      body: SingleChildScrollView(
      child:  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Cây Trồng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            DropdownMenu<String>(
              initialSelection: selectedPlant,
              onSelected: (String? value) {
                setState(() {
                  selectedPlant = value!;
                });
              },
              dropdownMenuEntries: plantTypes
                .map((plant) => DropdownMenuEntry(value: plant, label: plantNames[plant] ?? plant,))
                .toList(),
              width: 280, 
              menuHeight: 200, 
              enableSearch: true, // Thêm thanh tìm kiếm
              expandedInsets: EdgeInsets.zero,// Căn lề hợp lý
              textStyle: TextStyle(fontSize: 16, color: Colors.black), 
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
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Giai Đoạn',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            DropdownMenu<String>(
              initialSelection: selectedStage,
              onSelected: (String? value) {
                setState(() {
                  selectedStage = value!;
                });
              },
              dropdownMenuEntries: growthStages
                .map((stage) => DropdownMenuEntry(value: stage, label: plantStages[stage] ?? stage,))
                .toList(),
              width: 280, 
              menuHeight: 200, 
              enableSearch: true, // Thêm thanh tìm kiếm
              expandedInsets: EdgeInsets.zero,// Căn lề hợp lý
              textStyle: TextStyle(fontSize: 16, color: Colors.black),
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
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
            ),
            SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Loại Đất',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            DropdownMenu<String>(
              initialSelection: selectedSoil,
              onSelected: (String? value) {
                setState(() {
                  selectedSoil = value!;
                });
              },
              dropdownMenuEntries: soilTypes
                .map((soilType) => DropdownMenuEntry(value: soilType, label: soil[soilType] ?? soilType,))
                .toList(),
              width: 280, 
              menuHeight: 200, 
              enableSearch: true, 
              expandedInsets: EdgeInsets.zero, 
              textStyle: TextStyle(fontSize: 16, color: Colors.black), 
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
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Ngày Tháng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.calendar_today, color: Colors.green), // Icon lịch
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                enabledBorder: OutlineInputBorder( 
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder( 
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Số Ngày Thu Hoạch',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            TextField(
              controller: ngayThu,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                
                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
            const SizedBox(height: 20),
            Center(
              
              child: ElevatedButton(
                onPressed: () {_showConfirmationDialog(context);},
                child: const Text('Thêm Cây Trồng'),
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
          ],
        ),
      ),
      ),
    );
  }
}

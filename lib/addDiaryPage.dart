import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddDiaryPage extends StatefulWidget {
  final String uid;
  AddDiaryPage({required this.uid});

  @override
  _AddDiaryPageState createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController N = TextEditingController();
  TextEditingController P = TextEditingController();
  TextEditingController K = TextEditingController();
  TextEditingController plantController = TextEditingController();
  TextEditingController noteController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  List<Map<String, dynamic>> devices = [];
  String? selectedDeviceId;
  String? stage;
  String? plantName;
  String? idCayT;
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

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('cam bien')
        .doc(widget.uid)
        .collection('device id')
        .get();

    List<Map<String, dynamic>> deviceList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      return {
        'name': data?['name'] ?? 'Thiết bị không tên',
        'id': doc.id,
        'idCay': data?['idCay'],
      };
    }).toList();

    if (mounted) {
      setState(() {
        devices = deviceList;
        if (devices.isNotEmpty) {
          selectedDeviceId = devices.first['id'];
          _fetchPlantAndStages(devices.first['idCay']);
        }
      });
    }
  }

  Future<void> _fetchPlantAndStages(String? idCay) async {
    if (idCay == null || idCay.isEmpty) {
      return ; // Trả về null nếu idCay không hợp lệ
    }

      idCayT = idCay;
    try {
      DocumentSnapshot plantSnapshot = await FirebaseFirestore.instance
          .collection('cay_trong')
          .doc(widget.uid)
          .collection('cay_trong_id')
          .doc(idCay)
          .get();

      if (plantSnapshot.exists) {
        final data = plantSnapshot.data() as Map<String, dynamic>?;

        if (mounted) {
          setState(() {
            String englishPlantName = data?['ten_cay'] ?? 'Không có';
            plantName = plantNames[englishPlantName] ?? englishPlantName;

            String englishStage = data?['giai_doan'] ?? 'Không có';
            stage = plantStages[englishStage] ?? englishStage;
          });
        }
      } else {
        print("Không có cây trồng");
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu cây trồng: $e");
    }
  }

  Future<void> _selectDate() async {
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
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận Thêm"),
          content: const Text("Bạn có chắc chắn muốn thêm cây trồng này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                _saveJournal(); 
              },
              child: const Text("Xác nhận", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveJournal() async {
    
      String? englishPlantName;
      String? englishStage;

      // Tìm tên tiếng Anh của cây trồng
      englishPlantName = plantNames.entries
          .firstWhere((entry) => entry.value == plantName,
              orElse: () => MapEntry(plantName!, plantName!))
          .key;

      // Tìm giai đoạn tiếng Anh
      englishStage = plantStages.entries
          .firstWhere((entry) => entry.value == stage,
              orElse: () => MapEntry(stage!, stage!))
          .key;
    List<String> dateParts = dateController.text.split('/');
    if (titleController.text.isEmpty || dateController.text.isEmpty || englishStage.isEmpty || englishPlantName.isEmpty ||
      N.text.isEmpty ||
      P.text.isEmpty ||
      K.text.isEmpty ||
      noteController.text.isEmpty ||
      idCayT!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    if (dateParts.length == 3) {
      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      DateTime selectedDate = DateTime(year, month, day);

      try {
        await FirebaseFirestore.instance
            .collection('nhat ky')
            .doc(widget.uid)
            .collection('entries')
            .add({
          "tieuDe": titleController.text,
          "cayTrong": englishPlantName,
          "ngayThang": Timestamp.fromDate(selectedDate),
          "giaiDoan": englishStage,
          "N": N.text,
          "P": P.text,
          "K": K.text,
          "ghiChu": noteController.text,
          "idCay": idCayT,
          "hinhAnhUrl": "",
        });
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        print("Lỗi khi lưu nhật ký: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi lưu nhật ký: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.black), 
            onPressed: () {
              Navigator.pop(context); 
            },
          ),
          title: const Text(
            'Thêm Nhật Ký',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Thiết bị',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              DropdownMenu<String>(
                initialSelection: selectedDeviceId,
                dropdownMenuEntries: devices.map((device) {
                  return DropdownMenuEntry<String>(
                    value: device['id'].toString(),
                    label: device['name'],
                  );
                }).toList(),
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
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                onSelected: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDeviceId = value;
                      final selectedDevice = devices.firstWhere((device) => device['id'] == value);
                      _fetchPlantAndStages(selectedDevice['idCay']);
                    });
                  }
                },
              ),
              // SizedBox(height: 5,),
              Container(
                width: 300,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50, // Màu nền nhẹ
                  borderRadius: BorderRadius.circular(12), // Bo góc
                  border: Border.all(color: Colors.green.shade300), // Viền nhẹ
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2), // Đổ bóng nhẹ
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3), // Đổ bóng xuống dưới
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cây trồng: ${plantName ?? 'Không có'}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    
                    Text(
                      "Giai đoạn: ${stage ?? 'Không có'}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Tiêu đề',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextField(
                cursorColor: Colors.green[300],
                
                controller: titleController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                  enabledBorder: OutlineInputBorder( // Viền xám mặc định
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                )
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Ngày tháng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextField(
                cursorColor: Colors.green[300],
                autocorrect: false,
                enableSuggestions: false,
                controller: dateController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                  enabledBorder: OutlineInputBorder( // Viền xám mặc định
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Chỉ số N (Nito)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextField(
                controller: N,
                cursorColor: Colors.green[300],
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.number, // Chỉ nhập số
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),
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
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Chỉ số P (PhotPho)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextField(
                controller: P,
                cursorColor: Colors.green[300],
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.number, // Chỉ nhập số
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),
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
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Chỉ Số K (Kali)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextField(
                controller: K,
                cursorColor: Colors.green[300],
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.number, // Chỉ nhập số
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 18),
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
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              TextFormField(
                controller: noteController,
                cursorColor: Colors.green[300],
                
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                  enabledBorder: OutlineInputBorder( // Viền xám mặc định
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder( // Khi focus vẫn giữ viền xám
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                maxLines: 7,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ElevatedButton(
                  //   onPressed: () => Navigator.pop(context),
                  //   child: Text("Hủy"),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color.fromARGB(255, 174, 79, 44),
                  //     foregroundColor: Colors.white,
                  //     padding: const EdgeInsets.symmetric(horizontal: 16,),
                      
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(16),
                  //     ),
                  //     overlayColor:Colors.white,
                  //   ),
                  // ),
                  // SizedBox(width: 10,),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context);
                    },
                    child: Text("Lưu"),
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
                  SizedBox(width: 5,),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditPlantPage extends StatefulWidget {
  final String uid;
  final String idCay;
  final String? deviceID;

  const EditPlantPage({Key? key, required this.uid, required this.idCay, required this.deviceID}) : super(key: key);

  @override
  _EditPlantPageState createState() => _EditPlantPageState();
}

class _EditPlantPageState extends State<EditPlantPage> {
  TextEditingController dateController = TextEditingController();
  TextEditingController ngayThu = TextEditingController();
  String? selectedPlant;
  String? selectedStage;
  String? selectedSoil;
  String? harvestDays;

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

  List<String> plantTypes = [];
  List<String> growthStages = [];
  List<String> soilTypes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlantDataMau();
    _fetchPlantData();
  }

  Future<void> _fetchPlantDataMau() async {
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

  Future<void> _fetchPlantData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('cay_trong')
          .doc(widget.uid)
          .collection('cay_trong_id')
          .doc(widget.idCay)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String cayEN = data['ten_cay'];
        String GDEN = data['giai_doan'];
        String soilEN = data['loai_dat'];
        Timestamp timestamp = data['ngay_trong'];
        DateTime ngayTrong = timestamp.toDate(); // Chuyển Timestamp → DateTime
        String formattedDate = DateFormat('dd/MM/yyyy').format(ngayTrong);

        setState(() {
          selectedPlant = plantNames[cayEN] ?? cayEN;
          selectedStage = plantStages[GDEN] ?? GDEN; 
          selectedSoil = soil[soilEN] ?? soilEN;
          dateController.text = formattedDate;
          ngayThu.text = data['so_ngay_thu_hoach'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi lấy dữ liệu cây trồng: $e");
      setState(() => isLoading = false);
    }
  }


  Future<void> _updatePlant() async {
    if (dateController.text.isNotEmpty) {
      List<String> dateParts = dateController.text.split('/');
        if (dateParts.length == 3) {
          int day = int.parse(dateParts[0]);
          int month = int.parse(dateParts[1]);
          int year = int.parse(dateParts[2]);

          DateTime selectedDate = DateTime(year, month, day);
        await FirebaseFirestore.instance
            .collection('cay_trong')
            .doc(widget.uid)
            .collection('cay_trong_id')
            .doc(widget.idCay)
            .update({
          'ten_cay': plantNames.entries.firstWhere((entry) => entry.value == selectedPlant, orElse: () => MapEntry(selectedPlant ?? "", "")).key,
          'giai_doan': plantStages.entries.firstWhere((entry) => entry.value == selectedStage, orElse: () => MapEntry(selectedStage ?? "", "")).key,
          'loai_dat': soil.entries.firstWhere((entry) => entry.value == selectedSoil, orElse: () => MapEntry(selectedSoil ?? "", "")).key,
          'so_ngay_thu_hoach': ngayThu.text,
          'ngay_trong': Timestamp.fromDate(selectedDate),
        });
        Navigator.pop(context);
      }else {
        print("Lỗi định dạng ngày tháng");
      }
    }else {
      print("Ngày trồng không được để trống");
    }
  }

  Future<void> _deletePlant() async {
    await FirebaseFirestore.instance
        .collection('cay_trong')
        .doc(widget.uid)
        .collection('cay_trong_id')
        .doc(widget.idCay)
        .update({
          'trangThai': false,
        });

    await FirebaseFirestore.instance
        .collection('cam bien')
        .doc(widget.uid)
        .collection('device id')
        .doc(widget.deviceID)
        .update({
          'idCay': "",
        });
    Navigator.pop(context);
  }

  void _showSaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận Sửa"),
          content: const Text("Bạn có chắc muốn sửa cây trồng này?"),
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
                _updatePlant(); 
              },
              child: const Text("Xác nhận", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận Kết Thúc"),
          content: const Text("Bạn muốn kết thúc cây trồng này không?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại
                _deletePlant(); // Gọi hàm lưu cây trồng
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
          'Sửa Cây Trồng',
          style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              )
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        
      ),
      backgroundColor: colorScheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
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
                      dropdownMenuEntries: plantNames.values
                          .map((name) => DropdownMenuEntry(value: name, label: name))
                          .toList(),
                      width: 280, 
                      menuHeight: 200, 
                      enableSearch: true, // Thêm thanh tìm kiếm
                      expandedInsets: EdgeInsets.zero,// Căn lề hợp lý
                      textStyle: TextStyle(fontSize: 16, color: Colors.black), 
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
                      dropdownMenuEntries: plantStages.values
                          .map((stage) => DropdownMenuEntry(value: stage, label: stage))
                          .toList(),
                      width: 280, 
                      menuHeight: 200, 
                      enableSearch: true, // Thêm thanh tìm kiếm
                      expandedInsets: EdgeInsets.zero,// Căn lề hợp lý
                      textStyle: TextStyle(fontSize: 16, color: Colors.black), 
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
                      dropdownMenuEntries: soil.values
                          .map((soilType) => DropdownMenuEntry(value: soilType, label: soilType))
                          .toList(),
                      width: 280, // Độ rộng menu dropdown
                      menuHeight: 200, // Chiều cao menu
                      enableSearch: true, // Thêm thanh tìm kiếm
                      expandedInsets: EdgeInsets.zero, // Căn lề hợp lý
                      textStyle: TextStyle(fontSize: 16, color: Colors.black), 
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
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
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
                    SizedBox(height: 10,),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: () {_showSaveDialog(context);},
                            child: const Text('Lưu'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              overlayColor:Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () { _showEndDialog(context);},
                          
                          child: const Text('Kết thúc cây trồng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 174, 79, 44),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            overlayColor:Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

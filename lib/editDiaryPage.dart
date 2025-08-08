import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditJournalScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> journal;

  EditJournalScreen({required this.uid, required this.journal});

  @override
  _EditJournalScreenState createState() => _EditJournalScreenState();
}

class _EditJournalScreenState extends State<EditJournalScreen> {
  late TextEditingController titleController;
  late TextEditingController plantController;
  late TextEditingController dateController;
  late TextEditingController noteController;
  late TextEditingController N = TextEditingController();
  late TextEditingController P = TextEditingController();
  late TextEditingController K = TextEditingController();
  late String selectedStage;
  late String plantName;
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
    titleController = TextEditingController(text: widget.journal['tieuDe']);
    Timestamp timestamp = widget.journal['ngayThang'];
    String formattedDate = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
    dateController = TextEditingController(text: formattedDate);
    noteController = TextEditingController(text: widget.journal['ghiChu']);
    N = TextEditingController(text: widget.journal['N']);
    P = TextEditingController(text: widget.journal['P']);
    K = TextEditingController(text: widget.journal['K']);
    String englishPlantName = widget.journal['cayTrong'] ?? 'Không xác định';
    plantName = plantNames[englishPlantName] ?? englishPlantName;
    String englishStage = widget.journal['giaiDoan'] ?? 'Không xác định';
    selectedStage = plantStages[englishStage] ?? englishStage;
    
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Xác nhận Sửa"),
          content: const Text("Bạn có muốn sửa cây trồng này không?"),
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
                _updateJournal(); 
              },
              child: const Text("Xác nhận", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateJournal() async {
    if (titleController.text.isEmpty || dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    String? englishPlantName;
    String? englishStage;

      // Tìm tên tiếng Anh của cây trồng
      englishPlantName = plantNames.entries
          .firstWhere((entry) => entry.value == plantName,
              orElse: () => MapEntry(plantName, plantName))
          .key;

      // Tìm giai đoạn tiếng Anh
      englishStage = plantStages.entries
          .firstWhere((entry) => entry.value == selectedStage,
              orElse: () => MapEntry(selectedStage!, selectedStage!))
          .key;
    List<String> dateParts = dateController.text.split('/');
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
          .doc(widget.journal['id'])
          .update({
            "tieuDe": titleController.text,
            // "cayTrong": englishPlantName,
            "ngayThang": Timestamp.fromDate(selectedDate),
            // "giaiDoan": englishStage,
            "N": N.text,
            "P": P.text,
            "K": K.text,
            "ghiChu": noteController.text,
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

  Future<void> _deleteJournal() async {
    try {
      await FirebaseFirestore.instance
          .collection('nhat ky')
          .doc(widget.uid)
          .collection('entries')
          .doc(widget.journal['id'])
          .delete();

      if (mounted) {
        Navigator.pop(context, true); // Quay lại màn hình trước đó
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi xóa nhật ký: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận xóa"),
          content: Text("Bạn có muốn xóa nhật ký này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Hủy", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteJournal();
              },
              child: Text("Xóa", style: TextStyle(color: Colors.green)),
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
            icon: Icon(Icons.arrow_back_ios, color: Colors.black), 
            onPressed: () {
              Navigator.pop(context); 
            },
          ),
          title: const Text(
            'Sửa Nhật Ký',
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
                      "Cây trồng: ${plantName}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    
                    Text(
                      "Giai đoạn: ${selectedStage}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),
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
                autocorrect: false,
                enableSuggestions: false,
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
                autocorrect: false,
                enableSuggestions: false,
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
                maxLines: 5,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: (){_showConfirmationDialog(context);},
                    child: Text("Sửa"),
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
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 174, 79, 44),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          overlayColor:Colors.white,
                    ),
                    onPressed: () => _showDeleteConfirmationDialog(context),
                    child: Text("Xóa nhật ký", style: TextStyle(color: Colors.white, fontSize: 16)),
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

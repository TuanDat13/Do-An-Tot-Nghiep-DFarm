import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'entry_detail_page.dart';


class CropDetailPage extends StatefulWidget {
  final Map<String, dynamic> crop; // Dữ liệu cây trồng

  CropDetailPage({required this.crop});

  @override
  _CropDetailPageState createState() => _CropDetailPageState();
}

class _CropDetailPageState extends State<CropDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _entries = [];

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
    _fetchEntries(); 
  }

  Future<void> _fetchEntries() async {
    String uid = _auth.currentUser!.uid;
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('nhat ky') 
          .doc(uid) 
          .collection('entries') 
          .where('idCay', isEqualTo: widget.crop['id']) 
          .get();

      List<Map<String, dynamic>> entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Chuyển Timestamp -> DateTime
        if (data['ngayThang'] != null && data['ngayThang'] is Timestamp) {
          data['ngayThang'] = (data['ngayThang'] as Timestamp).toDate();
        }

        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _entries = entries;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy nhật ký: $e");
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
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
        title: Text(
          widget.crop['ten_cay'],
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
      body: 
        Column(
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
                    "Cây trồng: ${plantNames[widget.crop['ten_cay']] ?? widget.crop['ten_cay']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  
                  Text(
                    "Ngày trồng: ${widget.crop['ngay_trong'] != null ? _formatDate(widget.crop['ngay_trong']) : 'Không rõ'}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  Text(
                    "Loại đất: ${soil[widget.crop['loai_dat']] ?? widget.crop['loai_dat']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  Text(
                    "Giai đoạn: ${plantStages[widget.crop['giai_doan']] ?? widget.crop['giai_doan']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  Text(
                    "Số ngày thu hoạch: ${widget.crop['so_ngay_thu_hoach']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _entries.isEmpty
                  ? Center(child: Text("Không có nhật ký nào"))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return Card(
                          color: Colors.white,
                          elevation: 2,
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(entry['tieuDe']),
                            subtitle: Text("Ngày: ${_formatDate(entry['ngayThang'])}"),
                            // trailing: Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EntryDetailPage(entry: entry),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      
    );
  }
}

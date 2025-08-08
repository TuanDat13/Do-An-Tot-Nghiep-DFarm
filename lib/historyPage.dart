import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CropDetailPage.dart';

class CropHistoryPage extends StatefulWidget {
  final String uid; // UID của người dùng

  const CropHistoryPage({Key? key, required this.uid}) : super(key: key);

  @override
  _CropHistoryPageState createState() => _CropHistoryPageState();
}

class _CropHistoryPageState extends State<CropHistoryPage> {
  List<Map<String, dynamic>> _crops = [];

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
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('cay_trong') // Tên collection
          .doc(widget.uid) // Lấy theo UID người dùng
          .collection('cay_trong_id') // Lấy danh sách cây trồng của người đó
          .where('trangThai', isEqualTo: false) // Chỉ lấy cây có trangThai = false
          .get();

      List<Map<String, dynamic>> crops = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Lưu lại ID của tài liệu
        if (data['ngay_trong'] != null && data['ngay_trong'] is Timestamp) {
          DateTime ngayTrongDateTime = (data['ngay_trong'] as Timestamp).toDate();
          data['ngay_trong'] = ngayTrongDateTime; // Cập nhật dữ liệu
        }
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _crops = crops;
        });
      }
    } catch (e) {
      print("Lỗi khi lấy dữ liệu cây trồng: $e");
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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black), // Đổi icon quay lại
          onPressed: () {
            Navigator.pop(context); // Quay lại màn hình trước
          },
        ),
        title: const Text(
          'Lịch sử cây trồng',
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
      body: _crops.isEmpty
          ? Center(child: Text("Không có cây nào trong lịch sử"))
          : ListView.builder(
              itemCount: _crops.length,
              itemBuilder: (context, index) {
                var crop = _crops[index];
                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.only(top: 12, right: 16, left: 16),
                  child: ListTile(
                    title: Text(plantNames[crop['ten_cay']] ?? "Không có tên", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      "Ngày trồng: ${crop['ngay_trong'] != null ? _formatDate(crop['ngay_trong']) : 'Không rõ'}",
                    ),
                    // trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CropDetailPage(crop: crop),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// Trang chi tiết cây trồng
// class CropDetailPage extends StatelessWidget {
//   final Map<String, dynamic> crop;

//   const CropDetailPage({Key? key, required this.crop}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Chi tiết cây trồng")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Tên cây: ${crop['ten_cay']}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             SizedBox(height: 10),
//             Text("Ngày trồng: ${crop['ngay_trong'] ?? 'Không rõ'}"),
//             SizedBox(height: 10),
//             Text("Loại đất: ${crop['loai_dat'] ?? 'Không rõ'}"),
            
//           ],
//         ),
//       ),
//     );
//   }
// }

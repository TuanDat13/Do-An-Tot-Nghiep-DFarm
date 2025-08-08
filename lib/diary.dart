import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'editDiaryPage.dart';
import 'addDiaryPage.dart';
import 'package:flutter/services.dart';

class PlantJournalScreen extends StatefulWidget {
  final String uid;
  PlantJournalScreen({required this.uid});

  @override
  _PlantJournalScreenState createState() => _PlantJournalScreenState();
}

class _PlantJournalScreenState extends State<PlantJournalScreen> {
  Map<String, List<Map<String, dynamic>>> _groupedEntries = {};

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
    _fetchEntries();
  }

  Future<void> _fetchEntries() async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('nhat ky')
        .doc(widget.uid)
        .collection('entries')
        .orderBy('ngayThang', descending: true)
        .get();

    Map<String, List<Map<String, dynamic>>> groupedEntries = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Kiểm tra nếu idCay là null hoặc không phải String
      if (data['idCay'] == null || data['idCay'] is! String) {
        print("Bỏ qua nhật ký có id null hoặc không hợp lệ: ${doc.id}");
        continue;
      }

      String idCay = data['idCay'];
      Timestamp? timestamp = data['ngayThang'];

      // Kiểm tra nếu timestamp là null
      if (timestamp == null) {
        print("Bỏ qua nhật ký có timestamp null: ${doc.id}");
        continue;
      }

      DateTime date = timestamp.toDate();
      String ngay = DateFormat('dd/MM/yyyy').format(date);
      data['id'] = doc.id;

      DocumentSnapshot caySnapshot = await FirebaseFirestore.instance
          .collection('cay_trong')
          .doc(widget.uid)
          .collection('cay_trong_id')
          .doc(idCay)
          .get();

      if (caySnapshot.exists && 
          (caySnapshot.data() as Map<String, dynamic>?)?['trangThai'] == true) {
        groupedEntries.putIfAbsent(ngay, () => []);
        groupedEntries[ngay]!.add(data);
      }
    }

    if (mounted) {
      setState(() {
        _groupedEntries = groupedEntries;
      });
    }
  } catch (e) {
    print("Lỗi khi lấy nhật ký: $e");
  }
}


  void _navigateToEditPage(Map<String, dynamic> journal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditJournalScreen(uid: widget.uid, journal: journal)),
    ).then((isUpdated) {
      if (isUpdated == true) _fetchEntries();
    });
  }

  void _navigateToAddPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddDiaryPage(uid: widget.uid)),
    ).then((isUpdated) {
      if (isUpdated == true) _fetchEntries();
    });
  }

  Widget _buildJournalList() {
    return _groupedEntries.isEmpty
        ? Center(child: Text("Chưa có nhật ký nào", style: TextStyle(fontSize: 16, color: Colors.grey)))
        : ListView.builder(
            itemCount: _groupedEntries.length,
            itemBuilder: (context, index) {
              String date = _groupedEntries.keys.elementAt(index);
              List<Map<String, dynamic>> entries = _groupedEntries[date]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:EdgeInsets.only(left: 16, right: 16,bottom: 0,top: 10),

                    child: Text(date, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  ...entries.map((journal) => _buildJournalCard(journal)).toList(),
                ],
              );
            },
          );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal) {
    String plantName = plantNames[journal['cayTrong']] ?? journal['cayTrong']; 

    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
      borderRadius: BorderRadius.circular(12), 
      onTap: () {
          _navigateToEditPage(journal);
      },
        child: Container(
          height: 55,
          padding: EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(journal['tieuDe'],
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 0),
                  Text(plantName,
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Nhật Ký Cây Trồng',
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
      body: _buildJournalList(),
      floatingActionButton: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact(); 
          _navigateToAddPage();
        },
        child: Material(
          shape: CircleBorder(), 
          color: Colors.green,
          elevation: 2, 
          child: InkWell(
            borderRadius: BorderRadius.circular(50), 
            splashColor: Colors.white.withOpacity(0.5), 
            onTap: () {
              HapticFeedback.lightImpact(); 
              _navigateToAddPage();
            },
            child: Container(
              width: 56, 
              height: 56,
              alignment: Alignment.center,
              child: Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),

    );
  }
}

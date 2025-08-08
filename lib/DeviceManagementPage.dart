import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'conn_IoT.dart';
import 'package:firebase_database/firebase_database.dart';

class DeviceManagementPage extends StatefulWidget {
  final String uid;

  DeviceManagementPage({required this.uid});

  @override
  _DeviceManagementPageState createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  // @override
  // void initState() {
  //   super.initState();
  //   getDevices();
  // }

  Future<QuerySnapshot> getDevices() async {
    return await FirebaseFirestore.instance
        .collection('cam bien')
        .doc(widget.uid)
        .collection('device id')
        .get();
  }

  void _editDeviceName(String deviceId, String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95, 
          padding: EdgeInsets.all(20), // Khoảng cách bên trong
          decoration: BoxDecoration(
            color: Colors.white, // Màu nền
            borderRadius: BorderRadius.circular(16), // Bo góc
            boxShadow: [ // Hiệu ứng đổ bóng
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Để hộp thoại không quá cao
            children: [
              Text(
                "Sửa tên thiết bị",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                cursorColor: Colors.green[300],
                autocorrect: false,
                enableSuggestions: false,
                controller: nameController,
                autofocus: true, // Tự động focus khi hộp thoại mở
                decoration: InputDecoration(
                  labelText: "Tên thiết bị mới",
                  labelStyle: TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.grey[100], // Màu nền nhẹ nhàng hơn
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Hủy",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  SizedBox(width: 5,),
                  ElevatedButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('cam bien')
                          .doc(widget.uid)
                          .collection('device id')
                          .doc(deviceId)
                          .update({'name': nameController.text});
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text(
                      "Lưu",
                      style: TextStyle(fontSize: 16, color: Colors.green),
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

  Future<void> _deleteDevice(String deviceId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true, // Cho phép bấm ngoài để đóng hộp thoại
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          "Xác nhận xóa",
          textAlign: TextAlign.center,
        ),
        content: Text(
          "Bạn có chắc chắn muốn xóa thiết bị này không?",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Trả về false
            child: const Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Trả về true
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: Text("Xóa", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        // Xóa trên Firestore
        await FirebaseFirestore.instance
            .collection('cam bien')
            .doc(widget.uid)
            .collection('device id')
            .doc(deviceId)
            .delete();

        // Xóa trên Realtime Database
        DatabaseReference databaseRef = FirebaseDatabase.instance.ref();
        await databaseRef.child('controlData/${widget.uid}/$deviceId').remove();
        await databaseRef.child('sensorData/${widget.uid}/$deviceId').remove();

        print("Thiết bị đã bị xóa thành công trên cả Firestore và Realtime Database.");
        setState(() {});
      } catch (error) {
        print("Lỗi khi xóa thiết bị: $error");
      }
    } else {
      print("Người dùng đã hủy xóa thiết bị.");
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
            'Quản lý thiết bị',
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
      body: FutureBuilder(
        future: getDevices(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var devices = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: devices.isEmpty
                    ? Center(child: Text("Chưa có thiết bị nào"))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          var device = devices[index];
                          return Card(
                            color: Colors.white,
                            elevation: 3,
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(Icons.thermostat, color: Colors.green[400]),
                              title: Text(device['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[200],
                                    child: IconButton(
                                      iconSize: 16,
                                      icon: Icon(Icons.edit, color: Colors.black),
                                      onPressed: () => _editDeviceName(device.id, device['name']),
                                    ),
                                  ),
                                  SizedBox(width: 5,),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[200],
                                    child: IconButton(
                                      iconSize: 18,
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteDevice(device.id),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ProvisioningScreen()));
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
                  child: Text("Thêm thiết bị"),
                ),
              ),
                SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}


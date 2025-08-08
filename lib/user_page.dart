import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'conn_IoT.dart';
import 'historyPage.dart';
import 'login_page.dart';
import 'UserInfoScreen.dart';
import 'DeviceManagementPage.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentSnapshot> getUserInfo() async {
    String uid = _auth.currentUser!.uid;
    return await _firestore.collection('khach hang').doc(uid).get();
  }

  Future<QuerySnapshot> getDevices() async {
    String uid = _auth.currentUser!.uid;
    return await _firestore.collection('cam bien').doc(uid).collection('device id').get();
  }

  Future<QuerySnapshot> getHistory() async {
    String uid = _auth.currentUser!.uid;
    return await _firestore.collection('lich su').doc(uid).collection('entries').orderBy('ngayThang', descending: true).get();
  }

    void showPopup(BuildContext context, Widget content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Đóng"),
          ),
        ],
      ),
    );
  }


  void showEditUserDialog(Map<String, dynamic> userData) {
    TextEditingController nameController = TextEditingController(text: userData['name']);
    TextEditingController emailController = TextEditingController(text: userData['email']);
    TextEditingController phoneController = TextEditingController(text: userData['phone']);
    TextEditingController addressController = TextEditingController(text: userData['address']);

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Chỉnh sửa thông tin"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Tên")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "SĐT")),
              TextField(controller: addressController, decoration: InputDecoration(labelText: "Địa chỉ")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                String uid = _auth.currentUser!.uid;
                if (emailController.text != userData['email']) {
                try {
                  await _auth.currentUser!.verifyBeforeUpdateEmail(emailController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Email xác nhận đã được gửi. Vui lòng kiểm tra hộp thư.")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Xác nhận email thất bại: $e")),
                  );
                  return;
                }
              }
                await _firestore.collection('khach hang').doc(uid).update({
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'address': addressController.text,
                });
                Navigator.pop(context);
              },
              child: Text("Lưu"),
            ),
          ],
        ),
      );
  }

    void resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email đặt lại mật khẩu đã được gửi.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  void confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đăng xuất", textAlign: TextAlign.center,),
        content: Text("Đăng xuất khỏi tài khoản của bạn?", textAlign: TextAlign.center,),
        actions: [
          TextButton(
            onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
                (route) => false,
              );
            },
            child: Text("Đăng xuất",style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Icon(icon, color: Colors.green[400]),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        // trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    String uid = _auth.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Người Dùng',
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
      body: Align(
          alignment: Alignment.center,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                _buildMenuCard(
                  context,
                  title: "Thông tin người dùng",
                  icon: Icons.person,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInfoScreen(uid: uid),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: "Quản lý thiết bị",
                  icon: Icons.thermostat,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceManagementPage(uid: uid),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: "Lịch sử cây trồng",
                  icon: Icons.history,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CropHistoryPage(uid: uid),
                      ),
                    );
                  },
                ),
                Spacer(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: confirmLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      overlayColor:Colors.white,
                    ),
                    child: Text(
                      "Đăng xuất",
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
          ),
        ),
      ),
    );
  }
}

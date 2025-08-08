import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserInfoScreen extends StatefulWidget {
  final String uid;
  UserInfoScreen({required this.uid});

  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> userData = {};
  String? editingField;
  TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('khach hang')
        .doc(widget.uid)
        .get();

    if (userSnapshot.exists) {
      setState(() {
        userData = userSnapshot.data() as Map<String, dynamic>;
      });
    }
  }

  void _startEditing(String field) {
    setState(() {
      editingField = field;
      textController.text = userData[field] ?? '';
    });
     
  }

  Future<void> _confirmEdit(String lable, String field) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        
        title: Text("Xác nhận chỉnh sửa",
                      textAlign: TextAlign.center, 
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
        content: Text("Bạn có chắc muốn thay đổi ${lable}?", textAlign: TextAlign.center,),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Lưu",style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm == true && field != "email") {
      await FirebaseFirestore.instance
          .collection('khach hang')
          .doc(widget.uid)
          .update({field: textController.text});

      setState(() {
        userData[field] = textController.text;
        editingField = null;
      });
    } else if (confirm == true && field == "email") {
      try {
        await _auth.currentUser!.verifyBeforeUpdateEmail(textController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Email xác nhận đã được gửi. Vui lòng kiểm tra hộp thư.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xác nhận email thất bại: $e")),
        );
        return;
      }
      await FirebaseFirestore.instance
          .collection('khach hang')
          .doc(widget.uid)
          .update({field: textController.text});

      setState(() {
        userData[field] = textController.text;
        editingField = null;
      });
    }
     else {
      setState(() {
        editingField = null;
      });
    }
  }

  Future<void> _verifyAndSaveEmail() async {
    try {
      await _auth.currentUser!.verifyBeforeUpdateEmail(textController.text);
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

  Future<void> _saveField(String field, String value) async {
    await FirebaseFirestore.instance
        .collection('khach_hang')
        .doc(widget.uid)
        .update({field: value});

    setState(() {
      userData[field] = value;
      editingField = null;
    });
  }

  void confirmReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đổi mật khẩu", textAlign: TextAlign.center,),
        content: Text("Đổi mật khẩu của bạn?", textAlign: TextAlign.center,),
        actions: [
          TextButton(
            onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              resetPassword();
              Navigator.of(context).pop(); 
            },
            child: Text("Đổi mật khẩu",style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoField(String label, String field) {
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: editingField == field
          ? TextField(
              cursorColor: Colors.green[300],
              controller: textController,
              autofocus: true,
              onSubmitted: (_) => _confirmEdit(label, field),
              // onEditingComplete: () => _confirmEdit(field),
            )
          : Text(userData[field] ?? "Chưa cập nhật"),
          
      trailing: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey[200],
        child: IconButton(
          iconSize: 16,
          icon: const Icon(Icons.edit, color: Colors.black), 
          onPressed: () => _startEditing(field),
        ),
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
          'Thông Tin Người Dùng',
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
      body: userData.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(bottom: 50),
                    child: ListView(
                      children: [
                        _buildUserInfoField("Họ tên", "name"),
                        // const Divider(),
                        _buildUserInfoField("Email", "email"),
                        _buildUserInfoField("Số điện thoại", "phone"),
                        _buildUserInfoField("Địa chỉ", "address"),
                      ],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    confirmReset();
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
                  child: Text("Đổi mật khẩu"),
                ),
                SizedBox(height: 20), // Khoảng cách dưới cùng
              ],
            ),
    );
  }
}

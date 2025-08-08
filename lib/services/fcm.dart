import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart.gitignore';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// import 'dart:async';


class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PushNotificationService pushNotificationService = PushNotificationService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Map<String, int?> lastStatus = {};
  // Map<String, StreamSubscription> listeners = {};
  // int? TTBom;
  // int? method;
  // int? getkho;
  // int? gettoi;
  // int? getuot;
  Map<String, double> lastkho = {};

  Future<String> _getDeviceName(String uid, String deviceId) async {
    try {
      DocumentSnapshot deviceDoc = await FirebaseFirestore.instance
          .collection("cam bien")
          .doc(uid)
          .collection('device id')
          .doc(deviceId)
          .get();

      if (deviceDoc.exists) {
        return deviceDoc["name"] ?? "Không xác định";
      } else {
        return "Không xác định";
      }
    } catch (e) {
      print("Lỗi khi lấy tên thiết bị: $e");
      return "Không xác định";
    }
  }

  void listenForChanges() async {
    String uid = _auth.currentUser!.uid;

    _db.ref("controlData/$uid").onChildAdded.listen((event) {
      String deviceId = event.snapshot.key!; 

      _db.ref("controlData/$uid/$deviceId/TTBom").onValue.listen((event) async {
        if (event.snapshot.value != null) {
          var TTBom = event.snapshot.value;
          int? bomStatus = int.tryParse(TTBom.toString());

          if (bomStatus != null) {
            int? lastStatus = await _getLastStatus(uid, deviceId);
          if (lastStatus == null || lastStatus != bomStatus) {
            await _saveLastStatus(uid, deviceId, bomStatus);
            String deviceName = await _getDeviceName(uid, deviceId);
              if (bomStatus == 0) {
                await sendNotificationToUser(uid, "Cảnh báo bơm", "Bơm đã tắt trên thiết bị $deviceName");
              } else if (bomStatus == 1) {
                await sendNotificationToUser(uid, "Cảnh báo bơm", "Bơm đã bật trên thiết bị $deviceName");
              }
            }
          }
        }
      });
    });



    // int previousCount = 0;
    // //Lắng nghe thay đổi từ collection "cam bien"
    // _firestore.collection("cam bien").doc(uid).collection("device id").snapshots().listen((querySnapshot) {
    //   int currentCount = querySnapshot.docs.length;

    //   if (currentCount > previousCount) {
    //     sendNotificationToUser(uid, "Thông báo", "Thiết bị mới đã được thêm!");
    //   } else if (currentCount < previousCount) {
    //     sendNotificationToUser(uid, "Thông báo", "Một thiết bị đã bị xóa!");
    //   }

    //   previousCount = currentCount; // Cập nhật số lượng mới
    // });

    //Lắng nghe thay đổi từ collection "lich su"
    // _firestore.collection("lich su").where("userId", isEqualTo: uid).snapshots().listen((querySnapshot) {
    //   for (var doc in querySnapshot.docs) {
    //     sendNotificationToUser(uid, "Cập nhật!", "Bạn có một bản ghi lịch sử mới.");
    //   }
    // });

    // //Lắng nghe thay đổi từ collection "thiet bi"
    // _firestore.collection("thiet bi").where("userId", isEqualTo: uid).snapshots().listen((querySnapshot) {
    //   for (var doc in querySnapshot.docs) {
    //     sendNotificationToUser(uid, "Thông báo!", "Có cập nhật mới trong danh sách thiết bị.");
    //   }
    // });
  }

  // Lưu trạng thái TTBom của từng thiết bị lên Firebase
  Future<void> _saveLastStatus(String uid, String deviceId, int status) async {
    await _db.ref("lastStatus/$uid/$deviceId").set(status);
  }

  // Lấy trạng thái trước đó từ Firebase
  Future<int?> _getLastStatus(String uid, String deviceId) async {
    DataSnapshot snapshot = await _db.ref("lastStatus/$uid/$deviceId").get();
    if (snapshot.exists) {
      return int.tryParse(snapshot.value.toString());
    }
    return null;
  }

  Future<void> sendNotificationToUser(String userId, String title, String body) async {
    DocumentSnapshot userDoc = await _firestore.collection("khach hang").doc(userId).get();

    if (userDoc.exists && userDoc["fcmTokens"] != null) {
      List<String> userTokens = List<String>.from(userDoc["fcmTokens"]);
      
      for (String token in userTokens) {
        await pushNotificationService.sendFCMNotification(title, body, token);
      }
    }
  }

}

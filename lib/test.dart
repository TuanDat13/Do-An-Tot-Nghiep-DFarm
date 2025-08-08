import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> fetchNotifications() {
    String uid = _auth.currentUser!.uid;
    return _firestore
        .collection('thong bao')
        .doc(uid)
        .collection('user_notifications')
        .orderBy('timestamp', descending: true) // Sắp xếp mới nhất
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          "title": doc["title"],
          "body": doc["body"],
          "timestamp": (doc["timestamp"] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.lightGreen);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Thông Báo',
          style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
                
              ),
        ),
      backgroundColor: Colors.white,
      centerTitle: true,
      ),
      backgroundColor: colorScheme.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Không có thông báo nào."));
          }

          final notifications = snapshot.data!;
          Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

          for (var notification in notifications) {
            String dateKey = DateFormat('dd/MM/yyyy').format(notification["timestamp"]);
            groupedNotifications.putIfAbsent(dateKey, () => []);
            groupedNotifications[dateKey]!.add(notification);
          }

          return ListView(
            children: groupedNotifications.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      entry.key,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                  ...entry.value.map((notification) {
                    return ListTile(
                      title: Text(notification["title"], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(notification["body"]),
                      trailing: Text(DateFormat('HH:mm').format(notification["timestamp"])),
                    );
                  }).toList()
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

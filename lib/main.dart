import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;
import 'login_page.dart';
import 'package:deadtime/services/notification_service.dart.gitignore';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Khởi tạo Firebase với cấu hình cho nền tảng web
  // await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //     apiKey: "AIzaSyDz8gPS9lcsaw9bdABa_WjAhdk7ZDLMknE",
  //   authDomain: "farmer-4a13c.firebaseapp.com",
  //   databaseURL: "https://farmer-4a13c-default-rtdb.asia-southeast1.firebasedatabase.app",
  //   projectId: "farmer-4a13c",
  //   storageBucket: "farmer-4a13c.firebasestorage.app",
  //   messagingSenderId: "566560509880",
  //   appId: "1:566560509880:web:90c75b603f972bb67dc94d",
  //   measurementId: "G-70QF6HL93K" // Có thể bỏ qua nếu không sử dụng Analytics
  //   ),
  // );

  if (Firebase.apps.isEmpty) {
    if (Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDz8gPS9lcsaw9bdABa_WjAhdk7ZDLMknE",
          authDomain: "farmer-4a13c.firebaseapp.com",
          databaseURL: "https://farmer-4a13c-default-rtdb.asia-southeast1.firebasedatabase.app",
          projectId: "farmer-4a13c",
          storageBucket: "farmer-4a13c.firebasestorage.app",
          messagingSenderId: "566560509880",
          appId: "1:566560509880:web:90c75b603f972bb67dc94d",
          measurementId: "G-70QF6HL93K",
        ),
      );
    }
  }

  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize(); // Khởi tạo thông báo
  pushNotificationService.listenToForegroundNotifications();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt banner debug
      title: 'Smart Agriculture App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: SignInScreen(), // Bắt đầu từ màn hình LoginPage
    );
  }
}

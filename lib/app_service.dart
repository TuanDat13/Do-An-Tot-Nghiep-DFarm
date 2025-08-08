import 'dart:convert';

import 'package:dio/dio.dart';

class ApiService {
  // Hàm gửi dữ liệu tới server
  static Future<void> sendDataUser(String uid, String name, String email, String phone, String password) async {
    final Dio dio = Dio();
    // Extract the string from the Uri object
    final urlString = 'http://dinok.infy.uk/htdocs/index.php'; 
    try {
      final response = await dio.post(
        urlString, // Use the string representation of the URL
        data: {
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('Response: ${response.data}');
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;

class DeviceService {
  
  Future<String?> getDeviceID(String? espIP) async {
    try {
      final url = Uri.parse("http://$espIP/getDeviceID"); // Đúng endpoint của ESP8266
      final response = await http.get(url); // Dùng GET thay vì POST

      if (response.statusCode == 200) {
        print("id được lưu thành công!");
        return response.body.trim(); // ESP8266 trả về ID dạng text
      } else {
        print("Lỗi khi lấy deviceID: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Lỗi khi gửi request: $e");
      return null;
    }
  }

  
  Future<bool> setUID(String? espIP, String uid) async {
    try {
      final url = Uri.parse("http://$espIP/setUID"); // Đúng endpoint của ESP8266
      final response = await http.post(
        url,
        headers: {"Content-Type": "text/plain"}, // Chỉ định kiểu dữ liệu
        body: uid, // Gửi UID trong body
      );

      if (response.statusCode == 200) {
        print("UID được lưu thành công!");
        return true;
      } else {
        print("Lỗi khi gửi UID: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Lỗi khi gửi request: $e");
      return false;
    }
  }
}

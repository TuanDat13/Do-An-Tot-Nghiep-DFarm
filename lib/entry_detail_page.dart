import 'package:flutter/material.dart';

class EntryDetailPage extends StatelessWidget {
  final Map<String, dynamic> entry;

  EntryDetailPage({required this.entry});

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis, // Hiển thị "..." nếu quá dài
              maxLines: 1, // Chỉ hiển thị 1 dòng
            ),
          ),
        ],
      ),
    );
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
        title: Text(
          entry['tieuDe'] ?? "Chi tiết nhật ký",
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          color: Colors.white,
          elevation: 2, 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow("Ngày tạo", _formatDate(entry['ngayThang'])),
                _buildInfoRow("Chỉ số N", entry['N']?.toString() ?? 'Không có'),
                _buildInfoRow("Chỉ số P", entry['P']?.toString() ?? 'Không có'),
                _buildInfoRow("Chỉ số K", entry['K']?.toString() ?? 'Không có'),

                SizedBox(height: 10),
                Text(
                  "Nội dung:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                ),
                SizedBox(height: 5),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    entry['ghiChu'] ?? 'Không có nội dung',
                    style: TextStyle(fontSize: 16),
                    softWrap: true, // Tự động xuống dòng
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

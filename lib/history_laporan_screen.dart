import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoryLaporanScreen extends StatefulWidget {
  final String emailUser; // KITA PAKAI EMAIL BIAR PRIVATE
  const HistoryLaporanScreen({super.key, required this.emailUser});

  @override
  State<HistoryLaporanScreen> createState() => _HistoryLaporanScreenState();
}

class _HistoryLaporanScreenState extends State<HistoryLaporanScreen> {
  List<dynamic> historyData = [];
  bool isLoading = true;
  
  // Warna Tema
  final Color bgTosca = const Color(0xFFB2DFDB);
  final Color primaryDark = const Color(0xFF00695C);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    // Request pakai parameter ?email=...
    final uri = Uri.parse("http://192.168.95.2:5000/api/riwayat-laporan?email=${widget.emailUser}");
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          historyData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    if (status.toLowerCase() == 'selesai') return Colors.green;
    if (status.toLowerCase() == 'diproses') return Colors.blue;
    return Colors.orange; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgTosca,
      appBar: AppBar(
        // Judul menampilkan email biar user yakin ini datanya dia
        title: Text("Riwayat: ${widget.emailUser}", style: TextStyle(color: primaryDark, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryDark),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryDark))
          : historyData.isEmpty
              ? Center(child: Text("Belum ada riwayat untuk email ini", style: TextStyle(color: primaryDark)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: historyData.length,
                  itemBuilder: (context, index) {
                    final item = historyData[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryDark.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item['jenis'] ?? 'Laporan', // AMBIL DARI DATABASE
                                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark, fontSize: 12),
                                  ),
                                ),
                                Text(item['tanggal'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item['deskripsi'] ?? '-', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Status:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(item['status'] ?? 'Pending'),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(item['status'] ?? 'Pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Import profile dihapus karena navigasi/foto sudah dihilangkan
// import 'profile.dart'; 

class HistoryLaporanScreen extends StatefulWidget {
  final int userId; 
  final String emailUser; 

  const HistoryLaporanScreen({
    super.key, 
    required this.userId, 
    required this.emailUser
  });

  @override
  State<HistoryLaporanScreen> createState() => _HistoryLaporanScreenState();
}

class _HistoryLaporanScreenState extends State<HistoryLaporanScreen> {
  List<dynamic> historyData = [];
  bool isLoading = true;
  // Variabel profileImageUrl dihapus
  
  // --- WARNA TEMA ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1);
  final Color cardGlass = Colors.white.withValues(alpha: 0.9);

  // URL Dasar API
  final String baseUrl = "http://192.168.1.7:5000";

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    // _fetchProfileImage() dihapus
  }

  // Fungsi _fetchProfileImage dihapus karena tidak lagi dipakai

  Future<void> _fetchHistory() async {
    final uri = Uri.parse("$baseUrl/api/riwayat-laporan?email=${widget.emailUser}");
    
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
      body: Stack(
        children: [
          // --- 1. BACKGROUND GRADIENT & DEKORASI ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF80CBC4), 
                  bgMintLight,             
                ],
              ),
            ),
          ),
          // Lingkaran Dekorasi 1
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Lingkaran Dekorasi 2
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      // --- CUSTOM HEADER ---
                      Row(
                        children: [
                          // Tombol Back
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          
                          const SizedBox(width: 15),
                          
                          // Teks Header
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Riwayat Laporan", 
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold, 
                                    color: Colors.white
                                  ),
                                ),
                                Text(
                                  widget.emailUser, // Subtitle Email
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12, 
                                    color: Colors.white70
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- FOTO PROFILE DIHAPUS DARI SINI ---
                        ],
                      ),
                      // --- END HEADER ---
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // --- LIST RIWAYAT ---
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : historyData.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_toggle_off, size: 60, color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Belum ada riwayat", 
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8))
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              itemCount: historyData.length,
                              itemBuilder: (context, index) {
                                final item = historyData[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardGlass, // Putih Modern
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: primaryTeal.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              item['jenis'] ?? 'Laporan', 
                                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            item['tanggal'] ?? '-', 
                                            style: TextStyle(fontSize: 12, color: Colors.grey[500])
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        item['deskripsi'] ?? '-', 
                                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87)
                                      ),
                                      const SizedBox(height: 15),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text("Status:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(item['status'] ?? 'Pending'),
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _getStatusColor(item['status'] ?? 'Pending').withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2)
                                                )
                                              ]
                                            ),
                                            child: Text(
                                              item['status'] ?? 'Pending', 
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
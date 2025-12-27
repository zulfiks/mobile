import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'tracking_screen.dart';

// Import profile dihapus karena navigasi/foto sudah dihilangkan
// import 'profile.dart';

class LariScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const LariScreen({super.key, required this.userId, required this.userName});

  @override
  State<LariScreen> createState() => _LariScreenState();
}

class _LariScreenState extends State<LariScreen> {
  // --- WARNA TEMA (TEAL FRESH & BUTTON BLUE) ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1);
  final Color btnBlue = const Color(0xFF29B6F6);

  bool isLariMode = true; // Default Lari

  // Variabel Data Hari Ini
  double todayDistance = 0.0;
  int todaySteps = 0;
  String todayDuration = "00:00:00";
  int todayCalories = 0;
  
  // List untuk History
  List<dynamic> historyList = [];
  bool isLoading = true;
  // Variabel profileImageUrl dihapus

  // URL Dasar API (Sesuaikan IP)
  final String baseUrl = "http://192.168.1.7:5000";

  @override
  void initState() {
    super.initState();
    _fetchData();
    // _fetchProfileImage() dihapus
  }

  // Fungsi _fetchProfileImage dihapus

  // --- FUNGSI AMBIL DATA & HISTORY ---
  Future<void> _fetchData() async {
    setState(() => isLoading = true);

    // Tambahkan timestamp agar tidak dicache browser/http client
    String apiUrl = "$baseUrl/api/lari/${widget.userId}?t=${DateTime.now().millisecondsSinceEpoch}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        List<dynamic> allData = jsonDecode(response.body);
        
        // 1. Ambil Tanggal Hari Ini (Format yyyy-MM-dd)
        String hariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        double tempJarak = 0;
        int tempKalori = 0;
        
        // 2. Loop data untuk hitung total hari ini
        for (var item in allData) {
          if (item['tanggal'] == hariIni) {
            double jarakItem = (item['jarak'] is int) 
                ? (item['jarak'] as int).toDouble() 
                : (item['jarak'] ?? 0.0);
            
            tempJarak += jarakItem;
            tempKalori += (item['kalori'] as int? ?? 0);
          }
        }

        // 3. LOGIKA SORTING (Terbaru di atas berdasarkan ID)
        allData.sort((a, b) {
          int idA = a['id'] ?? 0;
          int idB = b['id'] ?? 0;
          return idB.compareTo(idA); 
        });

        if (mounted) {
          setState(() {
            todayDistance = double.parse(tempJarak.toStringAsFixed(2));
            todayCalories = tempKalori;
            todaySteps = (todayDistance * 1300).toInt(); 
            
            historyList = allData; 
            isLoading = false;
          });
        }
      } else {
        debugPrint("Gagal ambil data: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error koneksi: $e");
      if (mounted) setState(() => isLoading = false);
    }
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
                  const Color(0xFF80CBC4), // Hijau Teal Segar
                  bgMintLight,             // Putih Mint
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
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

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
                              
                              // Teks Sapaan & Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Halo, ${widget.userName} 👋",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 18, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.white
                                      ),
                                    ),
                                    const Text(
                                      "Ayo bergerak hari ini!",
                                      style: TextStyle(
                                        fontSize: 14, 
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

                          const SizedBox(height: 30),

                          // 1. KARTU STATISTIK UTAMA
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryTeal, const Color(0xFF80CBC4)], 
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryTeal.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Aktivitas Hari Ini",
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$todayDistance km",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "$todaySteps Langkah",
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Icon(Icons.directions_run, color: Colors.white, size: 30),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _miniStat("Kalori", "$todayCalories Kcal", Icons.local_fire_department),
                                    _miniStat("Durasi", "Auto", Icons.timer), 
                                  ],
                                )
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // 2. TOMBOL AKSI (LARI / JALAN)
                          Row(
                            children: [
                              _buildModeButton("Jalan", false),
                              const SizedBox(width: 15),
                              _buildModeButton("Lari", true),
                            ],
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () async {
                                // Pindah ke halaman Tracking
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrackingScreen(userId: widget.userId),
                                  ),
                                );
                                // Jika kembali, refresh data
                                if (result == true || result == null) {
                                  _fetchData(); 
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 5,
                                shadowColor: Colors.black.withValues(alpha: 0.3),
                              ),
                              child: const Text(
                                "MULAI SEKARANG",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // 3. RIWAYAT AKTIVITAS
                          const Text(
                            "Riwayat Terakhir",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 15),

                          historyList.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text("Belum ada data lari.", style: TextStyle(color: Colors.grey)),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true, 
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: historyList.length > 5 ? 5 : historyList.length, 
                                  itemBuilder: (context, index) {
                                    var item = historyList[index];
                                    return _buildHistoryCard(item);
                                  },
                                ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Mini Statistik
  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        )
      ],
    );
  }

  // Widget Tombol Mode
  Widget _buildModeButton(String title, bool isLari) {
    bool isSelected = (isLariMode == isLari);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isLariMode = isLari),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? primaryTeal : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? primaryTeal : Colors.transparent),
            boxShadow: isSelected 
              ? [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Kartu History
  Widget _buildHistoryCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.history, color: primaryTeal),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['tanggal'] ?? "-",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "Durasi: ${item['waktu']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${item['jarak']} km",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
              Text(
                "+${item['kalori']} Kcal",
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          )
        ],
      ),
    );
  }
}
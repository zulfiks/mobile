import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- IMPORT HALAMAN ---
import 'login.dart';          
import 'profile.dart';        
import 'bmi_screen.dart';     
import 'laporan_screen.dart'; 
import 'artikel_screen.dart'; 
import 'makan_screen.dart';
import 'peta_screen.dart';   
import 'leaderboard_screen.dart'; // IMPORT FILE BARU TADI

class DashboardScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const DashboardScreen({super.key, this.userName = "User", this.userId = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Warna Utama (Hijau Tosca Fresh)
  final Color bgTosca = const Color(0xFFB2DFDB); 
  final Color primaryDark = const Color(0xFF00695C);
  final Color cardLeaderboardBg = const Color(0xFF00897B);

  double _savedBmi = 0;
  String _todayCalories = "0"; 
  List<dynamic> leaderboardData = [];
  int _selectedIndex = 2; 

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _loadBmiData();
    _fetchDailyCalories();
    _fetchLeaderboard();
  }

  Future<void> _loadBmiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedBmi = prefs.getDouble('bmi_score') ?? 0;
    });
  }

  Future<void> _fetchDailyCalories() async {
    final url = Uri.parse('http://192.168.95.2:5000/api/summary/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _todayCalories = (data['total_kalori'] ?? 0).toString();
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _fetchLeaderboard() async {
    final url = Uri.parse('http://192.168.95.2:5000/api/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        // Urutkan poin tertinggi
        users.sort((a, b) => (b['poin'] ?? 0).compareTo(a['poin'] ?? 0));
        setState(() {
          leaderboardData = users.take(5).toList(); // Ambil top 5 saja untuk podium
        });
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    if (index == 0) { // BMI
      Navigator.push(context, MaterialPageRoute(builder: (context) => BmiScreen(userId: widget.userId)))
      .then((_) => _loadBmiData());
    }
    if (index == 1) { // PETA
       Navigator.push(context, MaterialPageRoute(builder: (context) => PetaScreen(userId: widget.userId)));
    }
    if (index == 3) { // PROFIL/GERAK
       Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)));
    }
    if (index == 4) { // MAKAN
       Navigator.push(context, MaterialPageRoute(builder: (context) => MakanScreen(userId: widget.userId)))
       .then((_) {
          _fetchDailyCalories();
          _fetchLeaderboard();
       }); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgTosca, 
      extendBody: true, 
      body: Stack(
        children: [
          // --- BACKGROUND EFFECTS ---
          Positioned(
            top: -60, left: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            ),
          ),
          Positioned(
            top: 150, right: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(color: primaryDark.withValues(alpha: 0.05), shape: BoxShape.circle),
            ),
          ),

          // --- KONTEN UTAMA ---
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.spa, color: primaryDark),
                          ),
                          const SizedBox(width: 10),
                          Text("Healthify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryDark)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId))),
                        child: Row(
                          children: [
                            Text(widget.userName, style: TextStyle(fontWeight: FontWeight.bold, color: primaryDark)),
                            const SizedBox(width: 8),
                            const CircleAvatar(radius: 16, backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white, size: 20)), 
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // SAPAAN
                  Text("Hai, ${widget.userName}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
                  Text("Kamu hebat hari ini! 🔥", style: TextStyle(fontSize: 18, color: primaryDark.withValues(alpha: 0.7))),
                  
                  const SizedBox(height: 25),

                  // --- BAGIAN 1: PODIUM LEADERBOARD ---
                  // Saya beri tombol "Lihat Semua" di sini
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cardLeaderboardBg, const Color(0xFF26A69A)]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Top 5 Minggu Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            GestureDetector(
                              onTap: () {
                                // NAVIGASI KE HALAMAN BARU
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                child: Row(children: const [
                                  Text("Lihat Semua", style: TextStyle(color: Colors.white, fontSize: 10)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 10, color: Colors.white)
                                ]),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        // PODIUM GRAFIK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end, 
                          children: _buildPodiumList(),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST NAMA DIHAPUS DARI SINI ---
                  
                  const SizedBox(height: 30),

                  // --- BAGIAN 2: STATISTIK HARIAN (Tetap) ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard("Kalori Masuk", _todayCalories, Icons.local_fire_department, Colors.orange, Colors.orange[50]!),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard("BMI Kamu", _savedBmi > 0 ? _savedBmi.toStringAsFixed(1) : "-", Icons.monitor_weight, Colors.blue, Colors.blue[50]!),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  
                  // --- BAGIAN 3: MENU PINTAS (Tetap) ---
                  const Text("Jalan Pintas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFancyMenuCard("Peta", Icons.map_outlined, const Color(0xFF4FC3F7), () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => PetaScreen(userId: widget.userId)));
                      }),
                      _buildFancyMenuCard("Makan", Icons.restaurant_menu, const Color(0xFFAED581), () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => MakanScreen(userId: widget.userId)))
                         .then((_) { _fetchDailyCalories(); _fetchLeaderboard(); });
                      }),
                      _buildFancyMenuCard("Lari", Icons.directions_run, const Color(0xFFFFB74D), (){
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Lari segera hadir!")));
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- BAGIAN 4 & 5: ARTIKEL & BANTUAN (DIBUAT SEBELAHAN & UNIK) ---
                  Row(
                    children: [
                      // KOTAK ARTIKEL
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtikelScreen(userId: widget.userId))),
                          child: Container(
                            height: 140, // Tinggi kotak
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)], // Biru Langit
                                begin: Alignment.topLeft, end: Alignment.bottomRight
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Stack(
                              children: [
                                // Icon Transparan di Belakang (Biar unik)
                                Positioned(
                                  right: -10, bottom: -10,
                                  child: Icon(Icons.article_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                                      child: const Icon(Icons.library_books, color: Colors.white, size: 24),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text("Artikel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("Tips Sehat", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 15),

                      // KOTAK BANTUAN/LAPORAN
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LaporanScreen(userName: widget.userName))),
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFCC80), Color(0xFFFFA726)], // Orange Lembut
                                begin: Alignment.topLeft, end: Alignment.bottomRight
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Stack(
                              children: [
                                // Icon Transparan di Belakang
                                Positioned(
                                  right: -10, bottom: -10,
                                  child: Icon(Icons.support_agent, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle),
                                      child: const Icon(Icons.headset_mic, color: Colors.white, size: 24),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text("Bantuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("Lapor Kendala", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // --- END OF ARTIKEL & BANTUAN ---

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.monitor_weight_outlined, 0, "BMI"),
            _buildNavItem(Icons.map_outlined, 1, "Peta"),
            _buildNavItem(Icons.home_rounded, 2, "Home", isMain: true),
            _buildNavItem(Icons.directions_run, 3, "Gerak"),
            _buildNavItem(Icons.restaurant_menu, 4, "Makan"),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PODIUM (Tetap Sama) ---
  List<Widget> _buildPodiumList() {
    if (leaderboardData.isEmpty) return [const Text("Belum ada data", style: TextStyle(color: Colors.white))];
    List<Widget> bars = [];
    for (int i = 0; i < leaderboardData.length; i++) {
      var user = leaderboardData[i];
      int rank = i + 1;
      double height = (rank == 1) ? 140 : (rank == 2 ? 100 : (rank == 3 ? 80 : 50));
      Color color = (rank == 1) ? Colors.amber : Colors.white.withValues(alpha: 0.8);

      bars.add(Column(
        children: [
          CircleAvatar(
            radius: 14, 
            backgroundColor: Colors.white, 
            child: rank <= 3 ? const Icon(Icons.emoji_events, size: 16, color: Colors.orange) : null
          ),
          const SizedBox(height: 5),
          Text(user['nama'].length > 6 ? user['nama'].substring(0,5) : user['nama'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 5),
          Container(
            width: 45, 
            height: height, 
            decoration: BoxDecoration(
              color: color, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5)]
            ), 
            child: Center(child: Text("${user['poin']}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rank==1 ? Colors.white : Colors.teal[900])))
          ),
        ],
      ));
    }
    if (bars.length >= 2) { var temp = bars[0]; bars[0] = bars[1]; bars[1] = temp; }
    return bars;
  }

  Widget _buildFancyMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label, {bool isMain = false}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: EdgeInsets.all(isMain ? 12 : 8), 
          decoration: BoxDecoration(
            color: isMain ? const Color(0xFF263238) : (isSelected ? const Color(0xFFE0F2F1) : Colors.transparent), 
            shape: BoxShape.circle
          ), 
          child: Icon(icon, color: isMain ? Colors.white : (isSelected ? Colors.teal : Colors.grey), size: isMain ? 28 : 24)
        ), 
        if (!isMain && isSelected) Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal))
      ]),
    );
  }
}
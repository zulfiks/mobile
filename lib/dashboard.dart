import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- IMPORT HALAMAN ---
import 'profile.dart';
import 'bmi_screen.dart';
import 'laporan_screen.dart';
import 'artikel_screen.dart';
import 'makan_screen.dart';
import 'peta_screen.dart'; 
import 'leaderboard_screen.dart';
import 'lari.dart'; 

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
  int _selectedIndex = 2; // Default ke Home (Tengah)

  // --- VARIABEL UNTUK NAMA & FOTO ---
  String _currentName = "";
  String? _userPhoto; 
  String? _token; 

  // --- SETTING IP ADDRESS (Ganti sesuai IP Laptop) ---
  final String _baseUrl = "http://192.168.1.7:5000"; 

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    await _loadToken(); 
    _loadBmiData();
    _fetchDailyCalories();
    _fetchLeaderboard();
    _fetchUserProfile();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token'); 
    });
  }

  Future<void> _fetchUserProfile() async {
    final url = Uri.parse('$_baseUrl/api/users/${widget.userId}?t=${DateTime.now().millisecondsSinceEpoch}');
    try {
      final response = await http.get(
        url,
        headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _currentName = data['nama'] ?? widget.userName;
            _userPhoto = data['foto']; 
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi profil: $e");
    }
  }

  Future<void> _loadBmiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedBmi = prefs.getDouble('bmi_score') ?? 0;
    });
  }

  Future<void> _fetchDailyCalories() async {
    final url = Uri.parse('$_baseUrl/api/summary/${widget.userId}');
    try {
      final response = await http.get(
        url,
        headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _todayCalories = (data['total_kalori'] ?? 0).toString();
        });
      }
    } catch (e) {
      debugPrint("Error Calories: $e");
    }
  }

  Future<void> _fetchLeaderboard() async {
    final url = Uri.parse('$_baseUrl/api/users');
    try {
      final response = await http.get(
        url,
        headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
      );

      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        users.sort((a, b) => (b['poin'] ?? 0).compareTo(a['poin'] ?? 0));
        setState(() {
          leaderboardData = users.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint("Error Leaderboard: $e");
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.push(context,
              MaterialPageRoute(builder: (context) => BmiScreen(userId: widget.userId)))
          .then((_) => _loadBmiData());
    }
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => PetaScreen(userId: widget.userId)));
    }
    // INDEX 2 = HOME
    if (index == 3) {
       Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LariScreen(
            userId: widget.userId,
            userName: _currentName,
          )),
        ).then((_) {
          _fetchDailyCalories();
          _fetchLeaderboard();
        });
    }
    if (index == 4) {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => MakanScreen(userId: widget.userId))).then((_) {
        _fetchDailyCalories();
        _fetchLeaderboard();
      });
    }
  }

  ImageProvider? _getProfileImage() {
    if (_userPhoto != null && _userPhoto!.isNotEmpty) {
      if (_userPhoto!.startsWith('http')) {
        return NetworkImage(_userPhoto!);
      } else {
        return NetworkImage('$_baseUrl/static/uploads/$_userPhoto');
      }
    }
    return null;
  }

  ImageProvider? _getAvatarImage(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      } else {
        return NetworkImage('$_baseUrl/static/uploads/$photoUrl');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgTosca,
      extendBody: true,
      body: Stack(
        children: [
          // BACKGROUND EFFECTS
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

          // KONTEN UTAMA
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
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.spa, color: primaryDark),
                          ),
                          const SizedBox(width: 10),
                          Text("Healthify",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryDark)),
                        ],
                      ),
                      
                      // FOTO PROFIL
                      GestureDetector(
                        onTap: () {
                           Navigator.push(context,
                              MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId))).then((_) {
                            _fetchUserProfile(); 
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)]
                          ),
                          child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.orange,
                              backgroundImage: _getProfileImage(), 
                              child: _getProfileImage() == null 
                                ? const Icon(Icons.person, color: Colors.white, size: 24) 
                                : null
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),

                  Text("Hai, $_currentName",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDark)),
                  Text("Kamu hebat hari ini! 🔥",
                      style: TextStyle(fontSize: 18, color: primaryDark.withValues(alpha: 0.7))),

                  const SizedBox(height: 25),

                  // LEADERBOARD CHART (PIRAMIDA)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [cardLeaderboardBg, const Color(0xFF26A69A)]),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Top 5 Minggu Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => LeaderboardScreen(userId: widget.userId)));
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
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: _buildPodiumList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // STATISTIK
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Kalori Masuk", _todayCalories, Icons.local_fire_department, Colors.orange, Colors.orange[50]!)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildStatCard("BMI Kamu", _savedBmi > 0 ? _savedBmi.toStringAsFixed(1) : "-", Icons.monitor_weight, Colors.blue, Colors.blue[50]!)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // MENU PINTAS
                  const Text("Fitur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFancyMenuCard("Cek BMI", Icons.monitor_weight_outlined, const Color(0xFF4FC3F7), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => BmiScreen(userId: widget.userId))).then((_) => _loadBmiData());
                      }),
                      _buildFancyMenuCard("Makan", Icons.restaurant_menu, const Color(0xFFAED581), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MakanScreen(userId: widget.userId))).then((_) {
                          _fetchDailyCalories();
                          _fetchLeaderboard();
                        });
                      }),
                      _buildFancyMenuCard("Lari", Icons.directions_run, const Color(0xFFFFB74D), () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => LariScreen(userId: widget.userId, userName: _currentName))).then((_) {
                            _fetchDailyCalories();
                            _fetchLeaderboard();
                        });
                      }),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ARTIKEL & BANTUAN
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtikelScreen(userId: widget.userId))),
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Stack(
                              children: [
                                Positioned(right: -10, bottom: -10, child: Icon(Icons.article_outlined, size: 80, color: Colors.white.withValues(alpha: 0.2))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle), child: const Icon(Icons.library_books, color: Colors.white, size: 24)),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                        Text("Artikel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("Tips Sehat", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ])
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LaporanScreen(userName: _currentName, userId: widget.userId))),
                          child: Container(
                            height: 140,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFFCC80), Color(0xFFFFA726)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Stack(
                              children: [
                                Positioned(right: -10, bottom: -10, child: Icon(Icons.support_agent, size: 80, color: Colors.white.withValues(alpha: 0.2))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle), child: const Icon(Icons.headset_mic, color: Colors.white, size: 24)),
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                        Text("Bantuan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text("Lapor Kendala", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    ])
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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

  // --- WIDGET HELPER ---
  List<Widget> _buildPodiumList() {
    if (leaderboardData.isEmpty) {
      return [const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.white)))];
    }

    List<Widget> podiumWidgets = [];
    
    // Urutan Visual Piramida
    List<int> visualOrder = [3, 1, 0, 2, 4];

    for (int index in visualOrder) {
      if (index < leaderboardData.length) {
        var user = leaderboardData[index];
        int rank = index + 1;
        podiumWidgets.add(_buildBarItem(user, rank));
      }
    }
    return podiumWidgets;
  }

  Widget _buildBarItem(dynamic user, int rank) {
    double height;
    
    // PERBAIKAN: Menggunakan blok {} untuk if-else
    if (rank == 1) {
      height = 140;
    } else if (rank == 2) {
      height = 110;
    } else if (rank == 3) {
      height = 90;
    } else {
      height = 60;
    }

    Color barColor = (rank == 1) ? Colors.amber : Colors.white.withValues(alpha: 0.9);
    Color textColor = (rank == 1) ? Colors.white : Colors.teal[900]!;
    String? photoUrl = user['foto'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // FOTO
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rank == 1 ? Colors.amber : Colors.white.withValues(alpha: 0.8), 
              width: 2
            ),
            boxShadow: [
              if (rank == 1) BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10)
            ]
          ),
          child: CircleAvatar(
            radius: rank == 1 ? 22 : 18, 
            backgroundColor: Colors.grey[200],
            backgroundImage: _getAvatarImage(photoUrl),
            child: _getAvatarImage(photoUrl) == null
                ? (rank <= 3
                    ? Icon(Icons.emoji_events, size: 18, color: rank == 1 ? Colors.amber : Colors.orange)
                    : Text("$rank", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)))
                : null,
          ),
        ),

        // NAMA
        Text(
          user['nama'].length > 6 ? user['nama'].substring(0, 5) : user['nama'],
          style: TextStyle(
            fontSize: 10, 
            fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal, 
            color: Colors.white
          )
        ),
        
        const SizedBox(height: 5),

        // BATANG
        Container(
          width: 45, 
          height: height,
          decoration: BoxDecoration(
            color: barColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5)]
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, 
            children: [
              const SizedBox(height: 8),
              Text(
                "${user['poin']}", 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)
              ),
              if (rank == 1) 
                 const Padding(
                   padding: EdgeInsets.only(top: 2),
                   child: Icon(Icons.star, size: 10, color: Colors.white),
                 )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFancyMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 100, height: 110,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, size: 28, color: color)),
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
      child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ])
      ]),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label, {bool isMain = false}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            padding: EdgeInsets.all(isMain ? 12 : 8),
            decoration: BoxDecoration(color: isMain ? const Color(0xFF263238) : (isSelected ? const Color(0xFFE0F2F1) : Colors.transparent), shape: BoxShape.circle),
            child: Icon(icon, color: isMain ? Colors.white : (isSelected ? Colors.teal : Colors.grey), size: isMain ? 28 : 24)),
        if (!isMain && isSelected) Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal))
      ]),
    );
  }
}
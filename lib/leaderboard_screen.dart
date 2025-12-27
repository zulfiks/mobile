import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  final int userId; 
  const LeaderboardScreen({super.key, required this.userId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // --- WARNA TEMA ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1);
  
  List<dynamic> leaderboardData = [];
  bool isLoading = true;
  String userName = "User"; // Default nama

  // IP ADDRESS (Pastikan sama dengan di profile.dart)
  final String baseUrl = 'http://192.168.1.7:5000';

  @override
  void initState() {
    super.initState();
    _loadUserData();      
    _fetchLeaderboard();  
  }

  // 1. Ambil Nama User yang sedang login
  Future<void> _loadUserData() async {
    try {
      final url = Uri.parse('$baseUrl/api/users/${widget.userId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted && data['nama'] != null) {
          setState(() {
            userName = data['nama'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error load user: $e");
    }
  }

  // 2. Ambil Data Leaderboard (List Semua User)
  Future<void> _fetchLeaderboard() async {
    // Tambahkan timestamp agar tidak cache
    final url = Uri.parse('$baseUrl/api/users?t=${DateTime.now().millisecondsSinceEpoch}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        // Urutkan poin tertinggi ke terendah
        users.sort((a, b) => (b['poin'] ?? 0).compareTo(a['poin'] ?? 0));
        setState(() {
          leaderboardData = users;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- 1. BACKGROUND ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF80CBC4), bgMintLight],
              ),
            ),
          ),
          // Dekorasi Lingkaran
          Positioned(top: -50, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)))),
          Positioned(bottom: 100, left: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.tealAccent.withValues(alpha: 0.1)))),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Halo, $userName...", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text("Top Leaderboard 🏆", style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // List Ranking
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: leaderboardData.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 15),
                          itemBuilder: (context, index) {
                            final user = leaderboardData[index];
                            // Passing data foto ke widget _buildRankTile
                            return _buildRankTile(
                              index + 1, 
                              user['nama'] ?? "No Name", 
                              user['poin'] ?? 0, 
                              user['foto'] // Data foto dari database
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

  // Helper untuk mendapatkan Gambar (Logic sama dengan profile.dart)
  ImageProvider? _getAvatarImage(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (!photoUrl.startsWith('http')) {
        // Jika hanya nama file, tambahkan base url upload
        return NetworkImage('$baseUrl/static/uploads/$photoUrl');
      }
      // Jika url lengkap (misal dari google login)
      return NetworkImage(photoUrl);
    }
    return null; // Return null jika tidak ada foto
  }

  Widget _buildRankTile(int rank, String name, int points, String? photoUrl) {
    Color medalColor = Colors.grey[300]!;
    double elevation = 2;

    // Logika Warna Medali
    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Emas
      elevation = 8;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Perak
      elevation = 4;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Perunggu
      elevation = 4;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, elevation))],
        border: rank <= 3 ? Border.all(color: medalColor, width: 2) : null,
      ),
      child: Row(
        children: [
          // 1. Icon Peringkat (Angka/Piala)
          SizedBox(
            width: 30, 
            child: Center(
              child: rank <= 3 
                ? Icon(Icons.emoji_events, color: medalColor, size: 28)
                : Text("#$rank", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 16)),
            ),
          ),
          
          const SizedBox(width: 10),

          // 2. FOTO PROFILE (NEW)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryTeal.withValues(alpha: 0.5), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 22, // Ukuran Avatar
              backgroundColor: Colors.grey[200],
              backgroundImage: _getAvatarImage(photoUrl),
              child: _getAvatarImage(photoUrl) == null 
                  ? Icon(Icons.person, color: Colors.grey[400]) 
                  : null,
            ),
          ),

          const SizedBox(width: 12),
          
          // 3. Nama User
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                if (rank == 1)
                  const Text("Sang Juara! 🔥", style: TextStyle(fontSize: 10, color: Colors.orange))
              ],
            ),
          ),
          
          // 4. Poin Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: primaryTeal),
                const SizedBox(width: 4),
                Text(
                  "$points", 
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 13)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
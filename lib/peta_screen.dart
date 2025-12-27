import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PetaScreen extends StatefulWidget {
  final int userId;
  const PetaScreen({super.key, required this.userId});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  int userPoints = 0;
  bool isLoading = true;

  // KONFIGURASI GAME: 300 Poin = 1 Pulau Terbuka
  final int pointsPerLevel = 300;

  // DAFTAR PULAU BESAR
  final List<Map<String, String>> islandList = [
    {"name": "Sumatera", "desc": "Gerbang Barat Indonesia"},
    {"name": "Jawa & Bali", "desc": "Jantung Nusantara"},
    {"name": "Kalimantan", "desc": "Paru-Paru Dunia"},
    {"name": "Sulawesi", "desc": "Pulau Anggrek"},
    {"name": "Nusa Tenggara", "desc": "Kepulauan Sunda Kecil"},
    {"name": "Maluku", "desc": "Kepulauan Rempah"},
    {"name": "Papua", "desc": "Mutiara Hitam"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    final url = Uri.parse('http://192.168.1.7:5000/api/users/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userPoints = data['poin'] ?? 0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int unlockedIndex = (userPoints / pointsPerLevel).floor();
    if (unlockedIndex >= islandList.length) unlockedIndex = islandList.length - 1;

    String currentIsland = islandList[unlockedIndex]['name']!;
    
    int pointsInCurrentLevel = userPoints % pointsPerLevel;
    double progressPercent = pointsInCurrentLevel / pointsPerLevel;
    if (unlockedIndex == islandList.length - 1) progressPercent = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withValues(alpha: 0.2))),
          Positioned(bottom: 50, left: -50, child: CircleAvatar(radius: 80, backgroundColor: Colors.teal.withValues(alpha: 0.1))),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- 1. HEADER TOMBOL BACK (INI YANG BARU) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      // Tombol Back Bulat
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.teal),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "Peta Jelajah 🗺️", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)
                      ),
                    ],
                  ),
                ),

                // --- 2. KARTU INFO STATUS ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Lokasi Saat Ini:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(currentIsland, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                              child: Column(
                                children: [
                                  Text("$userPoints", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                  const Text("POIN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Next: ${unlockedIndex + 1 < islandList.length ? islandList[unlockedIndex + 1]['name'] : 'Selesai!'}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text("$pointsInCurrentLevel/$pointsPerLevel", style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 3. LIST PULAU BESAR ---
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: islandList.length,
                    itemBuilder: (context, index) {
                      bool isUnlocked = index <= unlockedIndex;
                      bool isCurrent = index == unlockedIndex;
                      return _buildIslandCard(index, islandList[index], isUnlocked, isCurrent);
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

  Widget _buildIslandCard(int index, Map<String, String> island, bool isUnlocked, bool isCurrent) {
    Color cardColor = isUnlocked ? Colors.white : Colors.grey[200]!;
    if (isCurrent) cardColor = const Color(0xFFE0F2F1);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indikator Kiri
          Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.orange : (isUnlocked ? Colors.teal : Colors.grey[300]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 5)]
                ),
                child: Center(
                  child: isUnlocked 
                    ? const Icon(Icons.map, color: Colors.white, size: 24)
                    : const Icon(Icons.lock, color: Colors.white70, size: 24),
                ),
              ),
              if (index != islandList.length - 1)
                Expanded(
                  child: Container(width: 4, color: isUnlocked ? Colors.teal.withValues(alpha: 0.5) : Colors.grey[300]),
                ),
            ],
          ),
          const SizedBox(width: 15),

          // Kartu Pulau
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: isUnlocked ? [BoxShadow(color: Colors.teal.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3))] : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCurrent ? "MENJELAJAH..." : (isUnlocked ? "TERBUKA" : "TERKUNCI"), 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCurrent ? Colors.orange : Colors.teal)
                      ),
                      if (isCurrent) const Icon(Icons.flag, color: Colors.orange)
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(island['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isUnlocked ? Colors.black87 : Colors.grey)),
                  Text(island['desc']!, style: TextStyle(fontSize: 12, color: isUnlocked ? Colors.black54 : Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
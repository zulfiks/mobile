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

  // Leveling System: Tiap 100 Poin = 1 Provinsi
  int pointsPerLevel = 100;
  
  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    // Ganti IP sesuai laptopmu
    final url = Uri.parse('http://192.168.95.2:5000/api/users/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userPoints = data['poin'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logika Leveling
    int currentLevel = (userPoints / pointsPerLevel).floor();
    int nextLevelTarget = (currentLevel + 1) * pointsPerLevel;
    int progressPoints = userPoints % pointsPerLevel;
    double progressPercent = progressPoints / pointsPerLevel;

    // Nama Provinsi (Simulasi Urutan)
    List<String> provinsi = ["Jawa Timur", "Jawa Tengah", "Jawa Barat", "DKI Jakarta", "Bali", "Sumatera"];
    String unlockedProv = (currentLevel > 0 && currentLevel <= provinsi.length) 
        ? provinsi[currentLevel - 1] 
        : "Indonesia";
    String nextProv = (currentLevel < provinsi.length) ? provinsi[currentLevel] : "Selesai";

    return Scaffold(
      backgroundColor: const Color(0xFFB2DFDB), // Warna latar hijau tosca muda (sesuai foto)
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER TEXT
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("zul", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        const CircleAvatar(radius: 15, backgroundColor: Colors.orange, child: Icon(Icons.face, size: 20, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Ayo Semangat lengkapi\npeta indonesiamu",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "kumpulkan poin dari langkah lari dan makanan\nsehat untuk membuka wilayah baru",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // 2. AREA PETA & POPUP
              Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA), // Biru langit muda
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Stack(
                  children: [
                    // GAMBAR PETA (Placeholder)
                    Center(
                      child: Icon(Icons.map_outlined, size: 200, color: Colors.grey[400]),
                      // Nanti ganti dengan: Image.asset('assets/peta.png')
                    ),
                    
                    // POPUP "SELAMAT" (Sesuai Foto)
                    if (userPoints > 0)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Selamat!", style: TextStyle(fontWeight: FontWeight.bold)),
                              const Text("Kamu membuka\nprovinsi baru!!!", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 5),
                              Text("“$unlockedProv”", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. TOMBOL ACTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF29B6F6), // Biru tombol
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Jalan/lari", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF29B6F6),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. PROGRESS BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 15,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Ayo semangat poin : $userPoints/$nextLevelTarget lagi kamu membuka provinsi $nextProv",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 5. LEGEND (Bottom Sheet Style)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFB3E5FC), // Biru muda banget
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Icons.do_not_step, "Jalan Kaki\n+10 poin"),
                    _buildLegendItem(Icons.directions_run, "Lari\n+20 poin"),
                    _buildLegendItem(Icons.restaurant, "Makan\nIdeal\n+5 poin"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.black54),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
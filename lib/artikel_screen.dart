import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // Wajib tambahkan di pubspec.yaml jika mau link jalan

class ArtikelScreen extends StatefulWidget {
  final int userId;
  const ArtikelScreen({super.key, required this.userId});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  // Warna Desain
  final Color bgLight = const Color(0xFFF0F8F8);
  final Color primaryTeal = const Color(0xFF80CBC4);
  
  List<dynamic> allArticles = [];
  List<dynamic> filteredArticles = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  // Ambil Data dari API
  Future<void> _fetchArticles() async {
    // IP LAPTOP: 192.168.1.4
    final url = Uri.parse('http://192.168.95.2:5000/api/konten');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          allArticles = jsonDecode(response.body);
          filteredArticles = allArticles; // Awalnya tampilkan semua
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // Fungsi Search
  void _filterArticles(String query) {
    setState(() {
      filteredArticles = allArticles.where((article) {
        final title = article['judul'].toString().toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  // Fungsi Buka Link
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Stack(
        children: [
          // --- 1. DEKORASI BACKGROUND (Anti-Boring) ---
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withValues(alpha: 0.1),
                boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.1), blurRadius: 60)],
              ),
            ),
          ),
          Positioned(
            bottom: 100, left: -40,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.05),
                boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.05), blurRadius: 50)],
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header & Avatar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(), // Spacer kiri
                      GestureDetector(
                        onTap: () => Navigator.pop(context), // Balik ke Dashboard
                        child: Row(
                          children: const [
                            Text("Back", style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            CircleAvatar(radius: 18, backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Artikel Buat Motivasi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("Lihat tips makanan olahraga dll disini", style: TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: _filterArticles,
                    decoration: InputDecoration(
                      hintText: "Cari Disini",
                      prefixIcon: const Icon(Icons.search), // Kalo mau ikon di kanan pakai suffixIcon
                      suffixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Grid Artikel
                  Expanded(
                    child: isLoading 
                      ? const Center(child: CircularProgressIndicator()) 
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 Kolom
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 0.75, // Perbandingan tinggi lebar kartu
                          ),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final item = filteredArticles[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 3))]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gambar Artikel
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                        image: DecorationImage(
                                          image: NetworkImage(item['foto'] ?? "https://via.placeholder.com/150"), // Default jika kosong
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Teks Judul & Tombol
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['judul'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text("By. ${item['kategori']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        
                                        // Tombol Baca
                                        SizedBox(
                                          width: double.infinity,
                                          height: 30,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // Buka Link jika ada
                                              if (item['tautan'] != null) _launchURL(item['tautan']);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF29B6F6), // Biru Muda
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Text("Baca selengkapnya", style: TextStyle(fontSize: 10, color: Colors.white)),
                                          ),
                                        )
                                      ],
                                    ),
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
          ),
        ],
      ),
    );
  }
}
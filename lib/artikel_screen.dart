import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

class ArtikelScreen extends StatefulWidget {
  final int userId;
  const ArtikelScreen({super.key, required this.userId});

  @override
  State<ArtikelScreen> createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  // --- WARNA TEMA ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1);
  final Color btnBlue = const Color(0xFF29B6F6);

  List<dynamic> allArticles = [];
  List<dynamic> filteredArticles = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  // Data User untuk Header
  String userName = "User"; 
  
  // IP ADDRESS (Sesuaikan dengan IP Laptop/Server)
  final String baseUrl = 'http://192.168.1.7:5000';

  @override
  void initState() {
    super.initState();
    _loadUserData();    // Ambil Nama User
    _fetchArticles();   // Ambil Artikel
  }

  // 1. Ambil Data User (Hanya Nama)
  Future<void> _loadUserData() async {
    try {
      final url = Uri.parse('$baseUrl/api/users/${widget.userId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userName = data['nama'] ?? "User";
          });
        }
      }
    } catch (e) {
      debugPrint("Error load user: $e");
    }
  }

  // 2. Ambil Artikel dari API
  Future<void> _fetchArticles() async {
    final url = Uri.parse('$baseUrl/api/konten');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          allArticles = jsonDecode(response.body);
          filteredArticles = allArticles; 
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error article: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 3. Fungsi Search
  void _filterArticles(String query) {
    setState(() {
      filteredArticles = allArticles.where((article) {
        final title = article['judul'].toString().toLowerCase();
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  // 4. Fungsi Buka Link
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // --- HEADER CUSTOM (TANPA FOTO PROFILE) ---
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 15),
                      
                      // Teks Sapaan & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, $userName...", 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const Text(
                              "Artikel & Motivasi", // Subtitle
                              style: TextStyle(
                                fontSize: 14, 
                                color: Colors.white70
                              ),
                            ),
                          ],
                        ),
                      ),
                      // FOTO PROFILE TELAH DIHAPUS DARI SINI
                    ],
                  ),
                  // --- END HEADER ---

                  const SizedBox(height: 25),

                  // Search Bar
                  TextField(
                    controller: searchController,
                    onChanged: _filterArticles,
                    decoration: InputDecoration(
                      hintText: "Cari tips kesehatan...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: primaryTeal),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Grid Artikel
                  Expanded(
                    child: isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                      : (filteredArticles.isEmpty 
                          ? Center(child: Text("Tidak ada artikel ditemukan", style: TextStyle(color: Colors.white.withValues(alpha: 0.8))))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, 
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 0.75, 
                              ),
                              itemCount: filteredArticles.length,
                              itemBuilder: (context, index) {
                                final item = filteredArticles[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9), // Sedikit transparan
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Gambar Artikel
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                            image: DecorationImage(
                                              // Handle gambar null dengan placeholder
                                              image: NetworkImage(item['foto'] != null && item['foto'].isNotEmpty 
                                                  ? item['foto'] 
                                                  : "https://via.placeholder.com/150"), 
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // Teks Judul & Tombol
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['judul'], 
                                              maxLines: 2, 
                                              overflow: TextOverflow.ellipsis, 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "By. ${item['kategori']}", 
                                              style: const TextStyle(fontSize: 10, color: Colors.grey)
                                            ),
                                            const SizedBox(height: 10),
                                            
                                            // Tombol Baca
                                            SizedBox(
                                              width: double.infinity,
                                              height: 35,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  if (item['tautan'] != null) {
                                                    _launchURL(item['tautan']);
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: btnBlue,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  elevation: 0,
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: const Text("BACA", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            )
                        ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
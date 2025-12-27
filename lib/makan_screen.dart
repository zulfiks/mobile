import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Import file scan camera yang baru dibuat
import 'scan_camera.dart'; 

class MakanScreen extends StatefulWidget {
  final int userId;
  const MakanScreen({super.key, required this.userId});

  @override
  State<MakanScreen> createState() => _MakanScreenState();
}

class _MakanScreenState extends State<MakanScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  Timer? _debounce;
  bool isLoading = false;
  bool hasSearched = false;
  
  String userName = "Rizki Cahya Zulfikar"; 

  // IP ADDRESS (Sesuaikan dengan IP laptop kamu)
  final String baseUrl = 'http://192.168.1.7:5000'; 

  Map<String, dynamic> dailySummary = {
    "total_kalori": 0,
    "target_kalori": 2000,
    "status_gizi": "Menghitung...",
    "poin_hari_ini": 0,
    "pesan": "Ayo mulai makan sehat!",
    "pagi": [],
    "siang": [],
    "malam": []
  };

  final Color primaryTeal = const Color(0xFF4DB6AC); 
  final Color bgMintLight = const Color(0xFFE0F2F1); 
  final Color colorProtein = const Color(0xFF42A5F5); 
  final Color colorCarb = const Color(0xFF66BB6A);    
  final Color colorFat = const Color(0xFFFFA726);     

  @override
  void initState() {
    super.initState();
    _loadUserData();      
    _fetchDailySummary(); 
  }

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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.isNotEmpty) {
        _searchFood(query);
      }
    });
  }

  Future<void> _searchFood(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
      searchResults = []; 
    });

    final url = Uri.parse('$baseUrl/api/makanan/search?q=$query');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          searchResults = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Koneksi Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- FUNGSI BARU: PROSES HASIL SCAN AI ---
  Future<void> _processScanResult(String foodName) async {
    // Tampilkan Loading saat mencari data nutrisi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Cari detail nutrisi ke API berdasarkan nama dari AI (misal: "Nasi Goreng")
      final url = Uri.parse('$baseUrl/api/makanan/search?q=$foodName');
      final response = await http.get(url);

      if (!mounted) return;
      Navigator.pop(context); // Tutup Loading

      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);

        if (results.isNotEmpty) {
          // 2. Ambil data pertama yang paling cocok
          var foodItem = results[0]; 

          // 3. Langsung Buka Form Input (Biar user tinggal pilih jam & save)
          _showInputForm(foodItem);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("AI Sukses! Makanan terdeteksi: $foodName"),
            backgroundColor: Colors.green,
          ));
        } else {
          _showNotFoundDialog(foodName);
        }
      }
    } catch (e) {
      Navigator.pop(context); 
      debugPrint("Error processing scan: $e");
    }
  }

  void _showNotFoundDialog(String foodName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Belum Ada Data"),
        content: Text("AI mengenali ini sebagai '$foodName', tapi data gizinya belum ada di database admin."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Oke"))
        ],
      ),
    );
  }
  // ---------------------------------------------

  Future<void> _addFood(Map<String, dynamic> foodItem, String waktu) async {
    final url = Uri.parse('$baseUrl/api/riwayat/makan');
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "nama_makanan": foodItem['name'],      
          "kalori": foodItem['calories'],        
          "proteins": foodItem['proteins'],      
          "fat": foodItem['fat'],
          "carbohydrate": foodItem['carbohydrate'],
          "waktu": waktu
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); 

      if (response.statusCode == 201) {
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Disimpan! Poin bertambah +5"),
            ],
          ),
          backgroundColor: primaryTeal,
          behavior: SnackBarBehavior.floating,
        ));

        setState(() {
          searchResults = []; 
          searchController.clear();
          hasSearched = false;
        });
        FocusScope.of(context).unfocus(); 
        _fetchDailySummary(); 
      }
    } catch (e) {
      Navigator.pop(context); 
      debugPrint("Error adding food: $e");
    }
  }

  Future<void> _fetchDailySummary() async {
    final url = Uri.parse('$baseUrl/api/summary/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          dailySummary = jsonDecode(response.body);
        });
      }
    } catch (e) { debugPrint("Error summary: $e"); }
  }

  void _showInputForm(Map<String, dynamic> item) {
    String selectedTime = "Pagi"; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder( 
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: item['image'] != null && item['image'].toString().startsWith('http')
                              ? Image.network(item['image'], width: 60, height: 60, fit: BoxFit.cover, 
                                  errorBuilder: (c,o,s) => Container(width: 60, height: 60, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey)))
                              : Container(width: 60, height: 60, color: Colors.teal[50], child: Icon(Icons.lunch_dining, color: primaryTeal)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              Text("${item['calories']} kkal", style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Divider(height: 30),

                    const Text("Pilih Waktu Makan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildChoiceChip("Pagi", Icons.wb_sunny_outlined, Colors.orange, selectedTime, (val) => setSheetState(() => selectedTime = val)),
                        _buildChoiceChip("Siang", Icons.wb_sunny, Colors.amber[800]!, selectedTime, (val) => setSheetState(() => selectedTime = val)),
                        _buildChoiceChip("Malam", Icons.nights_stay, Colors.indigo, selectedTime, (val) => setSheetState(() => selectedTime = val)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 3,
                        ),
                        onPressed: () {
                          _addFood(item, selectedTime);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 10),
                            Text("SIMPAN CATATAN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildChoiceChip(String label, IconData icon, Color color, String currentSelection, Function(String) onSelect) {
    bool isSelected = currentSelection == label;
    return GestureDetector(
      onTap: () => onSelect(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(
              color: isSelected ? color : Colors.grey, 
              fontWeight: FontWeight.bold,
              fontSize: 12
            )),
          ],
        ),
      ),
    );
  }

  String _getNutrientStatus(double p, double f, double c) {
    if (p == 0 && f == 0 && c == 0) return "Belum Ada Data";
    if (p > c && p > f) return "Tinggi Protein 💪";
    if (c > p && c > f) return "Energi Tinggi ⚡"; 
    if (f > c && f > p) return "Cukup Mengenyangkan 🧀"; 
    return "Gizi Seimbang ✨";
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0.0;
    int current = dailySummary['total_kalori'] ?? 0;
    int target = dailySummary['target_kalori'] ?? 2000;
    if (target > 0) progress = (current / target).clamp(0.0, 1.0);

    return Scaffold(
      body: Stack(
        children: [
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
          
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchDailySummary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    const SizedBox(height: 10),

                    Row(
                      children: [
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
                                "Pantau Nutrisimu",
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: Colors.white70
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryTeal, const Color(0xFF80CBC4)]), 
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Target Harian", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars, color: Colors.amber, size: 16),
                                    const SizedBox(width: 5),
                                    Text("+${dailySummary['poin_hari_ini']} Poin", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("$current", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 5),
                                child: Text("/ $target kkal", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress > 1.0 ? Colors.redAccent : Colors.amberAccent
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("${dailySummary['status_gizi']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text("${dailySummary['pesan']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    const Text("Tambah Makanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),

                    // --- TOMBOL SCAN CAMERA & AI (INTEGRASI BARU) ---
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                           // 1. TUNGGU HASIL DARI KAMERA
                           final resultName = await Navigator.push(
                             context,
                             MaterialPageRoute(builder: (context) => const ScanCameraScreen()),
                           );

                           // 2. JIKA ADA HASIL DARI AI, PROSES!
                           if (resultName != null && resultName is String) {
                             _processScanResult(resultName);
                           }
                        },
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text("Scan Foto Makanan (AI)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726), 
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                      ),
                    ),

                    TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _searchFood(value),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Atau cari manual...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: primaryTeal),
                        suffixIcon: isLoading 
                            ? Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal))
                            : (searchController.text.isNotEmpty 
                                ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: (){ searchController.clear(); setState(() { searchResults = []; hasSearched = false; }); }) 
                                : null),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.9), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),

                    if (hasSearched) 
                       AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(top: 15),
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)]
                        ),
                        child: isLoading 
                          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Mencari di Database...")))
                          : (searchResults.isEmpty 
                              ? Padding(padding: const EdgeInsets.all(20), child: Center(child: Column(children: [Icon(Icons.no_food, size: 40, color: Colors.grey[300]), const SizedBox(height: 10), const Text("Makanan tidak ditemukan", style: TextStyle(color: Colors.grey)) ])))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  shrinkWrap: true,
                                  itemCount: searchResults.length,
                                  separatorBuilder: (ctx, i) => const Divider(height: 10, color: Colors.transparent),
                                  itemBuilder: (context, index) {
                                    final item = searchResults[index];
                                    return ListTile(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      tileColor: Colors.grey[50],
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: item['image'] != null && item['image'].toString().startsWith('http')
                                            ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,o,s)=>const Icon(Icons.image_not_supported)) 
                                            : Container(width: 50, height: 50, color: Colors.grey[200], child: Icon(Icons.fastfood, color: primaryTeal)),
                                      ),
                                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text("${item['calories']} kkal | P: ${item['proteins']}g", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      trailing: Icon(Icons.add_circle, color: primaryTeal),
                                      onTap: () => _showInputForm(item),
                                    );
                                  },
                                )
                            ),
                      ),

                    const SizedBox(height: 30),
                    const Text("Riwayat Makan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 15),

                    _buildMealCard("Sarapan Pagi", Icons.wb_sunny_outlined, Colors.orange, dailySummary['pagi']),
                    _buildMealCard("Makan Siang", Icons.wb_sunny, Colors.amber[700]!, dailySummary['siang']),
                    _buildMealCard("Makan Malam", Icons.nights_stay, Colors.indigo, dailySummary['malam']),
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, IconData icon, Color color, List<dynamic> items) {
    double totalCal = 0;
    double totalProt = 0;
    double totalFat = 0;
    double totalCarb = 0;

    for (var item in items) {
      totalCal += (item['kalori'] ?? 0);
      totalProt += (item['protein'] ?? 0);
      totalFat += (item['lemak'] ?? 0);
      totalCarb += (item['karbo'] ?? 0);
    }

    String status = items.isEmpty ? "Belum diisi" : _getNutrientStatus(totalProt, totalFat, totalCarb);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9), 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(status, style: TextStyle(fontSize: 12, color: items.isEmpty ? Colors.grey : primaryTeal, fontWeight: FontWeight.w600)),
                  ],
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Text("${totalCal.toInt()} kkal", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          
          if (items.isNotEmpty) ...[
            Container(height: 1, color: Colors.grey[100]),
            ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_makanan'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMiniChip("Pro", item['protein'], colorProtein),
                                const SizedBox(width: 8),
                                _buildMiniChip("Lem", item['lemak'], colorFat),
                                const SizedBox(width: 8),
                                _buildMiniChip("Kar", item['karbo'], colorCarb),
                              ],
                            )
                          ],
                        ),
                      ),
                      Text("+${item['kalori']}", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text("$label ${value}g", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
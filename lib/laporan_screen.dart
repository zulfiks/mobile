import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'history_laporan_screen.dart';
// import 'profile.dart'; // Navigasi ke profile dihapus

class LaporanScreen extends StatefulWidget {
  final int userId; 
  final String userName; 

  const LaporanScreen({
    super.key, 
    required this.userId, 
    required this.userName
  });

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  
  String selectedKendala = "Profile"; 
  bool isLoading = false;
  File? _selectedImage;
  // Variabel profileImageUrl dihapus

  // --- WARNA TEMA BARU ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1);
  final Color cardGlass = Colors.white.withValues(alpha: 0.9);
  final Color inputGrey = const Color(0xFFF5F5F5);
  final Color btnBlue = const Color(0xFF29B6F6);
  final Color btnBlack = Colors.black87;

  // URL Dasar API (Sesuaikan jika IP berubah)
  final String baseUrl = "http://192.168.1.7:5000";

  @override
  void initState() {
    super.initState();
    namaController.text = widget.userName; 
    // _fetchProfileImage() dihapus
  }

  // Fungsi _fetchProfileImage dihapus

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _kirimLaporan() async {
    if (deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jelaskan kendalamu!")));
      return;
    }

    setState(() => isLoading = true);
    
    // IP Address Backend
    var uri = Uri.parse("$baseUrl/api/laporan");
    var request = http.MultipartRequest('POST', uri);

    request.fields['nama'] = namaController.text;
    request.fields['email'] = emailController.text;
    request.fields['jenis'] = selectedKendala;
    request.fields['deskripsi'] = deskripsiController.text;
    
    if (_selectedImage != null) {
      var multipartFile = await http.MultipartFile.fromPath('image', _selectedImage!.path);
      request.files.add(multipartFile);
    }

    try {
      var response = await request.send();
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(backgroundColor: Colors.green, content: Text("Laporan Terkirim!"))
          );
          
          // Reset form agar terlihat bersih kembali setelah kirim
          setState(() {
            deskripsiController.clear();
            _selectedImage = null;
          });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Gagal mengirim")));
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fungsi Pindah ke History
  void _goToHistory() {
     if (emailController.text.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => HistoryLaporanScreen(
          emailUser: emailController.text,
          userId: widget.userId, 
        )
      ));
     } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Isi email untuk melihat riwayatmu"))
        );
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      
                      // Teks Header
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, ${widget.userName}", 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const Text(
                              "Layanan Bantuan",
                              style: TextStyle(
                                fontSize: 14, 
                                color: Colors.white70
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol History
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.history, color: Colors.white),
                          tooltip: "Riwayat Laporan",
                          onPressed: _goToHistory,
                        ),
                      ),

                      // --- FOTO PROFILE DIHAPUS DARI SINI ---
                    ],
                  ),
                  // --- END HEADER ---
                  
                  const SizedBox(height: 30),

                  // FORM CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardGlass, // Putih Semi Transparan
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "FORM KENDALA", 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                          )
                        ),
                        const SizedBox(height: 5),
                        const Center(
                          child: Text(
                            "Ceritakan masalahmu di sini", 
                            style: TextStyle(fontSize: 12, color: Colors.grey)
                          )
                        ),
                        const SizedBox(height: 20),

                        _buildLabel("Nama"),
                        _buildInput(namaController, Icons.person_outline),

                        _buildLabel("Email"),
                        _buildInput(emailController, Icons.email_outlined),

                        _buildLabel("Jenis Kendala"),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedKendala,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                              dropdownColor: Colors.white,
                              items: ["Profile", "Login", "Bug", "Lainnya"].map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                              }).toList(),
                              onChanged: (newValue) => setState(() => selectedKendala = newValue!),
                            ),
                          ),
                        ),

                        _buildLabel("Deskripsi"),
                        TextField(
                          controller: deskripsiController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Jelaskan detail kendala...",
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            filled: true, fillColor: inputGrey,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(15),
                          ),
                        ),

                        _buildLabel("Upload Screenshot"),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image, size: 18, color: Colors.white),
                                label: const Text("Pilih Foto", style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryTeal, 
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedImage != null ? _selectedImage!.path.split('/').last : "Belum ada file",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _kirimLaporan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnBlack, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                              shadowColor: btnBlack.withValues(alpha: 0.3),
                            ),
                            child: isLoading 
                              ? const CircularProgressIndicator(color: Colors.white) 
                              : const Text("KIRIM LAPORAN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 15, bottom: 8), 
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54))
  );
  
  Widget _buildInput(TextEditingController controller, IconData icon) => TextField(
    controller: controller,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true, fillColor: inputGrey,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}
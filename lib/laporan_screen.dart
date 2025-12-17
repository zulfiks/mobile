import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Pastikan file ini ada (lihat langkah 3)
import 'history_laporan_screen.dart'; 

class LaporanScreen extends StatefulWidget {
  final String userName; // Nama user (contoh: rizki)
  const LaporanScreen({super.key, required this.userName});

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

  final Color bgTosca = const Color(0xFFA7DDD3); 
  final Color cardWhite = Colors.white;
  final Color inputGrey = const Color(0xFFE0E0E0);
  final Color btnBlack = Colors.black;

  @override
  void initState() {
    super.initState();
    namaController.text = widget.userName; 
  }

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
    var uri = Uri.parse("http://192.168.95.2:5000/api/laporan");
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Laporan Terkirim!")));
          Navigator.pop(context); 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgTosca,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // TOMBOL HISTORY
IconButton(
  icon: const Icon(Icons.history, color: Colors.black),
  tooltip: "Riwayat Laporan",
  onPressed: () {
     // PERBAIKAN: Kirim parameter 'email' dari controller atau widget
     // Pastikan user mengisi email dulu atau ambil dari data login
     if (emailController.text.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => HistoryLaporanScreen(emailUser: emailController.text)
        ));
     } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Isi email untuk melihat riwayatmu"))
        );
     }
  },
),
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 10),
            child: Center(child: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ADA KENDALA?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
            const SizedBox(height: 5),
            const Text("Waduh kamu punya kendala atau saran\ntulisan masalah mu di form ini ya", style: TextStyle(fontSize: 14)),
            
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("FORM KENDALA", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),

                  _buildLabel("Nama"),
                  _buildInput(namaController, Icons.person_outline),

                  _buildLabel("Email"),
                  _buildInput(emailController, Icons.email_outlined),

                  _buildLabel("Jenis Kendala"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedKendala,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        items: ["Profile", "Login", "Bug", "Lainnya"].map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) => setState(() => selectedKendala = newValue!),
                      ),
                    ),
                  ),

                  _buildLabel("Deskripsi"),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "tulis kendalamu disini",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      filled: true, fillColor: inputGrey,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),

                  _buildLabel("Upload Screenshot"),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.upload_file, size: 16, color: Colors.black),
                        label: const Text("Choose file", style: TextStyle(color: Colors.black, fontSize: 12)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], elevation: 0),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedImage != null ? _selectedImage!.path.split('/').last : "No file chosen",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _kirimLaporan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnBlack,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("Kirim", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(top: 15, bottom: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  
  Widget _buildInput(TextEditingController controller, IconData icon) => TextField(
    controller: controller,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, color: Colors.black),
      filled: true, fillColor: inputGrey,
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
  );
}
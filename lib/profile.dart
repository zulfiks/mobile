import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'login.dart';
import 'bmi_screen.dart'; // Import halaman BMI untuk navigasi

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controller Akun (BISA DIEDIT DI SINI)
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  
  // Controller Password
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  // Data Statistik (HANYA DISPLAY / READ-ONLY)
  String displayUsia = "0";
  String displayTinggi = "0";
  String displayBerat = "0";
  String displayGender = "-";
  String displayBmi = "0.0";
  String displayStatusBmi = "-";

  bool isLoading = false;
  File? _imageFile; 
  String? _networkImage; 

  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgGrey = const Color(0xFFF5F7FA);

  // GANTI IP INI SESUAI LAPTOP KAMU
  final String _baseUrl = "http://192.168.1.7:5000";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fungsi Refresh Data (Dipanggil saat kembali dari BMI Screen)
  Future<void> _refreshData() async {
    await _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final url = Uri.parse('$_baseUrl/api/users/${widget.userId}?t=${DateTime.now().millisecondsSinceEpoch}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Data Akun (Editable)
            namaController.text = data['nama'] ?? "";
            emailController.text = data['email'] ?? "";
            
            // Data Statistik (Read Only)
            displayUsia = (data['umur'] ?? 0).toString();
            displayTinggi = (data['tinggi'] ?? 0).toString();
            displayBerat = (data['berat'] ?? 0).toString();
            displayBmi = (data['bmi_score'] ?? 0).toString(); // Ambil dari server
            
            // Normalisasi Gender
            String rawGender = data['gender'] ?? "";
            if (rawGender == "P" || rawGender == "Perempuan") {
              displayGender = "Perempuan";
            } else if (rawGender == "L" || rawGender == "Laki-Laki") {
              displayGender = "Laki-Laki";
            } else {
              displayGender = "-";
            }
            
            // Foto
            if (data['foto'] != null && data['foto'] != "") {
              _networkImage = data['foto']; 
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error Fetch: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _updateProfile() async {
    final messenger = ScaffoldMessenger.of(context);

    // Validasi Password
    if (newPasswordController.text.isNotEmpty) {
      if (oldPasswordController.text.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text("Masukkan password lama!"), backgroundColor: Colors.orange));
        return;
      }
      if (newPasswordController.text.length < 8) {
        messenger.showSnackBar(const SnackBar(content: Text("Password baru min 8 karakter!"), backgroundColor: Colors.orange));
        return;
      }
      if (newPasswordController.text != confirmPasswordController.text) {
        messenger.showSnackBar(const SnackBar(content: Text("Password baru tidak cocok!"), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => isLoading = true);
    
    final uri = Uri.parse('$_baseUrl/api/users/${widget.userId}');
    var request = http.MultipartRequest('PUT', uri);

    // HANYA KIRIM DATA AKUN & PASSWORD (STATISTIK TIDAK DIKIRIM)
    request.fields['nama'] = namaController.text;
    request.fields['email'] = emailController.text;
    
    if (newPasswordController.text.isNotEmpty) {
      request.fields['old_password'] = oldPasswordController.text;
      request.fields['password'] = newPasswordController.text; 
    }
    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', _imageFile!.path));
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        messenger.showSnackBar(const SnackBar(content: Text("Data Akun Berhasil Diupdate!"), backgroundColor: Colors.green));
        
        if (mounted) {
          oldPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
          _fetchUserData(); // Refresh agar foto terbaru muncul
        }
      } else {
        messenger.showSnackBar(const SnackBar(content: Text("Gagal update profile"), backgroundColor: Colors.red));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionTitle("Informasi Akun"),
                  _buildAccountCard(),
                  const SizedBox(height: 25),
                  
                  // Bagian Statistik Read-Only + Link ke BMI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle("Data Fisik"),
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke BMI Screen untuk Edit Data Fisik
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BmiScreen(userId: widget.userId)),
                          ).then((_) => _refreshData()); // Refresh data saat kembali
                        },
                        child: Text("Update di BMI >", style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  _buildStatCardReadOnly(), 
                  
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                  const SizedBox(height: 15),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET UI ---
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 220,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryTeal, const Color(0xFF80CBC4)])),
          ),
        ),
        Positioned(
          top: 50, left: 20,
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        const Positioned(
          top: 60,
          child: Text("Edit Profil", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Positioned(
          bottom: -50,
          child: GestureDetector(
            onTap: _pickImage, 
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: CircleAvatar(
                    radius: 55, backgroundColor: Colors.white,
                    backgroundImage: _getImageProvider(),
                    child: _getImageProvider() == null ? Icon(Icons.person, size: 60, color: primaryTeal) : null,
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _getImageProvider() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (_networkImage != null && _networkImage!.isNotEmpty) {
      if (!_networkImage!.startsWith('http')) {
        return NetworkImage('$_baseUrl/static/uploads/$_networkImage');
      }
      return NetworkImage(_networkImage!);
    }
    return null;
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]),
      child: Column(
        children: [
          _buildField(namaController, "Username", Icons.person_outline, limit: 20),
          const SizedBox(height: 15),
          _buildField(emailController, "Alamat Email", Icons.email_outlined),
          const Divider(height: 40),
          const Text("Ganti Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildField(oldPasswordController, "Password Lama", Icons.lock_open, isObs: true),
          const SizedBox(height: 10),
          _buildField(newPasswordController, "Password Baru", Icons.lock_outline, isObs: true),
          const SizedBox(height: 10),
          _buildField(confirmPasswordController, "Konfirmasi Password Baru", Icons.check_circle_outline, isObs: true),
        ],
      ),
    );
  }

  // WIDGET BARU: TAMPILAN STATISTIK (READ ONLY)
  Widget _buildStatCardReadOnly() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("Usia", "$displayUsia th"),
              _buildInfoItem("Gender", displayGender),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("Tinggi", "$displayTinggi cm"),
              _buildInfoItem("Berat", "$displayBerat kg"),
              _buildInfoItem("BMI", displayBmi, isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: isBold ? primaryTeal : Colors.black87)),
      ],
    );
  }

  Widget _buildField(TextEditingController c, String hint, IconData icon, {bool isObs = false, int? limit}) {
    return TextField(
      controller: c, 
      obscureText: isObs, 
      maxLength: limit,
      decoration: InputDecoration(
        labelText: hint, 
        prefixIcon: Icon(icon, color: primaryTeal), 
        filled: true, 
        fillColor: const Color(0xFFFAFAFA), 
        counterText: "", 
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: isLoading ? null : _updateProfile, style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Simpan Data Akun", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  }

  Widget _buildLogoutButton() => TextButton.icon(onPressed: _logout, icon: const Icon(Icons.logout, color: Colors.red), label: const Text("Logout", style: TextStyle(color: Colors.red)));

  Widget _buildSectionTitle(String title) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))));
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path(); path.lineTo(0, size.height - 50); path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50); path.lineTo(size.width, 0); path.close(); return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usiaController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController tinggiController = TextEditingController();
  final TextEditingController beratController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;

  // --- PALET WARNA AESTHETIC ---
  final Color primaryTeal = const Color(0xFF009688);
  final Color lightTeal = const Color(0xFFE0F2F1);
  final Color bgGrey = const Color(0xFFF5F7FA);
  final Color textDark = const Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // --- PASTIKAN IP SESUAI ---
    final url = Uri.parse('http://192.168.95.2:5000/api/users/${widget.userId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaController.text = data['nama'] ?? "";
          emailController.text = data['email'] ?? "";
          usiaController.text = (data['umur'] ?? 0).toString();
          genderController.text = data['gender'] ?? "";
          tinggiController.text = (data['tinggi'] ?? 0).toString();
          beratController.text = (data['berat'] ?? 0).toString();
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _updateProfile() async {
    setState(() => isLoading = true);
    final url = Uri.parse('http://192.168.95.2:5000/api/users/${widget.userId}');
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": namaController.text, "email": emailController.text, "umur": usiaController.text,
          "gender": genderController.text, "tinggi": tinggiController.text, "berat": beratController.text,
          "password": passwordController.text, 
        }),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Color(0xFF43A047), behavior: SnackBarBehavior.floating, content: Text("✨ Profil Berhasil Diupdate!"))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Yakin ingin keluar dari aplikasi?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
               Navigator.pop(ctx);
               Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }, 
            child: const Text("Keluar")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER DENGAN CURVE & FOTO ---
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Background Gradient Curve
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [primaryTeal, const Color(0xFF4DB6AC)],
                      ),
                    ),
                  ),
                ),
                // Tombol Back
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
                // Judul Header
                const Positioned(
                  top: 60,
                  child: Text("Edit Profil", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                // Foto Profil
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 60, color: primaryTeal),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60), // Space untuk foto profil yang overlap

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // --- 2. INFORMASI AKUN (CARD) ---
                  _buildSectionTitle("Informasi Akun"),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        _buildModernField(namaController, "Nama Lengkap", Icons.person_outline),
                        const SizedBox(height: 15),
                        _buildModernField(emailController, "Alamat Email", Icons.email_outlined),
                        const SizedBox(height: 15),
                        _buildModernField(passwordController, "Password Baru", Icons.lock_outline, isObs: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 3. STATISTIK TUBUH (GRID 2x2) ---
                  _buildSectionTitle("Statistik Tubuh"),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5, // Lebar vs Tinggi
                    children: [
                      _buildStatCard(usiaController, "Usia", "Tahun", Icons.cake_outlined, Colors.orange),
                      _buildStatCard(genderController, "Gender", "L/P", Icons.wc, Colors.blue),
                      _buildStatCard(tinggiController, "Tinggi", "cm", Icons.height, Colors.green),
                      _buildStatCard(beratController, "Berat", "kg", Icons.monitor_weight_outlined, Colors.purple),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- 4. TOMBOL ACTION ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                        shadowColor: primaryTeal.withValues(alpha: 0.4),
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text("Logout Akun", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      ),
    );
  }

  Widget _buildModernField(TextEditingController c, String hint, IconData icon, {bool isObs = false}) {
    return TextField(
      controller: c,
      obscureText: isObs,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: primaryTeal),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryTeal, width: 2)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildStatCard(TextEditingController c, String label, String suffix, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: c,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Text(suffix, style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }
}

// --- CLIPPER UNTUK HEADER MELENGKUNG ---
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
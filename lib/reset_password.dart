import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordBaruController = TextEditingController();
  bool isLoading = false;

  // --- 1. LOGIKA VERIFIKASI USER ---
  Future<void> _verifikasiUser() async {
    if (namaController.text.isEmpty || emailController.text.isEmpty) {
      _showSnackBar("Isi Nama dan Email dulu!", Colors.orange);
      return;
    }
    setState(() => isLoading = true);

    // GANTI IP SESUAI LAPTOP KAMU
    final url = Uri.parse('http://192.168.1.7:5000/api/reset-password/verify');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": namaController.text,
          "email": emailController.text
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showDialogPasswordBaru(data['user_id']);
      } else {
        _showSnackBar("Nama atau Email tidak cocok!", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Koneksi Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- 2. LOGIKA UPDATE PASSWORD ---
  Future<void> _updatePassword(int userId) async {
    if (passwordBaruController.text.isEmpty) return;

    if (passwordBaruController.text.length < 8) {
      Navigator.pop(context); // Tutup dialog
      _showSnackBar("Password minimal 8 karakter!", Colors.orange);
      return;
    }

    // GANTI IP SESUAI LAPTOP KAMU
    final url = Uri.parse('http://192.168.1.7:5000/api/reset-password/update');

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "new_password": passwordBaruController.text
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnackBar("Password Berhasil Diganti!", Colors.green);
        Navigator.pop(context); // Keluar dari halaman reset (kembali ke login)
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal update: $e", Colors.red);
    }
  }

  // --- 3. DIALOG PASSWORD BARU ---
  void _showDialogPasswordBaru(int userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Ganti Password"),
        content: TextField(
          controller: passwordBaruController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Password Baru (Min 8)",
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => _updatePassword(userId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29B6F6),
            ),
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- 4. HELPER SNACKBAR ---
  void _showSnackBar(String msg, Color col) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: col),
    );
  }

  // --- 5. TAMPILAN UI (BUILD) ---
  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF8CD1CC);

    return Scaffold(
      backgroundColor: mainColor,
      body: Stack(
        children: [
          // --- BUBBLES BACKGROUND (Perhatikan KOMA di akhir, bukan titik koma) ---
          _buildBubble(top: -50, left: -50, size: 200, opacity: 0.1),
          _buildBubble(bottom: 100, right: -20, size: 100, opacity: 0.1),
          _buildBubble(top: 150, left: 30, size: 80, opacity: 0.12),
          _buildBubble(bottom: -40, left: -40, size: 180, opacity: 0.08),
          _buildBubble(top: 50, right: 50, size: 60, opacity: 0.15),

          // --- KONTEN TENGAH ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Text(
                    "Reset Password",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 5,
                          color: Colors.black26,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // CARD FORM PUTIH
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2F1).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nama",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: namaController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor:
                                const Color(0xFFAAAAAA).withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        const Text(
                          "Email",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor:
                                const Color(0xFFAAAAAA).withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _verifikasiUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF29B6F6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Kirim",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              "Kembali",
                              style: TextStyle(
                                color: Color(0xFF29B6F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- 6. HELPER WIDGET BUBBLE ---
  // Fungsi ini ada DI DALAM class, tapi DI BAWAH build
  Widget _buildBubble({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
} 
// PASTIKAN TIDAK ADA KODE APAPUN DI BAWAH KURUNG KURAWAL INI
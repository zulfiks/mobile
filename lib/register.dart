import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    // (Logika Register Tetap Sama)
    if (namaController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua data!")));
      return;
    }
    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.orange, content: Text("Password minimal 8 karakter!")));
      return;
    }
    if (passwordController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password tidak sama!")));
      return;
    }

    setState(() => isLoading = true);
    final url = Uri.parse('http://192.168.1.7:5000/api/register'); // GANTI IP

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": namaController.text,
          "email": emailController.text,
          "password": passwordController.text
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Berhasil Daftar! Silahkan Login")));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      } else {
        final msg = jsonDecode(response.body)['message'] ?? "Gagal Daftar";
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFF8CD1CC);

    return Scaffold(
      backgroundColor: mainColor,
      body: Stack(
        children: [
           // --- BANYAK LINGKARAN (BUBBLES) ---
          _buildBubble(top: -50, left: -50, size: 200, opacity: 0.1),
          _buildBubble(top: 100, right: -40, size: 120, opacity: 0.1),
          _buildBubble(bottom: 50, left: 30, size: 150, opacity: 0.08),
          _buildBubble(top: 300, left: -20, size: 80, opacity: 0.12),
          _buildBubble(bottom: -50, right: 50, size: 180, opacity: 0.09),
          
          // Konten Tengah
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text("Register", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5, shadows: [Shadow(offset: Offset(0, 2), blurRadius: 5, color: Colors.black26)])),
                   const SizedBox(height: 30),

                   Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF2F1).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Username"),
                        _buildInput(namaController, Icons.person),
                        const SizedBox(height: 15),
                        _buildLabel("Email"),
                        _buildInput(emailController, Icons.email),
                        const SizedBox(height: 15),
                        _buildLabel("Password (Min 8 Karakter)"),
                        _buildInput(passwordController, Icons.lock, isObscure: true),
                        const SizedBox(height: 15),
                        _buildLabel("Konfirmasi Password"),
                        _buildInput(confirmPassController, Icons.verified_user, isObscure: true),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                            child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Daftar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 15),
                         Center(
                           child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Sudah punya akun? "),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                                  child: const Text("Masuk", style: TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                         ),
                      ],
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

  // Helper Bubble
  Widget _buildBubble({double? top, double? left, double? right, double? bottom, required double size, required double opacity}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity))),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));
  }

  Widget _buildInput(TextEditingController ctrl, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: ctrl, obscureText: isObscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        filled: true, fillColor: const Color(0xFFAAAAAA).withValues(alpha: 0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
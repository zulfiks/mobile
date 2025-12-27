import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dashboard.dart';
import 'register.dart';
import 'reset_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // --- LOGIKA LOGIN (TETAP SAMA) ---
  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Email & Password!")));
      return;
    }
    setState(() => isLoading = true);
    // GANTI IP SESUAI LAPTOP KAMU
    final url = Uri.parse('http://192.168.1.7:5000/api/login/user');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text, "password": passwordController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Login Berhasil!")));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(userName: data['user']['nama'] ?? "User", userId: data['user']['id'])));
        }
      } else {
        final msg = jsonDecode(response.body)['message'] ?? "Login Gagal";
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI BARU ---
  @override
  Widget build(BuildContext context) {
    // Warna Ijo Mint Solid
    final Color mainColor = const Color(0xFF8CD1CC);

    return Scaffold(
      backgroundColor: mainColor, // Background full color
      body: Stack(
        children: [
          // --- BANYAK LINGKARAN (BUBBLES) ---
          // Posisi: Top, Left, Size, Opacity
          _buildBubble(top: -50, left: -50, size: 200, opacity: 0.1),
          _buildBubble(top: 50, left: 250, size: 100, opacity: 0.08),
          _buildBubble(top: 200, left: -30, size: 150, opacity: 0.12),
          _buildBubble(bottom: 100, right: -50, size: 250, opacity: 0.1),
          _buildBubble(bottom: -80, left: 80, size: 180, opacity: 0.09),
          _buildBubble(top: 150, right: 30, size: 50, opacity: 0.15),
          _buildBubble(bottom: 250, left: 50, size: 80, opacity: 0.1),

          // --- KONTEN UTAMA ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                    child: const Icon(Icons.directions_run, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text("Healthify", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5, shadows: [Shadow(offset: Offset(0, 2), blurRadius: 5, color: Colors.black26)])),
                  const SizedBox(height: 40),

                  // Card Login
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
                        const Center(child: Text("LOGIN", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87))),
                        const SizedBox(height: 30),
                        
                        const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            filled: true, fillColor: const Color(0xFFAAAAAA).withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            filled: true, fillColor: const Color(0xFFAAAAAA).withValues(alpha: 0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                            child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Log in", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen())),
                                child: const Text("Lupa Sandi?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("belum punya akun? "),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                                    child: const Text("daftar", style: TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
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

  // Helper Widget untuk membuat lingkaran
  Widget _buildBubble({double? top, double? left, double? right, double? bottom, required double size, required double opacity}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity)
        ),
      ),
    );
  }
}
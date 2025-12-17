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
  
  // Warna Desain
  final Color bgMint = const Color(0xFF8CE2D6);
  final Color inputGrey = const Color(0xFFB0B0B0);
  final Color btnBlue = const Color(0xFF42A5F5);
  final Color cardWhite = const Color(0xFFF5F5F5);

  Future<void> _login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Email & Password!")));
      return;
    }
    setState(() => isLoading = true);

    // --- UPDATE IP DI SINI (192.168.1.4) ---
    final url = Uri.parse('http://192.168.95.2:5000/api/login/user');

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
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                userName: data['user']['nama'] ?? "User",
                userId: data['user']['id'], 
              ),
            ),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Login Gagal")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgMint,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF26C6DA)]),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: const Icon(Icons.directions_run, color: Colors.white, size: 55),
              ),
              const SizedBox(height: 15),
              const Text("Healthify", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Column(
                  children: [
                    const Text("LOGIN", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 30),
                    TextField(controller: emailController, decoration: InputDecoration(hintText: "Email", filled: true, fillColor: inputGrey, prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                    const SizedBox(height: 20),
                    TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(hintText: "Password", filled: true, fillColor: inputGrey, prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                    const SizedBox(height: 30),
                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: btnBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Log in", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
                    const SizedBox(height: 20),
                    GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordScreen())), child: const Text("Lupa Sandi?", style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline))),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text("belum punya akun? "), GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())), child: Text("daftar", style: TextStyle(color: btnBlue, fontWeight: FontWeight.bold)))])
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
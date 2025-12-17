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
  final Color bgTeal = const Color(0xFF90DED0);
  final Color btnBlue = const Color(0xFF2FA4F3);

  Future<void> _register() async {
    if (namaController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi semua data!")));
      return;
    }
    if (passwordController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password tidak sama!")));
      return;
    }
    setState(() => isLoading = true);

    // --- UPDATE IP DI SINI (192.168.1.4) ---
    final url = Uri.parse('http://192.168.95.2:5000/api/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"nama": namaController.text, "email": emailController.text, "password": passwordController.text}),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Berhasil Daftar!")));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Gagal Daftar")));
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
      backgroundColor: bgTeal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Icon(Icons.directions_run, size: 50, color: Colors.white),
              const Text("Healthify", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFFEAF4F4), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Text("sign up", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(controller: namaController, decoration: InputDecoration(hintText: "Nama", filled: true, fillColor: const Color(0xFFBDBDBD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                    const SizedBox(height: 10),
                    TextField(controller: emailController, decoration: InputDecoration(hintText: "Email", filled: true, fillColor: const Color(0xFFBDBDBD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                    const SizedBox(height: 10),
                    TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(hintText: "Password", filled: true, fillColor: const Color(0xFFBDBDBD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                    const SizedBox(height: 10),
                    TextField(controller: confirmPassController, obscureText: true, decoration: InputDecoration(hintText: "Konfirmasi Password", filled: true, fillColor: const Color(0xFFBDBDBD), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
                    const SizedBox(height: 20),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isLoading ? null : _register, style: ElevatedButton.styleFrom(backgroundColor: btnBlue), child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Masuk", style: TextStyle(color: Colors.white, fontSize: 18)))),
                    const SizedBox(height: 15),
                    GestureDetector(onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())), child: const Text("Sudah punya akun? Masuk", style: TextStyle(fontWeight: FontWeight.bold))),
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
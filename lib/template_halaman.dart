import 'package:flutter/material.dart';

class TemplateHalaman extends StatelessWidget {
  final Widget body;
  final int currentIndex;

  // Konstruktor dengan Key dan const agar efisien
  const TemplateHalaman({
    super.key,
    required this.body,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- HEADER (APPBAR) ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFB2EBF2), // Warna sesuai gambar kamu
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              "zul",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),

      // --- ISI HALAMAN ---
      body: body,

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Logika pindah halaman menggunakan Named Routes
          if (index == currentIndex) return; // Jangan pindah jika klik menu yang sama

          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/bmi');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/peta');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/gerak');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/makan');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFB2EBF2),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.scale), label: 'BMI'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 35), 
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Gerak'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Makan'),
        ],
      ),
    );
  }
}
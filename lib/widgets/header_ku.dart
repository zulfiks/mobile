import 'package:flutter/material.dart';

class HeaderKu extends StatelessWidget implements PreferredSizeWidget {
  final String judul; // Biar teks judulnya bisa diganti-ganti
  final bool showBackButton; // Opsi mau tampilin tombol back atau tidak

  const HeaderKu({
    super.key, 
    required this.judul,
    this.showBackButton = true, // Defaultnya tombol back muncul
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Kalau showBackButton false, tombol back panah hilang (cocok buat Dashboard)
      automaticallyImplyLeading: showBackButton,
      
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            judul, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Selamat Datang!", // Bisa diganti sub-judul lain
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        // Tombol Profil di pojok kanan
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.blue),
              onPressed: () {
                // Nanti diisi navigasi ke halaman profil
                debugPrint("Tombol profil ditekan"); // <--- GANTI JADI INI
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
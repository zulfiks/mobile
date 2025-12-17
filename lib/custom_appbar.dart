// file: widgets/custom_appbar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton; // Opsi: mau tampilin tombol back atau tidak?

  const CustomAppBar({
    super.key, 
    required this.title, 
    this.showBackButton = true
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Kalau showBackButton false (misal di Dashboard), otomatis hilang
      automaticallyImplyLeading: showBackButton, 
      title: Text(title),
      actions: [
        // Tombol Profil yang selalu ada
        IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            // Navigasi ke profil
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
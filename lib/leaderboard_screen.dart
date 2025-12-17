import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboardData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    // Ganti IP sesuai laptop kamu
    final url = Uri.parse('http://192.168.95.2:5000/api/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> users = jsonDecode(response.body);
        // Urutkan poin tertinggi
        users.sort((a, b) => (b['poin'] ?? 0).compareTo(a['poin'] ?? 0));
        setState(() {
          leaderboardData = users;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1),
      appBar: AppBar(
        title: const Text("Papan Peringkat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: leaderboardData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = leaderboardData[index];
                return _buildRankTile(index + 1, user['nama'], user['poin']);
              },
            ),
    );
  }

Widget _buildRankTile(int rank, String name, int points) {
    Color medalColor = Colors.grey[300]!;
    // Variabel textColor dihapus karena tidak digunakan
    double elevation = 2;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700); // Emas
      elevation = 5;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0); // Perak
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32); // Perunggu
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, elevation))],
        border: rank <= 3 ? Border.all(color: medalColor, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: medalColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Center(
              child: rank <= 3 
                ? Icon(Icons.emoji_events, color: medalColor)
                : Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(10)),
            child: Text("$points Pts", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
          )
        ],
      ),
    );
  }
}
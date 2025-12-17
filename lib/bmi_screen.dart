import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class BmiScreen extends StatefulWidget {
  final int userId;

  const BmiScreen({super.key, required this.userId});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String selectedGender = "Laki-Laki";

  double? bmiResult;
  String bmiStatus = "";
  Color statusColor = Colors.green;
  bool isLoading = false;

  // --- WARNA BARU (LEBIH FRESH) ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1); // Warna dasar sangat muda
  final Color cardGlass = Colors.white.withValues(alpha: 0.8); // Kartu semi-transparan
  final Color inputGrey = const Color(0xFFF5F5F5); // Input lebih bersih
  final Color btnBlue = const Color(0xFF29B6F6);

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final url = Uri.parse('http://192.168.95.2:5000/api/users/${widget.userId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          heightController.text = (data['tinggi'] ?? 0).toString();
          weightController.text = (data['berat'] ?? 0).toString();
          ageController.text = (data['umur'] ?? 0).toString();
          selectedGender = (data['gender'] == "Laki-Laki" || data['gender'] == "Perempuan") 
              ? data['gender'] 
              : "Laki-Laki";
        });
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    }
  }

  void _calculateBMI() {
    double height = double.tryParse(heightController.text) ?? 0;
    double weight = double.tryParse(weightController.text) ?? 0;

    if (height > 0 && weight > 0) {
      setState(() {
        double heightInM = height / 100;
        bmiResult = weight / (heightInM * heightInM);

        if (bmiResult! < 18.5) {
          bmiStatus = "Underweight";
          statusColor = Colors.blue;
        } else if (bmiResult! < 25) {
          bmiStatus = "Normal";
          statusColor = Colors.green;
        } else if (bmiResult! < 30) {
          bmiStatus = "Overweight";
          statusColor = Colors.orange;
        } else {
          bmiStatus = "Obese";
          statusColor = Colors.red;
        }
      });
      _saveBmiData();
    }
  }

  Future<void> _saveBmiData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bmi_score', bmiResult ?? 0);

    setState(() => isLoading = true);
    final url = Uri.parse('http://192.168.95.2:5000/api/users/${widget.userId}');
    
    try {
      await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tinggi": heightController.text,
          "berat": weightController.text,
          "umur": ageController.text,
          "gender": selectedGender,
        }),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Data Tersimpan!")),
        );
      }
    } catch (e) {
      debugPrint("Error save: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Agar background sampai atas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // --- 1. BACKGROUND GRADIENT & DEKORASI ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF80CBC4), // Hijau Teal Segar
                  bgMintLight,             // Putih Mint
                ],
              ),
            ),
          ),
          // Lingkaran Dekorasi 1 (Kanan Atas)
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Lingkaran Dekorasi 2 (Kiri Bawah)
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.1),
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA ---
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cek BMI", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Pantau kesehatanmu disini", style: TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.monitor_weight_outlined, size: 40, color: Colors.white),
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  // FORM CARD (Glassmorphism Effect)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardGlass, // Putih Semi Transparan
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("Lengkapi Data Fisik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(child: _buildInput("Tinggi (cm)", heightController)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildInput("Berat (kg)", weightController)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Gender", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: inputGrey, borderRadius: BorderRadius.circular(12)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedGender,
                                        isExpanded: true,
                                        icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                                        dropdownColor: Colors.white,
                                        items: ["Laki-Laki", "Perempuan"].map((String value) {
                                          return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                                        }).toList(),
                                        onChanged: (newValue) => setState(() => selectedGender = newValue!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(child: _buildInput("Usia (th)", ageController)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // HASIL GAUGE
                  if (bmiResult != null) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 30)]
                        ),
                        width: 200, height: 200,
                        child: CustomPaint(
                          painter: GaugePainter(bmi: bmiResult!),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bmiResult!.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                                Text(
                                  bmiStatus,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: Text("Indikator: ${bmiStatus.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    const SizedBox(height: 10),
                    // Legend Bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [Colors.blue, Colors.green, Colors.orange, Colors.red]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // TOMBOL ACTION
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _calculateBMI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnBlue,
                        elevation: 5,
                        shadowColor: btnBlue.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("HITUNG SEKARANG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: inputGrey,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

// --- GAUGE PAINTER (FIXED: WithValues & Logic) ---
class GaugePainter extends CustomPainter {
  final double bmi;
  GaugePainter({required this.bmi});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Lingkaran Background Penuh (Tipis)
    Paint bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.grey.withValues(alpha: 0.1);

    // 2. Lingkaran Progress
    Paint valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Logika Warna
    if (bmi < 18.5) {
      valuePaint.color = Colors.blue;
    } else if (bmi < 25) {
      valuePaint.color = Colors.green;
    } else if (bmi < 30) {
      valuePaint.color = Colors.orange;
    } else {
      valuePaint.color = Colors.red;
    }

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = (size.width / 2) - 10;

    // Gambar Full Circle Background
    canvas.drawCircle(center, radius, bgPaint);

    // Hitung Progress (Max 40 BMI = 1 Lingkaran Penuh)
    // Mulai dari -90 derajat (atas)
    double progress = (bmi / 40).clamp(0.0, 1.0) * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, progress, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
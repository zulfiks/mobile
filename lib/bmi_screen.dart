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

  // --- DATA USER ---
  String userName = "User"; 

  double? bmiResult;
  String bmiStatus = "";
  Color statusColor = Colors.green;

  // --- WARNA TEMA ---
  final Color primaryTeal = const Color(0xFF4DB6AC);
  final Color bgMintLight = const Color(0xFFE0F2F1); 
  final Color cardGlass = Colors.white.withValues(alpha: 0.8); 
  final Color inputGrey = const Color(0xFFF5F5F5); 
  final Color btnBlue = const Color(0xFF29B6F6);

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final url = Uri.parse('http://192.168.1.7:5000/api/users/${widget.userId}?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            if (data['nama'] != null) {
              userName = data['nama']; 
            }
            heightController.text = (data['tinggi'] ?? 0).toString();
            weightController.text = (data['berat'] ?? 0).toString();
            ageController.text = (data['umur'] ?? 0).toString();
            
            if (data['gender'] == "L" || data['gender'] == "Laki-Laki") {
              selectedGender = "Laki-Laki";
            } else if (data['gender'] == "P" || data['gender'] == "Perempuan") {
              selectedGender = "Perempuan";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error load data: $e");
    }
  }

  Future<void> _calculateBMI() async {
    String heightTxt = heightController.text.replaceAll(',', '.');
    String weightTxt = weightController.text.replaceAll(',', '.');
    double height = double.tryParse(heightTxt) ?? 0;
    double weight = double.tryParse(weightTxt) ?? 0;

    FocusScope.of(context).unfocus(); 

    if (height > 0 && weight > 0 && height < 300 && weight < 500) {
      
      // TAMPILKAN LOADING DIALOG
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text("Menyimpan Data...", style: TextStyle(fontWeight: FontWeight.bold))
              ],
            ),
          ),
        ),
      );

      double heightInM = height / 100;
      double result = weight / (heightInM * heightInM);
      String status = "";
      Color color = Colors.green;

      if (result < 18.5) {
        status = "Underweight";
        color = Colors.blue;
      } else if (result < 25) {
        status = "Normal";
        color = Colors.green;
      } else if (result < 30) {
        status = "Overweight";
        color = Colors.orange;
      } else {
        status = "Obese";
        color = Colors.red;
      }

      bool success = await _saveBmiData(result);

      // --- PERBAIKAN 1: MENGGUNAKAN BLOK KURUNG KURAWAL ---
      if (mounted) {
        Navigator.pop(context);
      }

      if (success && mounted) {
        setState(() {
          bmiResult = result;
          bmiStatus = status;
          statusColor = color;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Berhasil dihitung & disimpan!")),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Gagal menyimpan ke server, coba lagi.")),
        );
      }

    } else {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Masukkan data yang valid (Maks 3 Digit)")),
        );
    }
  }

  Future<bool> _saveBmiData(double currentBmi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bmi_score', currentBmi);

    final url = Uri.parse('http://192.168.1.7:5000/api/users/${widget.userId}');
    
    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "tinggi": heightController.text,
          "berat": weightController.text,
          "umur": ageController.text,
          "gender": selectedGender,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error save: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF80CBC4), bgMintLight],
              ),
            ),
          ),
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.tealAccent.withValues(alpha: 0.1)),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context), 
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, $userName...", 
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Text("Cek BMI & Kesehatanmu", style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardGlass,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        const Text("Lengkapi Data Fisik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Expanded(child: _buildInput("Tinggi (cm)", heightController, limit: 3)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildInput("Berat (kg)", weightController, limit: 3)),
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
                                        onChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              selectedGender = newValue;
                                            });
                                          } 
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(child: _buildInput("Usia (th)", ageController, limit: 3)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

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
                          key: ValueKey(bmiResult), 
                          painter: GaugePainter(bmi: bmiResult!),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(bmiResult!.toStringAsFixed(1), style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: statusColor)),
                                Text(bmiStatus, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(child: Text("Indikator: ${bmiStatus.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                    const SizedBox(height: 10),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(colors: [Colors.blue, Colors.green, Colors.orange, Colors.red]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _calculateBMI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnBlue,
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("HITUNG SEKARANG", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildInput(String label, TextEditingController controller, {int limit = 3}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: limit,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            filled: true, fillColor: inputGrey,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}

// --- PERBAIKAN 2: MENGGUNAKAN BLOK KURUNG KURAWAL PADA SETIAP IF ---
class GaugePainter extends CustomPainter {
  final double bmi;
  GaugePainter({required this.bmi});

  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..color = Colors.grey.withValues(alpha: 0.1);
    Paint valuePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;

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
    canvas.drawCircle(center, radius, bgPaint);
    double progress = (bmi / 40).clamp(0.0, 1.0) * 2 * pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, progress, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
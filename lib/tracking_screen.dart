import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';      
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http;

class TrackingScreen extends StatefulWidget {
  final int userId; 
  const TrackingScreen({super.key, required this.userId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // Tambahkan 'final' di sini
  final MapController mapController = MapController();
  
  List<LatLng> ruteLari = []; 
  double totalJarak = 0.0;     
  bool isRunning = false;      
  
  StreamSubscription<Position>? positionStream;
  LatLng lokasiSekarang = const LatLng(-7.5583, 111.6606); 

  // --- PERBAIKAN DI SINI (Tambahkan final) ---
  final Stopwatch _stopwatch = Stopwatch();
  
  Timer? _timer;
  String _waktuLari = "00:00:00";
  int _kalori = 0;

  @override
  void dispose() {
    positionStream?.cancel();
    _timer?.cancel(); 
    super.dispose();
  }

  void startTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return; 
    }

    setState(() {
      isRunning = true;
      ruteLari.clear(); 
      totalJarak = 0.0; 
      _kalori = 0;
      _stopwatch.reset(); // Reset dulu sebelum mulai
      _stopwatch.start(); 
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _waktuLari = _formatDuration(_stopwatch.elapsed);
      });
    });

    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, 
    );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      
      LatLng titikBaru = LatLng(position.latitude, position.longitude);

      setState(() {
        if (ruteLari.isNotEmpty) {
          double dist = Geolocator.distanceBetween(
            ruteLari.last.latitude, ruteLari.last.longitude,
            titikBaru.latitude, titikBaru.longitude,
          );
          totalJarak += dist;
          
          // Hitung Kalori Kasar: 0.06 kalori per meter
          _kalori = (totalJarak * 0.06).toInt();
        }

        ruteLari.add(titikBaru);
        lokasiSekarang = titikBaru;
      });

      mapController.move(titikBaru, 17.0);
    });
  }

  void stopTracking() async {
    _stopwatch.stop();
    _timer?.cancel();
    positionStream?.cancel();

    setState(() {
      isRunning = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Menyimpan data lari...")),
    );

    await _kirimDataKeServer();
  }

  Future<void> _kirimDataKeServer() async {
    // GANTI IP SESUAI SETUP KAMU
    String apiUrl = "http://192.168.1.7:5000/api/lari";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "jarak": double.parse((totalJarak / 1000).toStringAsFixed(2)),
          "waktu": _waktuLari,
          "kalori": _kalori,
          "rute": "Lokasi tersimpan"
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil Disimpan! +1 Poin")),
        );
        Navigator.pop(context, true); 
      } else {
        throw Exception("Gagal menyimpan");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lari Tracker"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: lokasiSekarang,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.healthify', 
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: ruteLari,
                    color: Colors.blue,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: lokasiSekarang,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.directions_run, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // PANEL ATAS: Timer
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)]
                ),
                child: Text(
                  _waktuLari,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 100, 
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("JARAK (KM)", style: TextStyle(color: Colors.grey)),
                      Text(
                        (totalJarak / 1000).toStringAsFixed(2), 
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("KALORI", style: TextStyle(color: Colors.grey)),
                      Text(
                        "$_kalori Kcal",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: isRunning ? stopTracking : startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: isRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isRunning ? "STOP & SIMPAN" : "MULAI LARI",
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
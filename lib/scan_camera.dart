import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key});

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  late CameraController controller;
  late FlutterVision vision;
  late List<CameraDescription> cameras;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> yoloResults = [];
  File? imageFile; 
  bool isLoaded = false;
  bool isScanning = false;
  
  double imageWidth = 0;
  double imageHeight = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize();
    
    vision = FlutterVision();
    await vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/model_makanan_indo.tflite',
        modelVersion: "yolov8", 
        quantization: false,
        numThreads: 2,
        useGpu: true);

    setState(() {
      isLoaded = true;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. KAMERA PREVIEW / HASIL FOTO
          if (imageFile != null)
            Image.file(imageFile!, fit: BoxFit.contain)
          else
            Center(child: CameraPreview(controller)),
          
          // 2. KOTAK DETEKSI
          ...displayBoxesAroundRecognizedObjects(size),
          
          // 3. LOGO LOADING
          if (isScanning)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 10),
                    Text("AI Sedang Menganalisa...", style: TextStyle(color: Colors.white))
                  ],
                ),
              ),
            ),

          // 4. TOMBOL KONTROL DI BAWAH
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  
                  // --- TOMBOL KHUSUS INTEGRASI (BARU) ---
                  if (imageFile != null && yoloResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent[700], // Warna Hijau Sukses
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 5,
                        ),
                        onPressed: () {
                          // KEMBALIKAN NAMA MAKANAN KE HALAMAN SEBELUMNYA
                          String foodName = yoloResults[0]['tag']; 
                          Navigator.pop(context, foodName);
                        },
                        child: const Text(
                          "✅ KLAIM MAKANAN INI",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  // MENU STANDAR (SCAN ULANG / JEPRET)
                  if (imageFile != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: resetScanner,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Scan Ulang"),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
                          onPressed: pickImageFromGallery,
                        ),
                        
                        GestureDetector(
                          onTap: captureAndScan,
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 30), 
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          // JUDUL
          if (imageFile == null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Arahkan ke Makanan mu",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void resetScanner() {
    setState(() {
      imageFile = null;
      yoloResults.clear();
      isScanning = false;
    });
    controller.resumePreview();
  }

  Future<void> captureAndScan() async {
    setState(() { isScanning = true; });
    try {
      final XFile photo = await controller.takePicture();
      await processImage(photo.path);
    } catch (e) {
      debugPrint("Error: $e");
      setState(() { isScanning = false; });
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() { isScanning = true; });
    await processImage(image.path);
  }

  Future<void> processImage(String path) async {
    File file = File(path);
    Uint8List bytes = await file.readAsBytes();
    var decodedImage = await decodeImageFromList(bytes);

    final result = await vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4, 
        classThreshold: 0.4);

    setState(() {
      imageFile = file;
      imageWidth = decodedImage.width.toDouble();
      imageHeight = decodedImage.height.toDouble();
      yoloResults = result;
      isScanning = false;
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || imageFile == null) return [];
    
    double factorX = screen.width / imageWidth;
    double factorY = screen.width / imageWidth; 
    
    double offsetY = (screen.height - (imageHeight * factorY)) / 2;
    if (imageHeight * factorY > screen.height) {
         factorY = screen.height / imageHeight;
         factorX = factorY;
         offsetY = 0;
    }

    return yoloResults.map((result) {
      double left = result["box"][0] * factorX;
      double top = (result["box"][1] * factorY) + offsetY;
      double right = result["box"][2] * factorX;
      double bottom = (result["box"][3] * factorY) + offsetY;

      return Positioned(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(color: Colors.greenAccent, width: 3.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.greenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
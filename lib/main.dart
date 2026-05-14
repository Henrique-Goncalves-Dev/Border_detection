import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: DetectorBordas(),
    ));

class DetectorBordas extends StatefulWidget {
  const DetectorBordas({super.key});

  @override
  _DetectorBordasState createState() => _DetectorBordasState();
}

class _DetectorBordasState extends State<DetectorBordas> {
  File? _originalImage;
  File? _grayImage;
  File? _edgeImage;
  int _currentIndex = 0;
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() => _isProcessing = true);
      
      try {
        File imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        final decoded = img.decodeImage(bytes);

        if (decoded != null) {
          final gray = img.grayscale(decoded);
          final grayFile = File(imageFile.path.replaceFirst('.jpg', '_gray.jpg'))
            ..writeAsBytesSync(img.encodeJpg(gray));

          final edges = img.sobel(gray);
          final edgeFile = File(imageFile.path.replaceFirst('.jpg', '_edge.jpg'))
            ..writeAsBytesSync(img.encodeJpg(edges));

          setState(() {
            _originalImage = imageFile;
            _grayImage = grayFile;
            _edgeImage = edgeFile;
            _isProcessing = false;
          });
        }
      } catch (e) {
        setState(() => _isProcessing = false);
        print("Erro no processamento: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detector de Bordas", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator()) 
        : (_originalImage == null ? _buildCaptureUI() : _buildResultUI()),
      bottomNavigationBar: _originalImage != null ? _buildBottomNav() : null,
    );
  }

  Widget _buildCaptureUI() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Capturar Imagem", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Tire uma foto usando a câmera do celular.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("ABRIR CÂMERA"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDicaCard(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDicaCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.deepPurple),
          SizedBox(width: 10),
          Expanded(child: Text("A foto será processada automaticamente após a captura.")),
        ],
      ),
    );
  }

  Widget _buildResultUI() {
    final titles = ["Original", "Tons de Cinza", "Bordas"];
    final images = [_originalImage, _grayImage, _edgeImage];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(titles[_currentIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(images[_currentIndex]!, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildBottomNav() {
  return BottomNavigationBar(
    currentIndex: _currentIndex,
    selectedItemColor: Colors.deepPurple, // Removido const daqui
    onTap: (index) => setState(() => _currentIndex = index),
    items: [ 
      const BottomNavigationBarItem(icon: Icon(Icons.photo), label: "Original"),
      const BottomNavigationBarItem(icon: Icon(Icons.grid_3x3), label: "Cinza"),
      const BottomNavigationBarItem(icon: Icon(Icons.blur_on), label: "Bordas"),
    ],
  );
}
}
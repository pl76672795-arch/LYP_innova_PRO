import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// Cambiamos el import general por el específico de reconocimiento de texto
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraScanPage extends StatefulWidget {
  final dynamic projectBox;

  const CameraScanPage({
    super.key,
    required this.projectBox,
  });

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  CameraController? _cameraController;
  // Cambiamos TextDetector por TextRecognizer
  late TextRecognizer _textRecognizer;

  String _detectedText = '';
  bool _isProcessing = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos el reconocedor en español/latín
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No se encontraron cámaras disponibles.');
        return;
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.max, // Máxima resolución para mejor OCR
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error inicializando cámara')),
        );
      }
    }
  }

  Future<void> _captureAndDetectText() async {
    if (_isProcessing || _cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      setState(() => _isProcessing = true);

      // Capturamos la imagen
      final XFile image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      // Procesamos el texto con la nueva API
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      setState(() {
        _detectedText = recognizedText.text;
        _isProcessing = false;
      });

      if (_detectedText.trim().isNotEmpty) {
        _showDetectedTextDialog();
      } else {
        // --- Corregido: Async gap en línea 109 ---
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontró texto en la imagen')),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Error en OCR: $e');
      // --- Corregido: Async gap en línea 112 ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error procesando imagen')),
        );
      }
    }
  }

  void _showDetectedTextDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.text_fields, color: Colors.orange),
            SizedBox(width: 10),
            Text('Texto Detectado', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          maxLines: 10,
          controller: TextEditingController(text: _detectedText),
          onChanged: (value) => _detectedText = value,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Edita el texto aquí...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Descartar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _saveToHive();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save_rounded),
            label: const Text('Guardar Proyecto'),
          ),
        ],
      ),
    );
  }

  void _saveToHive() {
    // Validación NTP: Asegurar texto no vacío para trazabilidad en escaneos civiles
    if (_detectedText.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Texto vacío, no se puede guardar')),
        );
      }
      return;
    }

    final projectId = DateTime.now().millisecondsSinceEpoch.toString();
    widget.projectBox.put(projectId, {
      'name': 'Escaneo #${widget.projectBox.length + 1}',
      'text': _detectedText,
      'date': DateTime.now().toIso8601String(),
      'type': 'scan',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proyecto guardado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close(); // Muy importante cerrar el motor de IA
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Vista de cámara a pantalla completa
          Positioned.fill(child: CameraPreview(_cameraController!)),
          
          // Capa de diseño (Overlay)
          Positioned.fill(
            child: CustomPaint(
              painter: CameraOverlayPainter(),
            ),
          ),

          // Botón para volver
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Instrucción
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Encuadra el texto para escanear',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.orange)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isProcessing ? null : _captureAndDetectText,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.document_scanner_rounded, size: 35, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Pintor del cuadro de enfoque (Mantenemos tu lógica pero la limpiamos)
class CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 127)  // Corregido: withOpacity(0.5) → withValues(alpha: 127)
      ..style = PaintingStyle.fill;

    final boxWidth = size.width * 0.85;
    final boxHeight = size.height * 0.3;
    final left = (size.width - boxWidth) / 2;
    final top = (size.height - boxHeight) / 2;

    // Dibujar fondo oscuro con hueco transparente
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, boxWidth, boxHeight), const Radius.circular(15))),
      ),
      paint,
    );

    // Dibujar bordes de la caja
    final borderPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, boxWidth, boxHeight), const Radius.circular(15)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
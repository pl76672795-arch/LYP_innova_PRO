import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../database_helper.dart';
import '../firebase_sync.dart';

class GaleriaObraPage extends StatefulWidget {
  const GaleriaObraPage({super.key});

  @override
  State<GaleriaObraPage> createState() => _GaleriaObraPageState();
}

class _GaleriaObraPageState extends State<GaleriaObraPage> {
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _fotos = [];
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
    if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Inicializando GaleriaObraPage NTP");
  }

  Future<void> _cargarFotos() async {
    try {
      final fotos = await _db.listarFotosGaleria();
      setState(() => _fotos = fotos);
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Cargadas ${fotos.length} fotos NTP");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Error carga: $e");
    }
  }

  bool _validarImagenNTP(File imageFile) {
    final size = imageFile.lengthSync();
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen >5MB NTP. Comprime o selecciona otra.')),
        );
      }
      return false;
    }
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formato no válido NTP. Usa JPG/PNG.')),
        );
      }
      return false;
    }
    return true;
  }

  File _comprimirImagenNTP(File imageFile) {
    if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Imagen sin comprimir NTP: ${imageFile.lengthSync()} bytes");
    return imageFile;
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        final file = File(image.path);
        if (!_validarImagenNTP(file)) return;
        final compressedFile = _comprimirImagenNTP(file);
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

        await _db.insertarFotoGaleria(pathLocal: compressedFile.path, timestamp: timestamp);
        
        if (!mounted) return;
        await FirebaseSync.uploadFotoObra(compressedFile.path, context);
        
        if (!mounted) return;
        await FirebaseSync.agregarFotoGaleriaCloud('url_placeholder', timestamp);

        _cargarFotos();
        if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Foto tomada NTP: $timestamp");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Error tomar foto: $e");
      rethrow;
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final file = File(image.path);
        if (!_validarImagenNTP(file)) return;
        final compressedFile = _comprimirImagenNTP(file);
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

        await _db.insertarFotoGaleria(pathLocal: compressedFile.path, timestamp: timestamp);
        
        if (!mounted) return;
        await FirebaseSync.uploadFotoObra(compressedFile.path, context);
        
        if (!mounted) return;
        await FirebaseSync.agregarFotoGaleriaCloud('url_placeholder', timestamp);

        _cargarFotos();
        if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Foto seleccionada NTP: $timestamp");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Error seleccionar foto: $e");
      rethrow;
    }
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);
    try {
      await FirebaseSync.syncNow(context);
      if (!mounted) return;
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Sincronización NTP completada");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA GALERIA] Error sync: $e");
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería de Obra NTP - LYP Innova'),
        backgroundColor: Colors.orange.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncNow,
            tooltip: 'Sincronizar NTP',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera),
                    label: const Text('Tomar Foto NTP'),
                    onPressed: _tomarFoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade900,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar Foto NTP'),
                    onPressed: _seleccionarFoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _fotos.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay fotos NTP. Toma o selecciona una.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _fotos.length,
                      itemBuilder: (context, index) {
                        final foto = _fotos[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: foto['pathLocal'] != null
                                    ? Image.file(
                                        File(foto['pathLocal']),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: foto['urlCloud'] ?? '',
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Fecha NTP: ${DateTime.fromMillisecondsSinceEpoch(int.parse(foto['timestamp'])).toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
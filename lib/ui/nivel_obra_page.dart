import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';  // Agregado: Para StreamSubscription

class NivelObraPage extends StatefulWidget {
  const NivelObraPage({super.key});

  @override
  NivelObraPageState createState() => NivelObraPageState();  // Corregido: Clase State ahora pública
}

class NivelObraPageState extends State<NivelObraPage> {  // Corregido: Nombre de clase State público
  double _pendiente = 0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;  // Ahora definido correctamente

  @override
  void initState() {
    super.initState();
    // Corregido: accelerometerEvents → accelerometerEventStream()
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (mounted) {  // Check mounted para evitar setState en widget desmontado
        setState(() => _pendiente = event.z * 100);
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();  // Cancelar stream para evitar leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nivel de Obra - NTP'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: Center(
          child: Card(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.straighten, size: 60, color: Colors.orange),  // Corregido: Icons.level → Icons.straighten (icono válido)
                  const SizedBox(height: 20),
                  Text(
                    'Pendiente: ${_pendiente.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _pendiente.abs() <= 2 ? 'Pendiente reglamentaria (1-2% según NTP)' : 'Pendiente fuera de rango (ajuste requerido)',
                    style: TextStyle(
                      fontSize: 18,
                      color: _pendiente.abs() <= 2 ? Colors.green.shade700 : Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Usa el dispositivo para medir la pendiente en tiempo real.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
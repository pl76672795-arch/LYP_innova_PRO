import 'package:flutter/material.dart';

class SteelCalculator extends StatefulWidget {
  const SteelCalculator({super.key});

  @override
  State<SteelCalculator> createState() => _SteelCalculatorState();
}

class _SteelCalculatorState extends State<SteelCalculator> {
  final TextEditingController _largoController = TextEditingController();
  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _separacionController = TextEditingController(text: '0.15');  // Ya correcto: text en lugar de value
  String _selectedDiameter = '1/4"';
  int? _varillasTotales;
  String? _errorMessage;

  // Diámetros disponibles (NTP: diámetros estándar para acero de refuerzo)
  static const List<String> _diameters = ['1/4"', '6mm', '3/8"', '1/2"', '5/8"', '3/4"', '1"'];

  void _calculateZapatas() {
    setState(() => _errorMessage = null);
    final largo = double.tryParse(_largoController.text);
    final ancho = double.tryParse(_anchoController.text);
    final altura = double.tryParse(_alturaController.text);
    final separacion = double.tryParse(_separacionController.text);

    // Validación NTP mejorada: Valores positivos, separaciones razonables (0.1-0.5m para mallas), alturas típicas (0.1-2m)
    if (largo == null || ancho == null || altura == null || separacion == null ||
        largo <= 0 || ancho <= 0 || altura < 0.1 || altura > 2 || separacion < 0.1 || separacion > 0.5) {
      setState(() => _errorMessage = 'Ingresa valores válidos según NTP (altura 0.1-2m, separación 0.1-0.5m).');
      return;
    }
    try {
      // Cálculo mejorado: Varillas en largo y ancho para malla bidireccional (aprox NTP)
      final varillasLargo = (largo / separacion).ceil();
      final varillasAncho = (ancho / separacion).ceil();
      final total = (varillasLargo + varillasAncho) * 2; // Factor para malla bidireccional
      setState(() => _varillasTotales = total);
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  @override
  void dispose() {
    _largoController.dispose();
    _anchoController.dispose();
    _alturaController.dispose();
    _separacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo de Aceros - NTP'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.orange.withValues(alpha: 25.5),  // Ya corregido
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.build, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Text('Diámetros y Zapatas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDiameter,  // --- Corregido: value → initialValue ---
                    items: _diameters.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (value) => setState(() => _selectedDiameter = value!),
                    decoration: const InputDecoration(
                      labelText: 'Diámetro de Acero',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Cálculo de Zapatas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _largoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largo (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _anchoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ancho (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Altura (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _separacionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Separación Malla (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grid_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _calculateZapatas,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular Varillas'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                  if (_varillasTotales != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Varillas Totales: $_varillasTotales (diámetro $_selectedDiameter)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
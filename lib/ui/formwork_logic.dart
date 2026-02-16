import 'package:flutter/material.dart';

class FormworkCalculator extends StatefulWidget {
  const FormworkCalculator({super.key});

  @override
  State<FormworkCalculator> createState() => _FormworkCalculatorState();
}

class _FormworkCalculatorState extends State<FormworkCalculator> {
  final TextEditingController _baseController = TextEditingController();
  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  double? _piesTablares;
  int? _clavos25, _clavos3;
  String? _errorMessage;

  void _calculate() {
    setState(() => _errorMessage = null);
    final base = double.tryParse(_baseController.text);
    final ancho = double.tryParse(_anchoController.text);
    final altura = double.tryParse(_alturaController.text);

    // Validación NTP: Medidas positivas y rangos razonables para encofrado (0.1-5m según normas peruanas)
    if (base == null || ancho == null || altura == null ||
        base <= 0 || ancho <= 0 || altura <= 0 ||
        base > 5 || ancho > 5 || altura > 10) {  // Rangos típicos para columnas
      setState(() => _errorMessage = 'Ingresa valores válidos (0.1-5m para base/ancho, 0.1-10m para altura).');
      return;
    }
    try {
      // Perímetro * altura para área de encofrado
      final perimetro = 2 * (base + ancho);
      _piesTablares = perimetro * altura;
      _clavos25 = (_piesTablares! * 10).round(); // Estimación NTP
      _clavos3 = (_piesTablares! * 5).round();
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  @override
  void dispose() {
    _baseController.dispose();
    _anchoController.dispose();
    _alturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encofrado de Columnas'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.orange.withValues(alpha: 25.5),  // Corregido: withOpacity(0.1) → withValues(alpha: 25.5)
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text('Cálculo de Encofrado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),  // Agregado: const
                const SizedBox(height: 16),
                TextField(
                  controller: _baseController,
                  decoration: const InputDecoration(labelText: 'Base (m)', border: OutlineInputBorder()),  // Agregado: const
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _anchoController,
                  decoration: const InputDecoration(labelText: 'Ancho (m)', border: OutlineInputBorder()),  // Agregado: const
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alturaController,
                  decoration: const InputDecoration(labelText: 'Altura (m)', border: OutlineInputBorder()),  // Agregado: const
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),  // Agregado: const
                  label: const Text('Calcular'),  // Agregado: const
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),  // Agregado: const
                ],
                if (_piesTablares != null) ...[
                  const SizedBox(height: 20),
                  Text('Pies Tablares: ${_piesTablares!.toStringAsFixed(2)} p²', style: const TextStyle(fontWeight: FontWeight.bold)),  // Agregado: const
                  Text('Clavos 2.5'': $_clavos25', style: const TextStyle(fontWeight: FontWeight.bold)),  // Agregado: const
                  Text('Clavos 3'': $_clavos3', style: const TextStyle(fontWeight: FontWeight.bold)),  // Agregado: const
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
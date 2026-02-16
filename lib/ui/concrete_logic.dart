import 'package:flutter/material.dart';

class ConcreteCalculator extends StatefulWidget {
  const ConcreteCalculator({super.key});

  @override
  State<ConcreteCalculator> createState() => _ConcreteCalculatorState();
}

class _ConcreteCalculatorState extends State<ConcreteCalculator> {
  final TextEditingController _volumeController = TextEditingController();
  String _selectedResistance = '140';
  Map<String, dynamic>? _result;
  String? _errorMessage;

  // Tablas CAPECO aproximadas (NTP: dosificaciones estándar peruanas para concreto)
  static const Map<String, Map<String, double>> _capecoDosages = {
    '140': {'cemento': 7.5, 'arena': 0.55, 'piedra': 0.85}, // Bolsas cemento, m³ arena/piedra
    '175': {'cemento': 8.5, 'arena': 0.50, 'piedra': 0.80},
    '210': {'cemento': 9.5, 'arena': 0.45, 'piedra': 0.75},
    '245': {'cemento': 10.5, 'arena': 0.40, 'piedra': 0.70},
  };

  static const List<String> _resistances = ['140', '175', '210', '245'];

  void _calculate() {
    setState(() => _errorMessage = null);
    final volume = double.tryParse(_volumeController.text);
    // Validación NTP: Volumen debe ser positivo y resistencia válida
    if (volume == null || volume <= 0 || !_capecoDosages.containsKey(_selectedResistance)) {
      setState(() => _errorMessage = 'Ingresa un volumen válido (>0) y resistencia según CAPECO.');
      return;
    }
    try {
      final dosage = _capecoDosages[_selectedResistance]!;
      setState(() {
        _result = {
          'cemento': (dosage['cemento']! * volume).round(),
          'arena': double.parse((dosage['arena']! * volume).toStringAsFixed(2)),
          'piedra': double.parse((dosage['piedra']! * volume).toStringAsFixed(2)),
        };
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Concreto'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(  // Agregado: const a la lista
                  children: [
                    Icon(Icons.construction, color: Colors.orange, size: 28),  // Agregado: const
                    SizedBox(width: 8),
                    Text('Dosificación de Concreto (CAPECO)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),  // Agregado: const
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedResistance,  // Corregido: value → initialValue (deprecated)
                  items: _resistances.map((r) => DropdownMenuItem(value: r, child: Text("f'c = $r kg/cm²"))).toList(),
                  onChanged: (value) => setState(() => _selectedResistance = value!),
                  decoration: const InputDecoration(
                    labelText: 'Resistencia del Concreto',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volumen (m³)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calcular Dosificación'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  const Text('Desglose:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Cemento: ${_result!['cemento']} bolsas'),
                          Text('Arena: ${_result!['arena']} m³'),
                          Text('Piedra Chancada: ${_result!['piedra']} m³'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
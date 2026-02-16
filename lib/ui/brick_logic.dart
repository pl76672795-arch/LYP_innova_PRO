import 'package:flutter/material.dart';
import '../services/material_intelligence.dart';  // --- Módulo 1: Importa el servicio nuevo ---

class BrickCalculator extends StatefulWidget {
  const BrickCalculator({super.key});

  @override
  State<BrickCalculator> createState() => _BrickCalculatorState();
}

class _BrickCalculatorState extends State<BrickCalculator> {
  final TextEditingController _largoController = TextEditingController();
  final TextEditingController _anchoController = TextEditingController();
  final TextEditingController _altoController = TextEditingController();
  final TextEditingController _juntaController = TextEditingController(text: '0.015');
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _vanosController = TextEditingController();
  String _selectedType = 'Pandereta';
  int? _ladrillosTotales;
  int? _ladrillosAjustados;
  String? _errorMessage;

  // --- Módulo 1: Nuevos campos para inteligencia de materiales ---
  String _tipoObra = 'vivienda';
  String _alertaDesperdicio = '';
  double _concretoM3 = 0;
  int _capacidadCamion = 8;
  Map<String, int> _resultadoCamiones = {};

  static const List<String> _types = ['Pandereta', 'King Kong', 'Bloque de Concreto'];
  static const Map<String, Map<String, double>> _baseMeasures = {
    'Pandereta': {'largo': 0.24, 'ancho': 0.12, 'alto': 0.06},
    'King Kong': {'largo': 0.30, 'ancho': 0.15, 'alto': 0.10},
    'Bloque de Concreto': {'largo': 0.40, 'ancho': 0.20, 'alto': 0.20},
  };

  void _updateType(String type) {
    final measures = _baseMeasures[type]!;
    setState(() {
      _selectedType = type;
      _largoController.text = measures['largo']!.toString();
      _anchoController.text = measures['ancho']!.toString();
      _altoController.text = measures['alto']!.toString();
    });
  }

  void _calculate() {
    setState(() => _errorMessage = null);
    final largo = double.tryParse(_largoController.text);
    final ancho = double.tryParse(_anchoController.text);
    final area = double.tryParse(_areaController.text);
    final junta = double.tryParse(_juntaController.text);

    if (largo == null || ancho == null || area == null || junta == null ||
        largo < 0.1 || largo > 0.5 || ancho < 0.1 || ancho > 0.3 || area <= 0 || junta < 0 || junta > 0.05) {
      setState(() => _errorMessage = 'Ingresa valores válidos según NTP.');
      return;
    }
    try {
      final ladrilloLargoConJunta = largo + junta;
      final ladrilloAnchoConJunta = ancho + junta;
      final ladrillosPorM2 = (1 / ladrilloLargoConJunta) * (1 / ladrilloAnchoConJunta);
      setState(() => _ladrillosTotales = (ladrillosPorM2 * area).ceil());
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo.');
    }
  }

  void _calcularConVanos() {
    _calculate();
    if (_ladrillosTotales != null) {
      final areaVanos = double.tryParse(_vanosController.text) ?? 0.0;
      final areaTotal = double.tryParse(_areaController.text) ?? 0;
      if (areaVanos >= areaTotal) {
        setState(() => _errorMessage = 'Área de vanos no puede ser mayor o igual al área total.');
        return;
      }
      final areaAjustada = areaTotal - areaVanos;
      if (areaAjustada > 0) {
        _ladrillosAjustados = (_ladrillosTotales! * (areaAjustada / areaTotal)).ceil();
      } else {
        _ladrillosAjustados = 0;
      }
      setState(() {});
    }
  }

  void _calcularConInteligencia() {
    _calcularConVanos();
    if (_ladrillosTotales != null) {
      final desperdicio = double.tryParse(_juntaController.text) ?? 0;
      _alertaDesperdicio = MaterialIntelligence.alertarDesperdicio(desperdicio, _tipoObra);
      _resultadoCamiones = MaterialIntelligence.convertirConcretoACamiones(_concretoM3, _capacidadCamion);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _largoController.dispose();
    _anchoController.dispose();
    _altoController.dispose();
    _juntaController.dispose();
    _areaController.dispose();
    _vanosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albañilería Editable - NTP'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Colors.orange.withValues(alpha: 25.5),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.brightness_5, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Text('Cálculo de Ladrillos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,  // Ya correcto
                    items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (value) => _updateType(value!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Ladrillo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Medidas Personalizadas (m)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _largoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Largo Ladrillo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _anchoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ancho Ladrillo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _altoController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Alto Ladrillo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _juntaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Espesor Junta (m)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.layers),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _areaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Área del Muro (m²)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.aspect_ratio),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vanosController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Área de Vanos (puertas/ventanas, m²)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.door_front_door),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Inteligencia de Materiales (CAPECO)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoObra,  // --- Corregido: value → initialValue ---
                    items: ['vivienda', 'comercial', 'industrial'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _tipoObra = v!),
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Obra',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Concreto (m³) para Camiones',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _concretoM3 = double.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _capacidadCamion,  // --- Corregido: value → initialValue ---
                    items: [8, 10].map((e) => DropdownMenuItem(value: e, child: Text('$e m³'))).toList(),
                    onChanged: (v) => setState(() => _capacidadCamion = v!),
                    decoration: const InputDecoration(
                      labelText: 'Capacidad Camión Mixer',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade900,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _calcularConInteligencia,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular con Inteligencia'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                  if (_ladrillosTotales != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Ladrillos Totales: $_ladrillosTotales',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  if (_ladrillosAjustados != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Ladrillos Ajustados (descontando vanos): $_ladrillosAjustados',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  if (_alertaDesperdicio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.blue.shade100,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Alerta CAPECO: $_alertaDesperdicio',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                  if (_resultadoCamiones.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.green.shade100,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Camiones Mixer: ${_resultadoCamiones['camiones']}, Sobrante: ${_resultadoCamiones['sobrante']} m³',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
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
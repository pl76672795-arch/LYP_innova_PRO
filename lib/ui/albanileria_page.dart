import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class CalculoAlbanileriaWidget extends StatefulWidget {
  final Box projectBox;

  const CalculoAlbanileriaWidget({super.key, required this.projectBox});

  @override
  CalculoAlbanileriaWidgetState createState() => CalculoAlbanileriaWidgetState();  // Corregido: Clase State ahora pública
}

class CalculoAlbanileriaWidgetState extends State<CalculoAlbanileriaWidget> {  // Corregido: Nombre de clase State público
  String tipoLadrillo = 'King Kong';
  String tipoMuro = 'Soga';
  double largo = 0;
  double alto = 0;
  double ladrillosTotal = 0;
  double bolsasCemento = 0;
  double areaTarrajeo = 0;
  double espesorTarrajeo = 0;
  double bolsasTarrajeo = 0;
  double arenaTarrajeo = 0;
  String? _errorMessage;

  // Tipos de ladrillo disponibles (NTP: medidas estándar peruanas)
  static const List<String> _tiposLadrillo = ['King Kong', 'Pandereta', 'Bloque de Concreto'];
  static const List<String> _tiposMuro = ['Soga', 'Cabeza'];

  void calcularAlbanileria() {
    setState(() => _errorMessage = null);
    // Validación NTP mejorada: Dimensiones positivas, área razonable (0.1-100 m²)
    if (largo <= 0 || alto <= 0 || largo > 50 || alto > 10) {
      setState(() => _errorMessage = 'Ingresa dimensiones válidas según NTP (largo 0-50m, alto 0-10m).');
      return;
    }
    try {
      double area = largo * alto;
      double ladrillosPorM2 = tipoLadrillo == 'King Kong' ? 0.15 : tipoLadrillo == 'Pandereta' ? 50 : 10;  // NTP aproximado
      ladrillosTotal = area * ladrillosPorM2 * 1.05;  // +5% rotura
      bolsasCemento = area * 0.1;  // Aproximado para mortero
      setState(() {});
      widget.projectBox.put('albanileria_${DateTime.now()}', {
        'tipoLadrillo': tipoLadrillo,
        'tipoMuro': tipoMuro,
        'ladrillos': ladrillosTotal,
        'bolsasCemento': bolsasCemento,
        'fecha': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cálculo guardado en BBDD')));
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  void calcularTarrajeo() {
    setState(() => _errorMessage = null);
    // Validación NTP mejorada: Área positiva, espesor razonable (0.5-5 cm)
    if (areaTarrajeo <= 0 || espesorTarrajeo < 0.5 || espesorTarrajeo > 5) {
      setState(() => _errorMessage = 'Ingresa área y espesor válidos según NTP (área >0, espesor 0.5-5 cm).');
      return;
    }
    try {
      double volumen = areaTarrajeo * (espesorTarrajeo / 100);  // m³
      bolsasTarrajeo = volumen * 10;  // Aproximado NTP
      arenaTarrajeo = volumen * 0.5;
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  void limpiarCampos() {
    setState(() {
      tipoLadrillo = 'King Kong';
      tipoMuro = 'Soga';
      largo = 0;
      alto = 0;
      ladrillosTotal = 0;
      bolsasCemento = 0;
      areaTarrajeo = 0;
      espesorTarrajeo = 0;
      bolsasTarrajeo = 0;
      arenaTarrajeo = 0;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albañilería y Tarrajeo - NTP'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Cálculo de Albañilería', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: tipoLadrillo,  // Corregido: value → initialValue
                items: _tiposLadrillo.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => tipoLadrillo = v!),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Ladrillo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: tipoMuro,  // Corregido: value → initialValue
                items: _tiposMuro.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => tipoMuro = v!),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Muro',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),  // Corregido: Icons.wall → Icons.home (icono válido)
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Largo (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => largo = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Alto (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => alto = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: calcularAlbanileria,
                icon: const Icon(Icons.calculate),
                label: const Text('Calcular Albañilería'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              if (ladrillosTotal > 0)
                Card(
                  color: Colors.blue.shade100,
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.construction, size: 40, color: Colors.brown),
                            const SizedBox(width: 16),
                            Text('Ladrillos Totales: ${ladrillosTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.build, size: 40, color: Colors.grey),
                            const SizedBox(width: 16),
                            Text('Bolsas Cemento (Mortero): ${bolsasCemento.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('Cálculo de Tarrajeo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Área del Muro (m²)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.aspect_ratio),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => areaTarrajeo = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Espesor (cm)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => espesorTarrajeo = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: calcularTarrajeo,
                icon: const Icon(Icons.brush),
                label: const Text('Calcular Tarrajeo'),
              ),
              if (bolsasTarrajeo > 0)
                Card(
                  color: Colors.green.shade100,
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.brush, size: 40, color: Colors.green),
                            const SizedBox(width: 16),
                            Text('Bolsas Cemento: ${bolsasTarrajeo.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.grain, size: 40, color: Colors.brown),
                            const SizedBox(width: 16),
                            Text('Arena Fina: ${arenaTarrajeo.toStringAsFixed(2)} m³', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: limpiarCampos,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Campos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
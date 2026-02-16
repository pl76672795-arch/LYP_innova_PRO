import 'package:flutter/material.dart';

class CalculoAceroWidget extends StatefulWidget {
  const CalculoAceroWidget({super.key});

  @override
  CalculoAceroWidgetState createState() => CalculoAceroWidgetState();  // Corregido: Clase State ahora pública
}

class CalculoAceroWidgetState extends State<CalculoAceroWidget> {  // Corregido: Nombre de clase State público
  String diametro = '3/8"';
  double longitudTotal = 0;
  double factorDesperdicio = 0.05;
  double pesoTotal = 0;
  double varillas9m = 0;
  String? _errorMessage;

  // Diámetros disponibles (NTP: diámetros estándar para acero de refuerzo)
  static const List<String> _diameters = ['3/8"', '1/2"', '5/8"', '3/4"', '1"'];

  void calcularAcero() {
    setState(() => _errorMessage = null);
    // Validación NTP mejorada: Longitud positiva, factor de desperdicio razonable (0.05-0.07)
    if (longitudTotal <= 0 || factorDesperdicio < 0.05 || factorDesperdicio > 0.07) {
      setState(() => _errorMessage = 'Ingresa valores válidos según NTP (longitud >0, desperdicio 5-7%).');
      return;
    }
    try {
      double pesoPorMetro = diametro == '3/8"' ? 0.56 : diametro == '1/2"' ? 0.89 : diametro == '5/8"' ? 1.58 : diametro == '3/4"' ? 2.47 : 3.97;  // NTP
      double longitudConDesperdicio = longitudTotal * (1 + factorDesperdicio);
      pesoTotal = longitudConDesperdicio * pesoPorMetro;
      varillas9m = longitudConDesperdicio / 9;
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = 'Error en cálculo. Verifica datos.');
    }
  }

  void limpiarCampos() {
    setState(() {
      diametro = '3/8"';
      longitudTotal = 0;
      factorDesperdicio = 0.05;
      pesoTotal = 0;
      varillas9m = 0;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cálculo de Acero - NTP'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Selecciona Diámetro y Factor de Desperdicio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: diametro,  // --- Corregido: value → initialValue ---
                items: _diameters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => diametro = v!),
                decoration: const InputDecoration(
                  labelText: 'Diámetro de Acero',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Longitud Total (m)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => longitudTotal = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 16),
              Slider(
                value: factorDesperdicio,
                min: 0.05,
                max: 0.07,
                divisions: 2,
                label: '${(factorDesperdicio * 100).toInt()}%',
                onChanged: (v) => setState(() => factorDesperdicio = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: calcularAcero,
                      icon: const Icon(Icons.calculate),
                      label: const Text('Calcular Acero'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: limpiarCampos,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar Campos'),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
              if (pesoTotal > 0)
                Card(
                  color: Colors.red.shade100,
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.build, size: 40, color: Colors.red),
                            const SizedBox(width: 16),
                            Text('Peso Total: ${pesoTotal.toStringAsFixed(2)} kg', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 40, color: Colors.blue),
                            const SizedBox(width: 16),
                            Text('Varillas 9m Necesarias: ${varillas9m.toStringAsFixed(1)}', style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
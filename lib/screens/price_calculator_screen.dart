import 'package:flutter/material.dart';
import '../material_calculator.dart'; // Importa desde lib/material_calculator.dart

class PriceCalculatorScreen extends StatefulWidget {
  final Map<String, dynamic> resumenMateriales; // Pasa el resumen de MaterialCalculator

  const PriceCalculatorScreen({super.key, required this.resumenMateriales});

  @override
  State<PriceCalculatorScreen> createState() => _PriceCalculatorScreenState();
}

class _PriceCalculatorScreenState extends State<PriceCalculatorScreen> {
  double precioBolsaCemento = 28.0; // Precio por bolsa (S/)
  double precioLataArena = 150.0 * 0.019; // Precio por lata de arena (S/), ajustado a volumen
  double precioLataPiedra = 180.0 * 0.019; // Precio por lata de piedra (S/), ajustado a volumen
  double costoTotal = 0.0;

  void _calcularCosto() {
    final unidades = widget.resumenMateriales['unidades_comerciales'] as Map<String, double>;
    costoTotal = MaterialCalculator.calcularCostoTotal(
      unidades,
      precioBolsaCemento,
      precioLataArena,
      precioLataPiedra,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Costo por Vaciado - LYP INNOVA'),
        backgroundColor: Colors.orange[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa Precios Unitarios (S/)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por bolsa de cemento (42.5kg)'),
              onChanged: (value) => precioBolsaCemento = double.tryParse(value) ?? 28.0,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por lata de arena (19L)'),
              onChanged: (value) => precioLataArena = double.tryParse(value) ?? 150.0 * 0.019,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio por lata de piedra (19L)'),
              onChanged: (value) => precioLataPiedra = double.tryParse(value) ?? 180.0 * 0.019,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calcularCosto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                minimumSize: const Size(double.infinity, 50), // Botón grande para visibilidad
              ),
              child: const Text('Calcular Presupuesto Total', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            Text(
              'Presupuesto Total: S/ ${costoTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Resumen de Materiales:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Bolsas de Cemento: ${widget.resumenMateriales['unidades_comerciales']['bolsas_cemento']?.toStringAsFixed(1) ?? '0'}'),
            Text('Latas de Arena: ${widget.resumenMateriales['unidades_comerciales']['latas_arena']?.toStringAsFixed(1) ?? '0'}'),
            Text('Latas de Piedra: ${widget.resumenMateriales['unidades_comerciales']['latas_piedra']?.toStringAsFixed(1) ?? '0'}'),
          ],
        ),
      ),
    );
  }
}
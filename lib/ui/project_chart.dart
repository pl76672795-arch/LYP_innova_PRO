import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProjectPieChart extends StatelessWidget {
  final Map<String, dynamic> proyecto;

  const ProjectPieChart({super.key, required this.proyecto});

  @override
  Widget build(BuildContext context) {
    // Calcula proporciones (ejemplo: volumen o costo)
    double cemento = proyecto['bolsas_cemento'] ?? 0;
    double arena = proyecto['arena_m3'] ?? 0;
    double piedra = proyecto['piedra_m3'] ?? 0;
    double total = cemento + arena + piedra;

    if (total == 0) return const Text('Sin datos para gráfico.');

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: (cemento / total) * 100,
            title: 'Cemento ${(cemento / total * 100).toInt()}%',
            color: Colors.orange,
          ),
          PieChartSectionData(
            value: (arena / total) * 100,
            title: 'Arena ${(arena / total * 100).toInt()}%',
            color: Colors.blue,
          ),
          PieChartSectionData(
            value: (piedra / total) * 100,
            title: 'Piedra ${(piedra / total * 100).toInt()}%',
            color: Colors.brown,
          ),
        ],
      ),
    );
  }
}

// Integración: Agrega en results_screen.dart dentro de _buildSingleCard o _buildBatchCards
// Ejemplo: Column(children: [ProjectPieChart(proyecto: item), ...])
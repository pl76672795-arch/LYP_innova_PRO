import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';  // --- Módulo 2: Ya tienes en YAML ---

class LadrilloPainter extends CustomPainter {
  final String tipoSentado;
  final double scale;

  LadrilloPainter(this.tipoSentado, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final paint = Paint()..color = Colors.brown..style = PaintingStyle.fill;
    const rect = Rect.fromLTWH(50, 50, 100, 50);
    canvas.drawRect(rect, paint);

    final linePaint = Paint()..color = Colors.black..strokeWidth = 2;
    if (tipoSentado == 'soga') {
      canvas.drawLine(const Offset(50, 60), const Offset(150, 60), linePaint);
      canvas.drawLine(const Offset(50, 80), const Offset(150, 80), linePaint);
    } else {
      canvas.drawLine(const Offset(70, 50), const Offset(70, 100), linePaint);
      canvas.drawLine(const Offset(110, 50), const Offset(110, 100), linePaint);
    }

    final textPainter = TextPainter(
      text: TextSpan(text: '20cm x 10cm\nTipo: $tipoSentado\nNTP 334.XXX & RNE', style: const TextStyle(color: Colors.black, fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 110));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class FierroPainter extends CustomPainter {
  final String diametro;
  final double longitud;
  final double scale;

  FierroPainter(this.diametro, this.longitud, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final paint = Paint()..color = Colors.grey..style = PaintingStyle.fill;
    const start = Offset(50, 75);
    final end = Offset(50 + longitud * 10, 75);
    canvas.drawLine(start, end, paint..strokeWidth = 5);

    final radius = diametro == '3/8 pulg' ? 3 : diametro == '1/2 pulg' ? 5 : 7;
    canvas.drawCircle(start, radius.toDouble(), paint);
    canvas.drawCircle(end, radius.toDouble(), paint);

    canvas.drawCircle(const Offset(100, 75), radius.toDouble() * 0.5, paint..color = Colors.red);

    final textPainter = TextPainter(
      text: TextSpan(text: 'Diámetro: $diametro\nLongitud: ${longitud.toStringAsFixed(1)}m\nCorte: Circular\nNTP 334.XXX & RNE', style: const TextStyle(color: Colors.black, fontSize: 12)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 90));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> resultado;

  const ResultsScreen({super.key, required this.resultado});

  @override
  ResultsScreenState createState() => ResultsScreenState();  // Corregido: Clase State ahora pública
}

class ResultsScreenState extends State<ResultsScreen> {  // Corregido: Nombre de clase State público
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados Inteligentes - Ley Peruana'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    const Text('Cumplimiento con Ley Peruana de Construcción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildLawBadge('RNC', 'Reglamento Nacional de Construcciones', 'Normas generales para edificaciones.'),
                        _buildLawBadge('NTP', 'Normas Técnicas Peruanas', 'Especificaciones técnicas detalladas.'),
                        _buildLawBadge('RNE', 'Reglamento Nacional de Edificaciones', 'Aprobación y seguridad estructural.'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (widget.resultado.containsKey('batch')) ..._buildBatchCards(widget.resultado['batch']),
              if (!widget.resultado.containsKey('batch')) _buildSingleCard(widget.resultado),
              if (widget.resultado.containsKey('bolsas_cemento')) _buildChart(widget.resultado),
              if (widget.resultado.containsKey('tipo_grafico')) _buildCustomGraphic(widget.resultado),
              // --- Módulo 2: Agregar PieChart dinámico para proyectos ---
              _buildPieChart(widget.resultado),  // Nuevo: Gráfico de proporciones
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar a PDF (RNE Compliant)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF generado según RNE, RNC y NTP')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawBadge(String code, String name, String description) {
    return Tooltip(
      message: description,
      child: Chip(
        label: Text(code, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        onDeleted: () {},
      ),
    );
  }

  List<Widget> _buildBatchCards(List<Map<String, dynamic>> batch) {
    return batch.map((item) => AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListTile(
            leading: Icon(item['resumen_total'] == true ? Icons.summarize : Icons.build, color: Colors.orange, size: 40),
            title: Text(item['resumen_total'] == true ? 'Resumen Total' : 'Partida: ${item['partida'] ?? 'N/A'}', style: const TextStyle(fontSize: 18)),
            subtitle: Text(
              item['resumen_total'] == true
                  ? 'Cemento: ${item['total_cemento_bolsas']?.toStringAsFixed(1)} bolsas\nArena: ${item['total_arena_m3']?.toStringAsFixed(2)} m³\nPiedra: ${item['total_piedra_m3']?.toStringAsFixed(2)} m³\nAcero: ${item['total_acero_varillas']} varillas\n${item['sugerencia']}'
                  : 'Cemento: ${item['bolsas_cemento']} bolsas\nArena: ${item['arena_m3']} m³\nPiedra: ${item['piedra_m3']} m³\n${item['sugerencia'] ?? ''}',
              style: const TextStyle(height: 1.5),
            ),
          ),
        ),
      ),
    )).toList();
  }

  Widget _buildSingleCard(Map<String, dynamic> item) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListTile(
            leading: const Icon(Icons.build, color: Colors.blue, size: 40),
            title: const Text('Resultado', style: TextStyle(fontSize: 18)),
            subtitle: Text(item.keys.map((key) => '$key: ${item[key]}').join('\n'), style: const TextStyle(height: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> item) {
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: item['bolsas_cemento'] ?? 0, color: Colors.orange)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: item['arena_m3'] ?? 0, color: Colors.blue)]),
            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: item['piedra_m3'] ?? 0, color: Colors.green)]),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Cemento'));
                case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Arena'));
                case 2: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Piedra'));
                default: return const Text('');
              }
            })),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomGraphic(Map<String, dynamic> item) {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(0.5, 3.0);
        });
      },
      child: SizedBox(
        height: 200,
        child: item['tipo_grafico'] == 'ladrillo'
            ? CustomPaint(painter: LadrilloPainter(item['tipo_muro'] ?? 'soga', _scale))
            : item['tipo_grafico'] == 'acero'
                ? CustomPaint(painter: FierroPainter(item['diametro'] ?? '1/2 pulg', item['metros_lineales'] ?? 9.0, _scale))
                : const SizedBox.shrink(),
      ),
    );
  }

  // --- Módulo 2: Nuevo método para PieChart dinámico ---
  Widget _buildPieChart(Map<String, dynamic> proyecto) {
    // Calcula proporciones basadas en datos del proyecto (cemento, arena, piedra)
    double cemento = proyecto['bolsas_cemento'] ?? 0;
    double arena = proyecto['arena_m3'] ?? 0;
    double piedra = proyecto['piedra_m3'] ?? 0;
    double total = cemento + arena + piedra;

    if (total == 0) {
      return const SizedBox.shrink();  // No mostrar si no hay datos
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Proporciones de Materiales (PieChart)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: (cemento / total) * 100,
                      title: 'Cemento\n${((cemento / total) * 100).toInt()}%',
                      color: Colors.orange,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: (arena / total) * 100,
                      title: 'Arena\n${((arena / total) * 100).toInt()}%',
                      color: Colors.blue,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: (piedra / total) * 100,
                      title: 'Piedra\n${((piedra / total) * 100).toInt()}%',
                      color: Colors.brown,
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Visualiza costos/volumen de un vistazo (NTP Compliant)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
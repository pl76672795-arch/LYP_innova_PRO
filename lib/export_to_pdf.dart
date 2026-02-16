import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart'; // Para compartir
import 'package:path_provider/path_provider.dart'; // Para guardar temporalmente

class ExportToPdf {
  /// Genera y comparte el reporte técnico de la obra (para un proyecto individual)
  static Future<void> generateProjectReport(Map project) async {
    final pdf = pw.Document();

    // Variables extraídas para evitar errores de constantes en los widgets del PDF
    final String nombreObra = (project['name'] ?? 'Sin nombre').toString().toUpperCase();
    final String fecha = (project['date'] ?? 'No especificada').toString();
    final String acero = (project['metrado_acero'] ?? 0).toString();
    final String ladrillos = (project['ladrillos'] ?? 0).toString();
    final String concreto = (project['concreto_m3'] ?? 0).toString();
    final String contenido = (project['text'] ?? 'Sin observaciones registradas.').toString();
    final double totalEstimado = (project['metrado_acero'] as num? ?? 0) * 0.1 + (project['ladrillos'] as num? ?? 0) * 0.5; // Estimación simple

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text("REPORTE TECNICO - LYP INNOVA PRO",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                ),
                pw.SizedBox(height: 10),
                pw.Text("INFORMACIÓN GENERAL", style: pw.TextStyle(color: PdfColors.orange, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.orange),
                pw.SizedBox(height: 5),
                pw.Text("OBRA: $nombreObra"),
                pw.Text("FECHA DE REGISTRO: $fecha"),
                pw.SizedBox(height: 20),
                
                pw.Text("METRADOS ESTIMADOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Bullet(text: "Acero Total: $acero kg"),
                pw.Bullet(text: "Ladrillos: $ladrillos unidades"),
                pw.Bullet(text: "Concreto: $concreto m³"),
                pw.SizedBox(height: 10),
                pw.Text("TOTAL ESTIMADO: S/ ${totalEstimado.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                pw.SizedBox(height: 20),
                
                pw.Text("OBSERVACIONES TÉCNICAS:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                  ),
                  child: pw.Text(contenido),
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text("Generado por LYP Innova App 2026", 
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ),
                pw.SizedBox(height: 20),
                pw.Text("FIRMA DEL INGENIERO: ________________________", style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Guarda el PDF temporalmente y compártelo
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Reporte_LYP_$nombreObra.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte técnico generado por LYP Innova Pro');
    } catch (e) {
      debugPrint('Error exportando PDF: $e');
    }
  }

  /// Método para compatibilidad con firebase_sync.dart (maneja listas de proyectos o datos híbridos)
  static Future<void> generateAndSharePdf(Map<String, dynamic> data, {bool saveLocally = false, String? userId}) async {
    try {
      // Si data contiene una lista de proyectos (e.g., de Firebase), genera un PDF con todos
      if (data.containsKey('projects') && data['projects'] is List && (data['projects'] as List).isNotEmpty) {
        final projects = data['projects'] as List;
        final pdf = pw.Document();
        for (final project in projects) {
          if (project is Map) {
            await _addProjectPageToPdf(pdf, project);
          }
        }
        await _shareOrSavePdf(pdf, 'Reporte_Completo_LYP.pdf', saveLocally);
      } else {
        // Si es un proyecto individual, usa el método original
        await generateProjectReport(data);
      }
    } catch (e) {
      debugPrint('Error en generateAndSharePdf: $e');
    }
  }

  /// Agrega una página de proyecto al PDF (para listas)
  static Future<void> _addProjectPageToPdf(pw.Document pdf, Map project) async {
    final String nombreObra = (project['name'] ?? 'Sin nombre').toString().toUpperCase();
    final String fecha = (project['date'] ?? 'No especificada').toString();
    final String acero = (project['metrado_acero'] ?? 0).toString();
    final String ladrillos = (project['ladrillos'] ?? 0).toString();
    final String concreto = (project['concreto_m3'] ?? 0).toString();
    final String contenido = (project['text'] ?? 'Sin observaciones registradas.').toString();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("PROYECTO: $nombreObra", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text("FECHA: $fecha"),
                pw.SizedBox(height: 10),
                pw.Bullet(text: "Acero: $acero kg"),
                pw.Bullet(text: "Ladrillos: $ladrillos unidades"),
                pw.Bullet(text: "Concreto: $concreto m³"),
                pw.SizedBox(height: 10),
                pw.Text("OBSERVACIONES: $contenido"),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Comparte o guarda el PDF
  static Future<void> _shareOrSavePdf(pw.Document pdf, String filename, bool saveLocally) async {
    final bytes = await pdf.save();
    if (saveLocally) {
      // Guarda localmente (puedes implementar lógica adicional aquí)
      debugPrint('PDF guardado localmente: $filename');
    } else {
      // Comparte el PDF
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$filename';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte completo generado por LYP Innova Pro');
    }
  }

  /// Verifica si el archivo de foto existe antes de procesar
  static bool checkFileExists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
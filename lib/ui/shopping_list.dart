import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart'; // AGREGADO: Para compartir PDFs
import 'package:path_provider/path_provider.dart'; // AGREGADO: Para guardar temporalmente PDFs
import 'dart:io'; // AGREGADO: Para File
import 'package:url_launcher/url_launcher.dart';

/// ShoppingList: Lista de compras de materiales para obras civiles.
/// Cumple con NTP (Norma Técnica Peruana) para trazabilidad y gestión de recursos.
/// Optimizada: Stateful para manejar async correctamente, con feedback mejorado.
class ShoppingList extends StatefulWidget {
  final Map<String, dynamic> materials; // Ej: {'cemento': 10, 'arena': 5.2, ...}

  const ShoppingList({required this.materials, super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  bool _isLoading = false;

  Future<void> _generateAndSharePdf() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Lista de Compras - LYP Innova Pro', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text('Cumple con NTP para trazabilidad en obras civiles.', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 20),
                ...widget.materials.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
              ],
            ),
          ),
        ),
      );

      // Guarda el PDF temporalmente y compártelo
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Lista_Compras.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(filePath)], text: 'Lista de compras generada por LYP Innova Pro');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF compartido exitosamente 📄'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error generando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar PDF'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareViaWhatsApp() async {
    try {
      final message = 'Lista de Compras (NTP):\n${widget.materials.entries.map((e) => '${e.key}: ${e.value}').join('\n')}';
      final url = 'https://wa.me/?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp no disponible')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error compartiendo via WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al compartir')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras - NTP'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Resumen de Materiales',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: widget.materials.entries.map((e) => Card(
                        color: Colors.orange.withValues(alpha: 25.5),
                        child: ListTile(
                          title: Text(e.key),
                          subtitle: Text(e.value.toString()),
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: _generateAndSharePdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Generar PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: _shareViaWhatsApp,
                          icon: const Icon(Icons.share),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
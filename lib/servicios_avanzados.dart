import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'core_integracion.dart';

class ServiciosAvanzados {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'pyl_innova.db'),
      onCreate: (db, v) => db.execute("CREATE TABLE registros(id INTEGER PRIMARY KEY, data TEXT, fecha TEXT)"),
      version: 1,
    );
    return _db!;
  }

  static Future<void> guardarDato(String info) async {
    final db = await database;
    await db.insert('registros', {'data': info, 'fecha': DateTime.now().toString()});
    if (kDebugMode) debugPrint("[TELEMETRIA SERVICIOS] Dato guardado NTP: $info");
  }

  static Future<void> generarReporte() async {
    try {
      final pdf = pw.Document();
      final db = await database;
      final List<Map<String, dynamic>> logs = await db.query('registros', orderBy: 'id DESC');

      pdf.addPage(pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("P&L INNOVA - SOLUCIONES DIGITALES")),
          pw.Divider(),
          ...logs.map((e) => pw.Text("${e['fecha'].toString().substring(0,16)} >> VALOR: ${e['data']}")),
        ],
      ));

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Reporte_P&L_INNOVA.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte P&L generado por LYP Innova');
      if (kDebugMode) debugPrint("[TELEMETRIA SERVICIOS] Reporte P&L generado y compartido NTP");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA SERVICIOS] Error generando reporte P&L NTP: $e");
      rethrow;
    }
  }

  static Future<void> generarReporteEjecutivo(BuildContext context) async {
    try {
      // ✅ Movido al principio para evitar async gap con BuildContext
      final alerta20 = await CoreIntegracion.alertaCajaChicaSupera20(context);

      final dbHelper = DatabaseHelper.instance;
      final valorizacion = await dbHelper.valorizacionObra();
      final totalGastos = await dbHelper.totalGastosCajaChica();
      final utilidad = valorizacion - totalGastos;
      final metrosAcero = await dbHelper.totalMetrosAcero();
      final pesoAceroKg = await dbHelper.totalPesoAceroKg();
      
      final porcentajeGasto = await CoreIntegracion.porcentajeGastoVsValorizacion();

      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, child: pw.Text("REPORTE EJECUTIVO - LYP INNOVA", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Text("Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}", style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
            pw.SizedBox(height: 15),
            pw.Text("UTILIDAD ACTUAL (S/.)", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text("S/ ${utilidad.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Valorización: S/ ${valorizacion.toStringAsFixed(2)} | Gastos Caja Chica: S/ ${totalGastos.toStringAsFixed(2)} (${porcentajeGasto.toStringAsFixed(1)}%)", style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            pw.Text("METRADO ACERO", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text("Metros usados: ${metrosAcero.toStringAsFixed(2)} m | Peso total: ${pesoAceroKg.toStringAsFixed(2)} kg", style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 20),
            pw.Text("ALERTAS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: alerta20 ? PdfColors.red100 : PdfColors.green50,
              child: pw.Text(
                alerta20 ? "⚠ GASTO CAJA CHICA SUPERA 20% DE VALORIZACIÓN (${porcentajeGasto.toStringAsFixed(1)}%)" : "✓ Caja Chica dentro del límite (${porcentajeGasto.toStringAsFixed(1)}%)",
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: alerta20 ? PdfColors.red900 : PdfColors.green800),
              ),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text("2026 © LYP INNOVA - INGENIERÍA PERÚ", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ],
        ),
      ));

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Reporte_Ejecutivo_LYP_INNOVA.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(filePath)], text: 'Reporte Ejecutivo generado por LYP Innova');
      if (kDebugMode) debugPrint("[TELEMETRIA SERVICIOS] Reporte Ejecutivo generado y compartido NTP");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA SERVICIOS] Error generando reporte Ejecutivo NTP: $e");
      rethrow;
    }
  }
}
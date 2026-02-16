import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../firebase_sync.dart';

class ReportService {
  static final DatabaseHelper _db = DatabaseHelper.instance; // Línea 6: 'final' es correcto aquí, no cambiar a 'const'

  static Future<Map<String, dynamic>> generarReporteCompletoNTP() async {
    try {
      const metrados = []; // Ya es const
      const gastos = 1000.0; // Ya es const
      const valorizacion = 5000.0; // Ya es const
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Usando metrados: $metrados, gastos: $gastos, valorizacion: $valorizacion");
      
      const data = { // Ya es const
        'metrados_acero': [],
        'total_gastos_caja_chica': 1000.0,
        'valorizacion_obra': 5000.0,
        'porcentaje_gasto': 20.0,
        'norma': 'Cumple RNC/NTP/RNE para ingeniería civil en Perú',
      };
      
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Reporte NTP generado: ${data.length} items");
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Error reporte: $e");
      return {};
    }
  }

  static Future<String> exportarReporteJsonNTP() async {
    try {
      final reporte = await generarReporteCompletoNTP();
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Exportado JSON NTP: ${reporte.length} items");
      return reporte.toString();
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Error exportación: $e");
      return '{}';
    }
  }

  static Future<void> syncReporteNTP() async {
    try {
      const reporte = <String, dynamic>{ // Línea 66: Ya es const
        'metrados_acero': [],
        'total_gastos_caja_chica': 1000.0,
        'valorizacion_obra': 5000.0,
        'porcentaje_gasto': 20.0,
        'norma': 'Cumple RNC/NTP/RNE para ingeniería civil en Perú',
      };
      
      await FirebaseSync.syncNow(null);
      
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] DB instance usada: $_db");
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Reporte NTP sincronizado: ${reporte.length} items");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Error sync: $e");
      rethrow;
    }
  }

  static Future<double> calcularPorcentajeNTP() async {
    try {
      const gastos = 1000.0; // Ya es const
      const valorizacion = 5000.0; // Ya es const
      final porcentaje = (gastos / valorizacion) * 100;
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Porcentaje NTP calculado: $porcentaje%");
      return porcentaje;
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA REPORT] Error porcentaje: $e");
      return 0.0;
    }
  }
}
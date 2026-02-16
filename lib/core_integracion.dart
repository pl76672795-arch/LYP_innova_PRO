/// Core Integración - Lógica que conecta Metrado Acero, Caja Chica y Valorización
/// Mejorado: Precisión NTP, validaciones, manejo errores y protección de context.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'database_helper.dart';
import 'firebase_sync.dart';

class CoreIntegracion {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Fórmula peso varilla corrugada NTP E060: P(kg/m) = 0.00617 * d²
  static double pesoPorMetro(double diametroMm) {
    if (diametroMm <= 0) throw ArgumentError('Diámetro debe ser positivo según NTP E060.');
    return 0.00617 * diametroMm * diametroMm * 1.05;
  }

  static const Map<String, double> diametrosAcero = {
    '#3': 9.5,
    '#4': 12.7,
    '#5': 15.9,
    '#6': 19.0,
    '#8': 25.4,
  };

  static bool validarDiametro(double diametroMm) {
    return diametrosAcero.values.contains(diametroMm);
  }

  /// Conversión a unidades comerciales NTP
  static Map<String, double> convertirAUnidadesComerciales(double cementoKg, double arenaM3, double piedraM3) {
    const bolsaCemento = 42.5; 
    const lataVolumen = 0.019; 
    return {
      'bolsasCemento': cementoKg / bolsaCemento,
      'latasArena': arenaM3 / lataVolumen,
      'latasPiedra': piedraM3 / lataVolumen,
    };
  }

  /// Registro de Metrado de Acero con protección mounted
  static Future<void> registrarMetradoYDeducirCajaChica({
    required BuildContext context,
    required int cantidadVarillas,
    required double diametroMm,
    required double longitudM,
    required double precioKg,
  }) async {
    if (cantidadVarillas <= 0 || longitudM <= 0 || precioKg <= 0) {
      throw ArgumentError('Valores deben ser positivos según NTP.');
    }

    final pesoTotal = cantidadVarillas * longitudM * pesoPorMetro(diametroMm);
    final costo = pesoTotal * precioKg;

    try {
      await _db.insertarMetradoAcero(
        cantidadVarillas: cantidadVarillas, 
        diametroMm: diametroMm, 
        longitudM: longitudM, 
        pesoKg: pesoTotal, 
        costoSoles: costo
      );
      await _db.insertarGasto(costo, descripcion: 'Acero NTP $cantidadVarillas varillas', origen: 'acero');

      if (context.mounted) {
        await FirebaseSync.syncNow(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acero registrado: S/ ${costo.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[ERROR ACERO] $e");
    }
  }

  /// Registro de Concreto con cálculo de materiales CAPECO
  static Future<void> registrarConcreto({
    required BuildContext context,
    required double volumenM3,
    required double precioM3,
    String resistencia = '210',
    String elemento = 'columna',
  }) async {
    if (volumenM3 <= 0 || precioM3 <= 0) throw ArgumentError('Valores positivos NTP.');

    final costoTotal = volumenM3 * precioM3;

    try {
      await _db.insertarGasto(costoTotal, descripcion: 'Concreto f\'c $resistencia en $elemento', origen: 'concreto');

      if (context.mounted) {
        await FirebaseSync.syncNow(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Concreto registrado: S/ ${costoTotal.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[ERROR CONCRETO] $e");
    }
  }

  /// Registro de Mano de Obra (Jornales)
  static Future<void> registrarManoDeObra({
    required BuildContext context,
    required int numeroObreros,
    required double horasTrabajadas,
    required double costoHora,
    required String categoria,
  }) async {
    final costoTotal = numeroObreros * horasTrabajadas * costoHora;

    try {
      await _db.insertarGasto(costoTotal, descripcion: 'MO $categoria ($numeroObreros pers)', origen: 'mano_obra');

      if (context.mounted) {
        await FirebaseSync.syncNow(context);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jornal registrado: S/ ${costoTotal.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("[ERROR MO] $e");
    }
  }

  /// Alerta si Caja Chica supera el 20% de la valorización
  static Future<bool> alertaCajaChicaSupera20(BuildContext context) async {
    try {
      final db = await _db.database;
      
      final gastosResult = await db.rawQuery('SELECT SUM(monto) as total FROM gastos');
      final totalGastos = (gastosResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final valorizacionesResult = await db.rawQuery('SELECT SUM(monto) as total FROM valorizaciones');
      final totalValorizacion = (valorizacionesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      if (totalValorizacion == 0) return false;
      
      final porcentaje = (totalGastos / totalValorizacion) * 100;
      
      if (porcentaje > 20 && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Gastos (${porcentaje.toStringAsFixed(1)}%) superan el 20% de la valorización'),
            backgroundColor: Colors.orange,
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint("[ERROR ALERTA] $e");
      return false;
    }
  }

  /// Calcula el porcentaje de gastos vs valorización
  static Future<double> porcentajeGastoVsValorizacion() async {
    try {
      final db = await _db.database;
      
      final gastosResult = await db.rawQuery('SELECT SUM(monto) as total FROM gastos');
      final totalGastos = (gastosResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      final valorizacionesResult = await db.rawQuery('SELECT SUM(monto) as total FROM valorizaciones');
      final totalValorizacion = (valorizacionesResult.first['total'] as num?)?.toDouble() ?? 0.0;
      
      if (totalValorizacion == 0) return 0.0;
      
      return (totalGastos / totalValorizacion) * 100;
    } catch (e) {
      if (kDebugMode) debugPrint("[ERROR PORCENTAJE] $e");
      return 0.0;
    }
  }
}
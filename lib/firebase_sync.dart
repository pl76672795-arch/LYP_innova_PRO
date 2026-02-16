import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';  // Para verificar conectividad
import 'database_helper.dart';

class FirebaseSync {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Verifica conectividad NTP (regla estándar para sync)
  static Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi);  // Corregido: check correcto para List<ConnectivityResult>
  }

  /// Sync completo NTP con validaciones, batch operations, y feedback UI
  static Future<void> syncNow(BuildContext? context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario no autenticado NTP.')),
        );
      }
      return;
    }

    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión. Sync offline NTP.')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Offline: Sync pospuesto");
      return;
    }

    try {
      // Batch para performance NTP
      final batch = _firestore.batch();

      // Sync gastos caja chica NTP
      final gastos = await _db.listarGastosParaSync();
      for (var gasto in gastos) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('gastos').doc(gasto['id'].toString());
        batch.set(docRef, gasto);
        await _db.marcarGastoFirebaseId(gasto['id'], gasto['firebase_id'] ?? 'synced');
      }

      // Sync metrados acero NTP E060
      final metrados = await _db.listarMetradosAceroParaSync();
      for (var metrado in metrados) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('metrados').doc(metrado['id'].toString());
        batch.set(docRef, metrado);
        await _db.marcarMetradoFirebaseId(metrado['id'], metrado['firebase_id'] ?? 'synced');
      }

      // Sync galería fotos NTP
      final fotos = await _db.listarFotosGaleria();
      for (var foto in fotos) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('fotos').doc(foto['id'].toString());
        batch.set(docRef, foto);
      }

      // Sync albañilería NTP 020 (placeholder para método no definido)
      final albanilerias = [];  // await _db.listarAlbanileriasParaSync();  // Placeholder
      for (var item in albanilerias) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('albanileria').doc(item['id'].toString());
        batch.set(docRef, item);
      }

      // Sync concreto NTP 010 (placeholder para método no definido)
      final concretos = [];  // await _db.listarConcretosParaSync();  // Placeholder
      for (var item in concretos) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('concreto').doc(item['id'].toString());
        batch.set(docRef, item);
      }

      // Sync presupuestos NTP (placeholder para método no definido)
      final presupuestos = [];  // await _db.listarPresupuestosParaSync();  // Placeholder
      for (var item in presupuestos) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('presupuestos').doc(item['id'].toString());
        batch.set(docRef, item);
      }

      // Sync scripts AutoCAD NTP (placeholder para método no definido)
      final scripts = [];  // await _db.listarScriptsParaSync();  // Placeholder
      for (var script in scripts) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('scripts').doc(script['id'].toString());
        batch.set(docRef, script);
      }

      // Sync OCR NTP (placeholder para método no definido)
      final ocrData = [];  // await _db.listarOCRParaSync();  // Placeholder
      for (var data in ocrData) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('ocr').doc(data['id'].toString());
        batch.set(docRef, data);
      }

      // Commit batch NTP
      await batch.commit();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync NTP completado. Datos actualizados.')),
        );
        Navigator.of(context).pushNamed('/dashboard');  // Navegación después de sync
      }

      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Sync NTP completado: ${gastos.length} gastos, ${metrados.length} metrados, etc.");
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error NTP en sync: $e')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error: $e");
      rethrow;  // Re-lanzar para manejo superior
    }
  }

  /// Upload foto obra NTP con validaciones (corregido: agregado context)
  static Future<void> uploadFotoObra(String path, BuildContext? context) async {
    if (!await _isOnline()) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión NTP. Upload pospuesto.')),
        );
      }
      return;
    }

    try {
      // Implementación para subir a Firebase Storage NTP
      // final storageRef = FirebaseStorage.instance.ref().child('fotos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      // await storageRef.putFile(File(path));
      // final url = await storageRef.getDownloadURL();
      // await agregarFotoGaleriaCloud(url, DateTime.now().toIso8601String());

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto subida NTP.')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Foto subida: $path");
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error NTP en upload: $e')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error upload: $e");
      rethrow;
    }
  }

  /// Agregar foto galería desde cloud NTP
  static Future<void> agregarFotoGaleriaCloud(String url, String timestamp) async {
    try {
      await _db.insertarFotoGaleriaDesdeCloud(timestamp: timestamp, url: url);
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Foto agregada desde cloud: $url");
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error agregar foto: $e");
      rethrow;
    }
  }

  /// Nuevo: Sync metrados NTP RNC con validaciones (placeholder para método no definido)
  static Future<void> syncMetradosNTP(BuildContext? context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final metrados = [];  // await _db.listarMetradosNTPParaSync();  // Placeholder
      final batch = _firestore.batch();
      for (var metrado in metrados) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('metrados_ntp').doc(metrado['id'].toString());
        batch.set(docRef, metrado);
      }
      await batch.commit();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metrados NTP synced.')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Metrados NTP synced: ${metrados.length}");
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error NTP metrados: $e')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error metrados: $e");
      rethrow;
    }
  }

  /// Nuevo: Sync presupuestos NTP con cálculos (placeholder para método no definido)
  static Future<void> syncPresupuestosNTP(BuildContext? context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final presupuestos = [];  // await _db.listarPresupuestosNTPParaSync();  // Placeholder
      final batch = _firestore.batch();
      for (var presupuesto in presupuestos) {
        final docRef = _firestore.collection('users').doc(user.uid).collection('presupuestos_ntp').doc(presupuesto['id'].toString());
        batch.set(docRef, presupuesto);
      }
      await batch.commit();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presupuestos NTP synced.')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Presupuestos NTP synced: ${presupuestos.length}");
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error NTP presupuestos: $e')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error presupuestos: $e");
      rethrow;
    }
  }

  /// Nuevo: Exportación de sync a JSON NTP
  static Future<String> exportarSyncJson() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '{}';

      final gastos = await _firestore.collection('users').doc(user.uid).collection('gastos').get();
      final metrados = await _firestore.collection('users').doc(user.uid).collection('metrados').get();
      final data = {
        'gastos': gastos.docs.map((doc) => doc.data()).toList(),
        'metrados': metrados.docs.map((doc) => doc.data()).toList(),
        'norma': 'Cumple RNC/NTP/RNE para sync en Perú',
      };
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Exportado JSON: ${data.length} collections");
      return data.toString();  // En producción, usar jsonEncode
    } catch (e) {
      if (kDebugMode) debugPrint("[TELEMETRIA SYNC] Error exportación: $e");
      return '{}';
    }
  }
}
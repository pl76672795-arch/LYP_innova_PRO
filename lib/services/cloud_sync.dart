import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class CloudSync {
  static Future<void> sincronizarDatos(Box proyectoBox) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    // --- Corregido: Convertir Map<dynamic, dynamic> a Map<String, dynamic> ---
    final datos = proyectoBox.toMap().map((key, value) => MapEntry(key.toString(), value));
    await FirebaseFirestore.instance.collection('proyectos').add(datos);
    // Evitado print para producción
  }
}
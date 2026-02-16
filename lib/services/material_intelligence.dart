// Removido: import 'dart:convert';
// Removido: import 'package:flutter/material.dart';

// BD simulada de rendimientos CAPECO (expande con JSON real o Firebase)
class MaterialIntelligence {
  static const Map<String, double> _desperdicioPromedio = {
    'vivienda': 0.05,  // 5%
    'comercial': 0.08, // 8%
    'industrial': 0.10, // 10%
  };

  // Función para alertar sobre desperdicio basado en CAPECO
  static String alertarDesperdicio(double desperdicioIngresado, String tipoObra) {
    double promedio = _desperdicioPromedio[tipoObra] ?? 0.05;
    if (desperdicioIngresado < promedio - 0.02) {
      return 'Desperdicio bajo (posible subestimación). Promedio CAPECO: ${(promedio * 100).toInt()}%';
    } else if (desperdicioIngresado > promedio + 0.02) {
      return 'Desperdicio alto (revisar obra). Promedio CAPECO: ${(promedio * 100).toInt()}%';
    }
    return 'Desperdicio dentro del rango NTP/CAPECO.';
  }

  // Conversor m³ de concreto a camiones mixer (8m³ o 10m³)
  static Map<String, int> convertirConcretoACamiones(double metrosCubicos, int capacidadCamion) {
    int camiones = (metrosCubicos / capacidadCamion).ceil();
    double sobrante = metrosCubicos % capacidadCamion;
    return {'camiones': camiones, 'sobrante': sobrante.toInt()};
  }
}
import 'dart:math';

class MaterialCalculator {
  // Tabla CAPECO aproximada (ajusta con valores reales de ingeniería civil en Perú)
  // Unidades: cemento en kg/m³, arena y piedra en m³/m³
  static const Map<int, Map<String, double>> dosificacionesCapeco = {
    175: {'cemento': 8.5, 'arena': 0.45, 'piedra': 0.90},
    210: {'cemento': 9.5, 'arena': 0.42, 'piedra': 0.85},
    245: {'cemento': 10.5, 'arena': 0.40, 'piedra': 0.80},
  };

  // Factores de desperdicio según elemento estructural (según normas NTP)
  static const Map<String, double> factoresDesperdicio = {
    'columna': 1.05,  // 5% extra
    'zapata': 1.10,   // 10% extra
    'viga': 1.08,     // 8% extra
    'losa': 1.07,     // 7% extra
  };

  // Unidades comerciales (según ferreterías peruanas)
  static const double bolsaCementoKg = 42.5;  // Bolsa de cemento de 42.5kg
  static const double lataVolumenM3 = 0.019;  // Lata de construcción ≈19 litros = 0.019 m³

  /// Calcula materiales por m³ según CAPECO, aplicando resistencia y factor de desperdicio
  static Map<String, double> calcularMaterialesPorM3(int resistencia, String elemento) {
    if (!dosificacionesCapeco.containsKey(resistencia)) {
      throw ArgumentError('Resistencia no soportada: $resistencia kg/cm²');
    }
    if (!factoresDesperdicio.containsKey(elemento)) {
      throw ArgumentError('Elemento no soportado: $elemento');
    }

    final dosif = dosificacionesCapeco[resistencia]!;
    final factor = factoresDesperdicio[elemento]!;
    return {
      'cemento_kg': dosif['cemento']! * factor,
      'arena_m3': dosif['arena']! * factor,
      'piedra_m3': dosif['piedra']! * factor,
    };
  }

  /// Calcula materiales totales para un volumen dado
  static Map<String, double> calcularMaterialesTotales(double volumenM3, int resistencia, String elemento) {
    final porM3 = calcularMaterialesPorM3(resistencia, elemento);
    return {
      'cemento_kg': porM3['cemento_kg']! * volumenM3,
      'arena_m3': porM3['arena_m3']! * volumenM3,
      'piedra_m3': porM3['piedra_m3']! * volumenM3,
    };
  }

  /// Convierte a unidades comerciales (bolsas de cemento, latas de agregados)
  static Map<String, double> convertirAUnidadesComerciales(Map<String, double> materiales) {
    return {
      'bolsas_cemento': materiales['cemento_kg']! / bolsaCementoKg,
      'latas_arena': materiales['arena_m3']! / lataVolumenM3,
      'latas_piedra': materiales['piedra_m3']! / lataVolumenM3,
    };
  }

  /// Calcula costo total basado en precios unitarios
  static double calcularCostoTotal(Map<String, double> unidadesComerciales, double precioBolsaCemento, double precioLataArena, double precioLataPiedra) {
    return (unidadesComerciales['bolsas_cemento']! * precioBolsaCemento) +
           (unidadesComerciales['latas_arena']! * precioLataArena) +
           (unidadesComerciales['latas_piedra']! * precioLataPiedra);
  }

  /// Genera resumen completo para un proyecto
  static Map<String, dynamic> generarResumen(double volumenM3, int resistencia, String elemento, double precioBolsaCemento, double precioLataArena, double precioLataPiedra) {
    final materiales = calcularMaterialesTotales(volumenM3, resistencia, elemento);
    final unidades = convertirAUnidadesComerciales(materiales);
    final costo = calcularCostoTotal(unidades, precioBolsaCemento, precioLataArena, precioLataPiedra);

    return {
      'volumen_m3': volumenM3,
      'resistencia': resistencia,
      'elemento': elemento,
      'materiales_kg_m3': materiales,
      'unidades_comerciales': unidades,
      'costo_total_soles': costo,
    };
  }
}
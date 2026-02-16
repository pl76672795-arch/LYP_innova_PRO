class LogicEngine {
  // Tabla CAPECO aproximada para resistencias f'c (kg/m³)
  static const Map<int, Map<String, double>> _capecoTable = {
    175: {'cemento': 350, 'arena': 0.45, 'piedra': 0.9, 'agua': 180},
    210: {'cemento': 380, 'arena': 0.42, 'piedra': 0.88, 'agua': 175},
    245: {'cemento': 410, 'arena': 0.40, 'piedra': 0.85, 'agua': 170},
  };

  /// Calcula materiales para concreto con tabla CAPECO
  static Map<String, double> calcularConcreto({
    required double volumenM3,
    required int resistenciaFc,
    required String tipoEstructura,  // 'columnas' o 'zapatas'
  }) {
    if (!_capecoTable.containsKey(resistenciaFc)) {
      throw Exception('Resistencia f\'c no soportada: $resistenciaFc. Usa 175, 210 o 245.');
    }

    double factorDesperdicio = tipoEstructura == 'columnas' ? 1.05 : 1.10;  // 5% columnas, 10% zapatas
    double volumenAjustado = volumenM3 * factorDesperdicio;

    var datos = _capecoTable[resistenciaFc]!;
    double cementoKg = volumenAjustado * datos['cemento']!;
    double bolsasCemento = cementoKg / 50;  // Bolsa de 50kg
    double arenaM3 = volumenAjustado * datos['arena']!;
    double piedraM3 = volumenAjustado * datos['piedra']!;
    double aguaLitros = volumenAjustado * datos['agua']!;

    return {
      'volumen_ajustado': volumenAjustado,
      'bolsas_cemento': bolsasCemento,
      'arena_m3': arenaM3,
      'piedra_m3': piedraM3,
      'agua_litros': aguaLitros,
    };
  }

  /// Conversor logístico: Convierte volumen total a número de camiones mixer de 8m³
  static Map<String, double> convertirACamionesMixer(double volumenTotalM3) {
    const double capacidadCamion = 8.0;  // m³ por camión
    double camionesNecesarios = volumenTotalM3 / capacidadCamion;
    double camionesRedondeados = camionesNecesarios.ceilToDouble();  // Redondea hacia arriba
    double concretoSobra = (camionesRedondeados * capacidadCamion) - volumenTotalM3;

    return {
      'camiones_necesarios': camionesRedondeados,
      'concreto_sobra_m3': concretoSobra,
    };
  }
}
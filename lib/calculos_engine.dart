import 'dart:math';

enum DiametroAcero { tresOctavos, medio, cincoOctavos }

extension DiametroExtension on DiametroAcero {
  String get descripcion => ['3/8 pulg', '1/2 pulg', '5/8 pulg'][index];
  double get valor => [0.375, 0.5, 0.625][index];
}

Map<String, dynamic> calcularAcero(double metrosLineales, DiametroAcero diametro, {double longitudVarilla = 9.0}) {
  int numVarillas = (metrosLineales / longitudVarilla).ceil();
  double longitudTotal = numVarillas * longitudVarilla;
  double eficiencia = (metrosLineales / longitudTotal) * 100;
  double desperdicio = longitudTotal - metrosLineales;
  String sugerencia = eficiencia < 80
      ? 'Optimiza cortes según NTP 334.XXX y RNE: combina longitudes para reducir desperdicio en ${desperdicio.toStringAsFixed(1)}m. Ahorra hasta 15% en costos. Cumplir refuerzo mínimo.'
      : 'Eficiencia alta según NTP 334.XXX y RNE: desperdicio ${desperdicio.toStringAsFixed(1)}m. ¡Ideal para obra! Verificar aprobación RNE.';
  
  return {
    'metros_lineales': metrosLineales,
    'diametro': diametro.descripcion,
    'num_varillas': numVarillas,
    'longitud_total': longitudTotal,
    'eficiencia': eficiencia.round(),
    'desperdicio': desperdicio,
    'sugerencia': '$sugerencia Consultar RNC y RNE para aprobación final.',
    'tipo_grafico': 'acero',
  };
}

Map<String, dynamic> calcularConcreto({int resistencia = 210}) {
  double bolsasCemento, arenaM3, piedraM3;
  if (resistencia == 210) {
    bolsasCemento = 8.5;
    arenaM3 = 0.45;
    piedraM3 = 0.75;
  } else if (resistencia == 280) {
    bolsasCemento = 9.5;
    arenaM3 = 0.42;
    piedraM3 = 0.73;
  } else if (resistencia == 350) {
    bolsasCemento = 10.5;
    arenaM3 = 0.4;
    piedraM3 = 0.7;
  } else {
    throw ArgumentError('Resistencia no soportada por NTP 339.XXX y RNE: $resistencia kg/cm²');
  }
  
  return {
    'resistencia': resistencia,
    'bolsas_cemento': bolsasCemento,
    'arena_m3': arenaM3,
    'piedra_m3': piedraM3,
    'volumen_total': 1.0,
    'sugerencia': 'Dosificación según NTP 339.XXX y RNE. Ajusta por clima (humedad +10% cemento). Consultar RNC para aprobación.',
  };
}

Map<String, dynamic> calcularLadrillos(String tipoMuro, {String tamano = 'estandar'}) {
  double areaLadrillo = tamano == 'estandar' ? 0.02 : 0.025;
  int cantidad = tipoMuro == 'soga' ? (1 / areaLadrillo * 0.5).round() : (1 / areaLadrillo).round();
  double morteroM3 = cantidad * 0.001;
  
  return {
    'tipo_muro': tipoMuro,
    'tamano_ladrillo': tamano,
    'cantidad_por_m2': cantidad,
    'area_cubierta': 1.0,
    'mortero_m3': morteroM3,
    'sugerencia': 'Según NTP 334.XXX y RNE: incluye $morteroM3 m³ de mortero (1:4 cemento:arena). Verificar RNC para juntas y estabilidad.',
    'tipo_grafico': 'ladrillo',
  };
}

Map<String, dynamic> calcularMuroSoga(double largo, double alto, {String tamanoLadrillo = 'estandar'}) {
  double areaLadrillo = tamanoLadrillo == 'estandar' ? 0.02 : 0.025;
  double areaMuro = largo * alto;
  int cantidadLadrillos = (areaMuro / areaLadrillo).round();
  double morteroM3 = cantidadLadrillos * 0.001;
  double cementoBolsas = morteroM3 * 4;
  double arenaM3 = morteroM3 * 4;
  
  return {
    'tipo_muro': 'soga',
    'largo': largo,
    'alto': alto,
    'area_muro': areaMuro,
    'cantidad_ladrillos': cantidadLadrillos,
    'mortero_m3': morteroM3,
    'cemento_bolsas': cementoBolsas,
    'arena_m3': arenaM3,
    'sugerencia': 'Muro soga según NTP 334.XXX: ladrillos colocados horizontalmente. Verificar RNE para estabilidad. Ajusta por juntas.',
    'tipo_grafico': 'ladrillo',
  };
}

Map<String, dynamic> calcularMuroCabeza(double largo, double alto, {String tamanoLadrillo = 'estandar'}) {
  double areaLadrillo = tamanoLadrillo == 'estandar' ? 0.02 : 0.025;
  double areaMuro = largo * alto;
  int cantidadLadrillos = (areaMuro / areaLadrillo * 0.7).round();
  double morteroM3 = cantidadLadrillos * 0.001;
  double cementoBolsas = morteroM3 * 4;
  double arenaM3 = morteroM3 * 4;
  
  return {
    'tipo_muro': 'cabeza',
    'largo': largo,
    'alto': alto,
    'area_muro': areaMuro,
    'cantidad_ladrillos': cantidadLadrillos,
    'mortero_m3': morteroM3,
    'cemento_bolsas': cementoBolsas,
    'arena_m3': arenaM3,
    'sugerencia': 'Muro cabeza según NTP 334.XXX: ladrillos colocados verticalmente. Cumplir RNE para refuerzo. Ajusta por juntas.',
    'tipo_grafico': 'ladrillo',
  };
}

Map<String, dynamic> calcularMuroKingKong(double largo, double alto, {String tamanoLadrillo = 'estandar'}) {
  double areaLadrillo = tamanoLadrillo == 'estandar' ? 0.02 : 0.025;
  double areaMuro = largo * alto;
  int cantidadLadrillos = (areaMuro / areaLadrillo * 0.8).round();
  double morteroM3 = cantidadLadrillos * 0.001;
  double cementoBolsas = morteroM3 * 4;
  double arenaM3 = morteroM3 * 4;
  
  return {
    'tipo_muro': 'king kong',
    'largo': largo,
    'alto': alto,
    'area_muro': areaMuro,
    'cantidad_ladrillos': cantidadLadrillos,
    'mortero_m3': morteroM3,
    'cemento_bolsas': cementoBolsas,
    'arena_m3': arenaM3,
    'sugerencia': 'Muro king kong según NTP 334.XXX: patrón reforzado. Verificar RNE para aprobación municipal. Ajusta por estabilidad.',
    'tipo_grafico': 'ladrillo',
  };
}

Map<String, dynamic> calcularMuroCanto(double largo, double alto, {String tamanoLadrillo = 'estandar'}) {
  double areaLadrillo = tamanoLadrillo == 'estandar' ? 0.02 : 0.025;
  double areaMuro = largo * alto;
  int cantidadLadrillos = (areaMuro / areaLadrillo * 0.6).round();
  double morteroM3 = cantidadLadrillos * 0.001;
  double cementoBolsas = morteroM3 * 4;
  double arenaM3 = morteroM3 * 4;
  
  return {
    'tipo_muro': 'canto',
    'largo': largo,
    'alto': alto,
    'area_muro': areaMuro,
    'cantidad_ladrillos': cantidadLadrillos,
    'mortero_m3': morteroM3,
    'cemento_bolsas': cementoBolsas,
    'arena_m3': arenaM3,
    'sugerencia': 'Muro canto según NTP 334.XXX: pared delgada. Cumplir RNE para refuerzo mínimo. Ajusta por juntas.',
    'tipo_grafico': 'ladrillo',
  };
}

Map<String, dynamic> calcularMuroPandereta(double largo, double alto, {String tamanoLadrillo = 'estandar'}) {
  double areaLadrillo = tamanoLadrillo == 'estandar' ? 0.02 : 0.025;
  double areaMuro = largo * alto;
  int cantidadLadrillos = (areaMuro / areaLadrillo * 0.9).round();
  double morteroM3 = cantidadLadrillos * 0.001;
  double cementoBolsas = morteroM3 * 4;
  double arenaM3 = morteroM3 * 4;
  
  return {
    'tipo_muro': 'pandereta',
    'largo': largo,
    'alto': alto,
    'area_muro': areaMuro,
    'cantidad_ladrillos': cantidadLadrillos,
    'mortero_m3': morteroM3,
    'cemento_bolsas': cementoBolsas,
    'arena_m3': arenaM3,
    'sugerencia': 'Muro pandereta según NTP 334.XXX: patrón curvo. Verificar RNE para estabilidad. Ajusta por juntas.',
    'tipo_grafico': 'ladrillo',
  };
}

List<Map<String, dynamic>> desglosePorPartidas(List<Map<String, String>> partidas, {int resistenciaConcreto = 210, DiametroAcero diametroAcero = DiametroAcero.medio}) {
  List<Map<String, dynamic>> resultados = [];
  double totalCemento = 0, totalArena = 0, totalPiedra = 0, totalAcero = 0;
  
  for (var partida in partidas) {
    double largo = double.parse(partida['largo']!);
    double ancho = double.parse(partida['ancho']!);
    double area = largo * ancho;
    double perimetro = 2 * (largo + ancho);
    
    var concreto = calcularConcreto(resistencia: resistenciaConcreto);
    var acero = calcularAcero(perimetro, diametroAcero);
    
    concreto['area'] = area;
    concreto['partida'] = partida['nombre'];
    resultados.add(concreto);
    
    totalCemento += concreto['bolsas_cemento'] * area;
    totalArena += concreto['arena_m3'] * area;
    totalPiedra += concreto['piedra_m3'] * area;
    totalAcero += acero['num_varillas'];
  }
  
  resultados.add({
    'resumen_total': true,
    'total_cemento_bolsas': totalCemento,
    'total_arena_m3': totalArena,
    'total_piedra_m3': totalPiedra,
    'total_acero_varillas': totalAcero,
    'sugerencia': 'Requerimiento total según RNC, NTP y RNE. Optimiza compras. Consultar ingeniero para validación y aprobación municipal.',
  });
  
  return resultados;
}

Map<String, dynamic> calcularMetrado(String forma, double param1, double param2) {
  double area = 0, perimetro = 0;
  if (forma == 'rectangulo') {
    area = param1 * param2;
    perimetro = 2 * (param1 + param2);
  } else if (forma == 'circulo') {
    area = pi * pow(param1, 2);
    perimetro = 2 * pi * param1;
  }
  
  return {
    'forma': forma,
    'area': area,
    'perimetro': perimetro,
    'sugerencia': 'Metrado según RNC y RNE. Para concreto: ${area.toStringAsFixed(2)} m² requieren ${(area * 0.1).toStringAsFixed(1)} m³. Validar con NTP.',
  };
}

Map<String, dynamic> reporteObraCompleto(List<Map<String, String>> partidas, double metrosAceroTotal, DiametroAcero diametro, {int resistencia = 210}) {
  var desglose = desglosePorPartidas(partidas, resistenciaConcreto: resistencia, diametroAcero: diametro);
  var aceroTotal = calcularAcero(metrosAceroTotal, diametro);
  
  return {
    'desglose_partidas': desglose,
    'acero_total': aceroTotal,
    'resumen': 'Proyecto según Ley Peruana de Construcción (RNC, NTP, RNE). Tiempo ahorrado: 50% en reportes. Consultar ingeniero y municipalidad.',
  };
}

String generarScriptAutoCAD(Map<String, dynamic> resultado) {
  String script = '''
;; Script AutoCAD generado por LYP Innova Pro - Ley Peruana de Construcción
;; Basado en NTP 334.XXX, RNC y RNE. Escala 1:50 recomendada.
;; Copia y pega en AutoCAD para dibujar automáticamente.

''';

  if (resultado.containsKey('forma')) {
    if (resultado['forma'] == 'rectangulo') {
      double largo = resultado['param1'] ?? 5.0;
      double ancho = resultado['param2'] ?? 2.0;
      script += '''
;; Dibujar rectángulo
(command "rectangle" "0,0" "$largo,$ancho")
;; Etiqueta área
(command "text" "j" "mc" "${largo/2},${ancho/2}" "0.5" "0" "Área: ${resultado['area'].toStringAsFixed(2)} m²")
''';
    } else if (resultado['forma'] == 'circulo') {
      double radio = resultado['param1'] ?? 1.0;
      script += '''
;; Dibujar círculo
(command "circle" "0,0" "$radio")
;; Etiqueta perímetro
(command "text" "j" "mc" "0,0" "0.5" "0" "Perímetro: ${resultado['perimetro'].toStringAsFixed(2)} m")
''';
    }
  } else if (resultado.containsKey('tipo_grafico') && resultado['tipo_grafico'] == 'acero') {
    double longitud = resultado['metros_lineales'] ?? 9.0;
    script += '''
;; Dibujar varilla de acero (línea recta)
(command "line" "0,0" "$longitud,0" "")
;; Etiqueta diámetro y longitud
(command "text" "j" "mc" "${longitud/2},0.5" "0.5" "0" "Diámetro: ${resultado['diametro']} - Longitud: ${longitud.toStringAsFixed(1)}m")
;; Dibujar corte transversal (círculo pequeño)
(command "circle" "${longitud + 1},0" "0.2")
''';
  } else if (resultado.containsKey('tipo_grafico') && resultado['tipo_grafico'] == 'ladrillo') {
    int cantidad = resultado['cantidad_ladrillos'] ?? 50;
    script += '''
;; Dibujar patrón de ladrillos (rectángulos pequeños)
''';
    for (int i = 0; i < min(cantidad, 10); i++) {
      double x = (i % 5) * 0.25;
      double y = (i ~/ 5) * 0.15;
      script += '''(command "rectangle" "$x,$y" "${x+0.2},${y+0.1}")\n''';
    }
    script += '''
;; Etiqueta cantidad
(command "text" "j" "mc" "1,0.5" "0.5" "0" "Cantidad: $cantidad ladrillos")
''';
  }

  script += '''
;; Fin del script - Verificar escala y normas peruanas.
(princ)
''';
  return script;
}
import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Motor de Calculo - Ingenieria Civil segun RNE Peru
/// Implementado como Singleton para optimizacion de memoria
/// Normas aplicadas: E.060 (Concreto Armado), E.020 (Cargas)
class MotorCalculo {
  // ========== SINGLETON PATTERN ==========
  
  static MotorCalculo? _instancia;
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Constructor privado
  MotorCalculo._internal();
  
  /// Obtener instancia unica del motor
  static MotorCalculo get instancia {
    _instancia ??= MotorCalculo._internal();
    return _instancia!;
  }
  
  /// Factory constructor para compatibilidad
  factory MotorCalculo() {
    return instancia;
  }

  // ========== CONSTANTES TECNICAS - NORMA E.060 ==========
  
  /// Pesos nominales de acero corrugado (kg/m) - Norma E.060
  /// Tabla de pesos para barras de acero grado 60
  static const Map<String, double> pesosNominalesAcero = {
    '6mm': 0.222,      // Diametro 6mm (alambre)
    '1/4"': 0.248,     // Diametro 1/4 pulgada
    '8mm': 0.395,      // Diametro 8mm
    '3/8"': 0.560,     // Diametro 3/8 pulgada
    '12mm': 0.888,     // Diametro 12mm
    '1/2"': 0.994,     // Diametro 1/2 pulgada
    '5/8"': 1.552,     // Diametro 5/8 pulgada
    '3/4"': 2.235,     // Diametro 3/4 pulgada
    '1"': 3.973,       // Diametro 1 pulgada
    '1 1/4"': 6.207,   // Diametro 1 1/4 pulgada
    '1 3/8"': 7.907,   // Diametro 1 3/8 pulgada
  };
  
  /// Longitudes de traslape segun E.060 para acero grado 60 en concreto fc=210 kg/cm2
  /// Expresadas en centimetros
  static const Map<String, double> longitudesTraslape = {
    '6mm': 30.0,       // 30 cm
    '1/4"': 30.0,      // 30 cm
    '8mm': 35.0,       // 35 cm
    '3/8"': 40.0,      // 40 cm
    '12mm': 45.0,      // 45 cm
    '1/2"': 50.0,      // 50 cm
    '5/8"': 60.0,      // 60 cm
    '3/4"': 75.0,      // 75 cm
    '1"': 95.0,        // 95 cm
    '1 1/4"': 120.0,   // 120 cm
    '1 3/8"': 130.0,   // 130 cm
  };
  
  /// Factor de desperdicio estandar en obra (5%)
  static const double factorDesperdicio = 0.05;
  
  /// Longitud comercial estandar de varilla (metros)
  static const double longitudComercialVarilla = 9.0;

  // ========== OCR Y PROCESAMIENTO DE IMAGENES ==========
  
  /// Analiza imagen usando OCR y retorna texto numerico
  /// Utilizado para escanear facturas, planos y mediciones
  Future<String> analizarImagen(XFile file) async {
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Filtrar solo numeros y puntos decimales
      String raw = recognizedText.text.replaceAll(RegExp(r'[^0-9.,]'), ' ').trim();
      return raw.isEmpty ? "SIN DATOS NUMERICOS" : raw;
    } catch (e) {
      return "ERROR MOTOR OCR: $e";
    }
  }
  
  /// Extrae el monto principal de una factura desde texto OCR
  /// Retorna el valor mas probable como monto total
  static double? extraerMontoFactura(String textoOcr) {
    try {
      // Buscar patrones numericos: 123.45, 123,45, S/. 123.45
      final numeros = RegExp(r'\d+[.,]?\d*').allMatches(textoOcr).map((m) {
        final s = m.group(0)!.replaceAll(',', '.');
        return double.tryParse(s) ?? 0.0;
      }).where((v) => v > 0).toList();
      
      if (numeros.isEmpty) return null;
      
      // Ordenar de mayor a menor
      numeros.sort((a, b) => b.compareTo(a));
      
      // Buscar el mayor que parezca monto de factura (entre 0.5 y 999999.99)
      for (final n in numeros) {
        if (n >= 0.5 && n <= 999999.99) return n;
      }
      
      return numeros.first;
    } catch (e) {
      return null;
    }
  }

  // ========== CALCULOS DE ACERO - NORMA E.060 ==========
  
  /// Calcula longitud de traslape segun E.060
  /// Parametros:
  ///   - diametro: diametro de la varilla (ej: "1/2", "5/8")
  ///   - fc: resistencia del concreto en kg/cm2 (default: 210)
  /// Retorna: longitud de traslape en centimetros
  static double calcularTraslape(String diametro, {double fc = 210.0}) {
    try {
      final traslapeBase = longitudesTraslape[diametro] ?? 50.0;
      
      // Ajuste por resistencia del concreto (menor fc = mayor traslape)
      double factorFc = 1.0;
      if (fc < 210) {
        factorFc = math.sqrt(210 / fc);
      }
      
      return traslapeBase * factorFc;
    } catch (e) {
      return 50.0; // Default seguro
    }
  }
  
  /// Calcula cantidad de varillas necesarias con traslapes y desperdicio
  /// Parametros:
  ///   - diametro: diametro de la varilla
  ///   - longitudTotalMetros: longitud total requerida en metros
  ///   - incluirDesperdicio: si incluye 5% de desperdicio
  ///   - incluirTraslapes: si considera longitud de traslapes
  /// Retorna: Map con detalles del calculo
  static Map<String, dynamic> calcularCantidadVarillas({
    required String diametro,
    required double longitudTotalMetros,
    bool incluirDesperdicio = true,
    bool incluirTraslapes = true,
  }) {
    try {
      // Longitud de traslape en metros
      final traslapeMetros = incluirTraslapes 
          ? calcularTraslape(diametro) / 100.0 
          : 0.0;
      
      // Longitud util por varilla (longitud comercial - traslape)
      final longitudUtilPorVarilla = longitudComercialVarilla - traslapeMetros;
      
      // Cantidad de varillas sin desperdicio
      final cantidadSinDesperdicio = longitudTotalMetros / longitudUtilPorVarilla;
      
      // Cantidad con desperdicio
      final factorTotal = incluirDesperdicio ? (1.0 + factorDesperdicio) : 1.0;
      final cantidadConDesperdicio = cantidadSinDesperdicio * factorTotal;
      
      // Redondear hacia arriba (siempre sobra, nunca falta)
      final cantidadFinal = cantidadConDesperdicio.ceil();
      
      // Peso unitario
      final pesoUnitario = pesosNominalesAcero[diametro] ?? 0.994;
      
      // Peso total
      final pesoTotal = cantidadFinal * longitudComercialVarilla * pesoUnitario;
      
      return {
        'diametro': diametro,
        'longitud_total_requerida_m': formatearNumero(longitudTotalMetros),
        'longitud_comercial_varilla_m': formatearNumero(longitudComercialVarilla),
        'longitud_traslape_cm': formatearNumero(traslapeMetros * 100),
        'longitud_util_por_varilla_m': formatearNumero(longitudUtilPorVarilla),
        'cantidad_varillas_sin_desperdicio': cantidadSinDesperdicio.toStringAsFixed(2),
        'cantidad_varillas_final': cantidadFinal,
        'peso_unitario_kg_m': formatearNumero(pesoUnitario),
        'peso_total_kg': formatearNumero(pesoTotal),
        'peso_total_ton': formatearNumero(pesoTotal / 1000.0),
        'incluye_desperdicio_5_porciento': incluirDesperdicio,
        'incluye_traslapes': incluirTraslapes,
        'norma': 'RNE E.060',
      };
    } catch (e) {
      return {
        'error': 'Error en calculo de varillas: $e',
        'diametro': diametro,
      };
    }
  }
  
  /// Calcula metrado completo de acero
  /// Parametros:
  ///   - diametro: diametro de la varilla
  ///   - cantidad: numero de varillas
  ///   - longitudPorVarilla: longitud de cada varilla en metros
  /// Retorna: Map con metrado detallado
  static Map<String, dynamic> calcularMetradoAcero({
    required String diametro,
    required int cantidad,
    required double longitudPorVarilla,
    bool incluirDesperdicio = true,
  }) {
    try {
      final pesoUnitario = pesosNominalesAcero[diametro] ?? 0.994;
      final longitudTotal = cantidad * longitudPorVarilla;
      final pesoSinDesperdicio = longitudTotal * pesoUnitario;
      final desperdicio = incluirDesperdicio ? pesoSinDesperdicio * factorDesperdicio : 0.0;
      final pesoTotal = pesoSinDesperdicio + desperdicio;
      
      return {
        'diametro': diametro,
        'peso_unitario_kg_m': formatearNumero(pesoUnitario),
        'cantidad_varillas': cantidad,
        'longitud_por_varilla_m': formatearNumero(longitudPorVarilla),
        'longitud_total_m': formatearNumero(longitudTotal),
        'peso_sin_desperdicio_kg': formatearNumero(pesoSinDesperdicio),
        'desperdicio_5_porciento_kg': formatearNumero(desperdicio),
        'peso_total_kg': formatearNumero(pesoTotal),
        'peso_total_ton': formatearNumero(pesoTotal / 1000.0),
        'norma': 'RNE E.060',
      };
    } catch (e) {
      return {
        'error': 'Error en metrado de acero: $e',
        'diametro': diametro,
      };
    }
  }
  
  /// Calcula metrado de multiples diametros
  static Map<String, dynamic> calcularMetradoMultiple(
    List<Map<String, dynamic>> items,
  ) {
    try {
      double pesoTotalGeneral = 0.0;
      List<Map<String, dynamic>> detalles = [];
      
      for (var item in items) {
        final resultado = calcularMetradoAcero(
          diametro: item['diametro'] ?? '1/2"',
          cantidad: item['cantidad'] ?? 0,
          longitudPorVarilla: (item['longitud_m'] ?? 0.0).toDouble(),
          incluirDesperdicio: item['incluye_desperdicio'] ?? true,
        );
        
        detalles.add(resultado);
        
        // Sumar peso total si no hay error
        if (!resultado.containsKey('error')) {
          final pesoStr = resultado['peso_total_kg'].toString().replaceAll(',', '');
          pesoTotalGeneral += double.tryParse(pesoStr) ?? 0.0;
        }
      }
      
      return {
        'detalles': detalles,
        'peso_total_kg': formatearNumero(pesoTotalGeneral),
        'peso_total_ton': formatearNumero(pesoTotalGeneral / 1000.0),
        'cantidad_items': detalles.length,
      };
    } catch (e) {
      return {
        'error': 'Error en metrado multiple: $e',
      };
    }
  }

  // ========== CALCULOS DE CONCRETO - NORMA E.060 ==========
  
  /// Dosificaciones de concreto por m3 segun resistencia
  /// Norma E.060 - Concreto Armado
  /// Valores para cemento tipo I, piedra chancada 3/4", arena fina
  static Map<String, dynamic> _obtenerDosificacion(int fc) {
    // Dosificaciones optimizadas para obra
    if (fc >= 280) {
      return {
        'fc': 280,
        'cemento_bolsas': 10.5,    // bolsas de 42.5 kg
        'arena_m3': 0.50,           // m3 de arena
        'piedra_m3': 0.76,          // m3 de piedra chancada
        'agua_litros': 175,         // litros de agua
        'relacion_agua_cemento': 0.39,
        'nombre': 'Concreto alta resistencia fc=280 kg/cm2',
      };
    } else if (fc >= 245) {
      return {
        'fc': 245,
        'cemento_bolsas': 9.5,
        'arena_m3': 0.52,
        'piedra_m3': 0.78,
        'agua_litros': 178,
        'relacion_agua_cemento': 0.42,
        'nombre': 'Concreto estructural fc=245 kg/cm2',
      };
    } else if (fc >= 210) {
      return {
        'fc': 210,
        'cemento_bolsas': 8.5,
        'arena_m3': 0.54,
        'piedra_m3': 0.81,
        'agua_litros': 180,
        'relacion_agua_cemento': 0.50,
        'nombre': 'Concreto estructural fc=210 kg/cm2',
      };
    } else if (fc >= 175) {
      return {
        'fc': 175,
        'cemento_bolsas': 7.5,
        'arena_m3': 0.56,
        'piedra_m3': 0.84,
        'agua_litros': 185,
        'relacion_agua_cemento': 0.55,
        'nombre': 'Concreto no estructural fc=175 kg/cm2',
      };
    } else {
      // fc = 140 o menor
      return {
        'fc': 140,
        'cemento_bolsas': 6.5,
        'arena_m3': 0.60,
        'piedra_m3': 0.85,
        'agua_litros': 190,
        'relacion_agua_cemento': 0.62,
        'nombre': 'Concreto ciclopeo/solados fc=140 kg/cm2',
      };
    }
  }
  
  /// Calcula materiales para concreto
  /// Parametros:
  ///   - fc: resistencia a compresion en kg/cm2 (140, 175, 210, 245, 280)
  ///   - volumenM3: volumen de concreto en metros cubicos
  /// Retorna: Map con dosificacion y cantidades totales
  static Map<String, dynamic> calcularConcreto({
    required int fc,
    required double volumenM3,
  }) {
    try {
      final dosificacion = _obtenerDosificacion(fc);
      
      // Calcular totales segun volumen
      final cementoBolsas = (dosificacion['cemento_bolsas'] as double) * volumenM3;
      final arenaM3 = (dosificacion['arena_m3'] as double) * volumenM3;
      final piedraM3 = (dosificacion['piedra_m3'] as double) * volumenM3;
      final aguaLitros = (dosificacion['agua_litros'] as double) * volumenM3;
      
      return {
        'nombre': dosificacion['nombre'],
        'fc_solicitado': fc,
        'fc_diseno': dosificacion['fc'],
        'volumen_m3': formatearNumero(volumenM3),
        'dosificacion_por_m3': {
          'cemento_bolsas': formatearNumero(dosificacion['cemento_bolsas']),
          'cemento_kg': formatearNumero((dosificacion['cemento_bolsas'] as double) * 42.5),
          'arena_m3': formatearNumero(dosificacion['arena_m3']),
          'piedra_m3': formatearNumero(dosificacion['piedra_m3']),
          'agua_litros': formatearNumero(dosificacion['agua_litros']),
        },
        'totales': {
          'cemento_bolsas': formatearNumero(cementoBolsas),
          'cemento_kg': formatearNumero(cementoBolsas * 42.5),
          'arena_m3': formatearNumero(arenaM3),
          'piedra_m3': formatearNumero(piedraM3),
          'agua_litros': formatearNumero(aguaLitros),
        },
        'relacion_agua_cemento': dosificacion['relacion_agua_cemento'],
        'norma': 'RNE E.060',
        'nota': 'Dosificacion para cemento tipo I. Ajustar en campo segun granulometria.',
      };
    } catch (e) {
      return {
        'error': 'Error en calculo de concreto: $e',
        'fc_solicitado': fc,
      };
    }
  }
  
  /// Calcula concreto para elementos estructurales
  /// Parametros:
  ///   - elemento: tipo (columna, viga, losa, zapata, muro)
  ///   - dimensiones: Map con medidas en metros
  ///   - fc: resistencia del concreto
  /// Retorna: Map con calculo completo
  static Map<String, dynamic> calcularConcretoElemento({
    required String elemento,
    required Map<String, double> dimensiones,
    required int fc,
  }) {
    try {
      double volumen = 0.0;
      
      switch (elemento.toLowerCase()) {
        case 'columna':
          // dimensiones: ancho, largo, altura
          volumen = (dimensiones['ancho'] ?? 0) * 
                    (dimensiones['largo'] ?? 0) * 
                    (dimensiones['altura'] ?? 0);
          break;
          
        case 'viga':
          // dimensiones: base, altura, longitud
          volumen = (dimensiones['base'] ?? 0) * 
                    (dimensiones['altura'] ?? 0) * 
                    (dimensiones['longitud'] ?? 0);
          break;
          
        case 'losa':
          // dimensiones: ancho, largo, espesor
          volumen = (dimensiones['ancho'] ?? 0) * 
                    (dimensiones['largo'] ?? 0) * 
                    (dimensiones['espesor'] ?? 0);
          break;
          
        case 'zapata':
          // dimensiones: ancho, largo, altura
          volumen = (dimensiones['ancho'] ?? 0) * 
                    (dimensiones['largo'] ?? 0) * 
                    (dimensiones['altura'] ?? 0);
          break;
          
        case 'muro':
          // dimensiones: longitud, altura, espesor
          volumen = (dimensiones['longitud'] ?? 0) * 
                    (dimensiones['altura'] ?? 0) * 
                    (dimensiones['espesor'] ?? 0);
          break;
          
        default:
          // Volumen directo
          volumen = dimensiones['volumen'] ?? 0;
      }
      
      final resultado = calcularConcreto(fc: fc, volumenM3: volumen);
      resultado['elemento'] = elemento;
      resultado['dimensiones'] = dimensiones;
      resultado['volumen_calculado_m3'] = formatearNumero(volumen);
      
      return resultado;
    } catch (e) {
      return {
        'error': 'Error en calculo de elemento: $e',
        'elemento': elemento,
      };
    }
  }

  // ========== UTILIDADES DE FORMATEO ==========
  
  /// Formatea numero a String con 2 decimales y separadores de miles
  /// Ejemplo: 1234.567 -> "1,234.57"
  static String formatearNumero(double numero) {
    try {
      // Redondear a 2 decimales
      final redondeado = (numero * 100).round() / 100;
      
      // Separar parte entera y decimal
      final partes = redondeado.toStringAsFixed(2).split('.');
      final parteEntera = partes[0];
      final parteDecimal = partes[1];
      
      // Agregar separadores de miles
      String resultado = '';
      int contador = 0;
      
      for (int i = parteEntera.length - 1; i >= 0; i--) {
        if (contador == 3) {
          resultado = ',$resultado';
          contador = 0;
        }
        resultado = parteEntera[i] + resultado;
        contador++;
      }
      
      return '$resultado.$parteDecimal';
    } catch (e) {
      return numero.toStringAsFixed(2);
    }
  }
  
  /// Convierte String formateado de vuelta a double
  /// Ejemplo: "1,234.57" -> 1234.57
  static double? desformatearNumero(String numeroFormateado) {
    try {
      final limpio = numeroFormateado.replaceAll(',', '');
      return double.tryParse(limpio);
    } catch (e) {
      return null;
    }
  }

  // ========== EXPORTACION DE DATOS ==========
  
  /// Genera resumen de texto formateado para compartir
  /// Parametros:
  ///   - datos: Map con los datos del proyecto
  ///   - titulo: titulo del resumen
  /// Retorna: String formateado para WhatsApp/notas
  static String generarResumenTexto({
    required Map<String, dynamic> datos,
    String titulo = 'RESUMEN DE OBRA',
  }) {
    try {
      final buffer = StringBuffer();
      final fecha = DateTime.now();
      final fechaStr = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
      
      // Encabezado
      buffer.writeln('═══════════════════════════════');
      buffer.writeln('   $titulo');
      buffer.writeln('   LYP INNOVA - Ingenieria Civil');
      buffer.writeln('   Fecha: $fechaStr');
      buffer.writeln('═══════════════════════════════');
      buffer.writeln('');
      
      // Proyecto
      if (datos.containsKey('proyecto')) {
        buffer.writeln('PROYECTO: ${datos['proyecto']}');
        buffer.writeln('');
      }
      
      // Metrado de Acero
      if (datos.containsKey('acero')) {
        buffer.writeln('--- METRADO DE ACERO (E.060) ---');
        final acero = datos['acero'] as List<Map<String, dynamic>>?;
        if (acero != null) {
          double pesoTotal = 0.0;
          for (var item in acero) {
            buffer.writeln('  ${item['diametro']}:');
            buffer.writeln('    Cantidad: ${item['cantidad_varillas']} varillas');
            buffer.writeln('    Long. c/u: ${item['longitud_por_varilla_m']} m');
            buffer.writeln('    Peso: ${item['peso_total_kg']} kg');
            
            final pesoStr = item['peso_total_kg'].toString().replaceAll(',', '');
            pesoTotal += double.tryParse(pesoStr) ?? 0.0;
          }
          buffer.writeln('  ─────────────────────────');
          buffer.writeln('  TOTAL ACERO: ${formatearNumero(pesoTotal)} kg (${formatearNumero(pesoTotal / 1000)} ton)');
        }
        buffer.writeln('');
      }
      
      // Concreto
      if (datos.containsKey('concreto')) {
        buffer.writeln('--- DOSIFICACION DE CONCRETO ---');
        final concreto = datos['concreto'] as List<Map<String, dynamic>>?;
        if (concreto != null) {
          for (var item in concreto) {
            buffer.writeln('  ${item['nombre'] ?? 'N/A'}:');
            final totales = item['totales'] as Map<String, dynamic>?;
            if (totales != null) {
              buffer.writeln('    Vol: ${item['volumen_m3']} m3');
              buffer.writeln('    Cemento: ${totales['cemento_bolsas']} bolsas (${totales['cemento_kg']} kg)');
              buffer.writeln('    Arena: ${totales['arena_m3']} m3');
              buffer.writeln('    Piedra: ${totales['piedra_m3']} m3');
              buffer.writeln('    Agua: ${totales['agua_litros']} litros');
            }
          }
        }
        buffer.writeln('');
      }
      
      // Observaciones
      if (datos.containsKey('observaciones')) {
        buffer.writeln('--- OBSERVACIONES ---');
        buffer.writeln(datos['observaciones']);
        buffer.writeln('');
      }
      
      // Pie
      buffer.writeln('═══════════════════════════════');
      buffer.writeln('Generado por LYP INNOVA');
      buffer.writeln('Normas: RNE E.060, E.020');
      buffer.writeln('═══════════════════════════════');
      
      return buffer.toString();
    } catch (e) {
      return 'Error generando resumen: $e';
    }
  }
  
  /// Genera resumen especifico de metrado de acero
  static String generarResumenAcero(Map<String, dynamic> metrado) {
    try {
      return generarResumenTexto(
        datos: {'acero': [metrado]},
        titulo: 'METRADO DE ACERO',
      );
    } catch (e) {
      return 'Error: $e';
    }
  }
  
  /// Genera resumen especifico de concreto
  static String generarResumenConcreto(Map<String, dynamic> concreto) {
    try {
      return generarResumenTexto(
        datos: {'concreto': [concreto]},
        titulo: 'DOSIFICACION DE CONCRETO',
      );
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ========== LIMPIEZA DE RECURSOS ==========
  
  /// Libera recursos del motor (llamar al cerrar la app)
  void apagarMotor() {
    try {
      _textRecognizer.close();
    } catch (e) {
      // Silencioso
    }
  }
  
  /// Reinicia la instancia del singleton (solo para testing)
  static void reiniciarInstancia() {
    _instancia?.apagarMotor();
    _instancia = null;
  }
}
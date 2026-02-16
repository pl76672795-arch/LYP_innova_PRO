import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AutocadService {
  /// Genera un script .lsp para AutoCAD: Dibuja rectángulo de zapata y malla de acero
  static Future<String> generarScriptZapata({
    required double largo,
    required double ancho,
    required double espaciamientoAcero,  // ej. 0.15m
  }) async {
    String script = '''
;; Script generado por LYP Innova Pro
;; Dibuja zapata rectangular
(command "rectangle" "0,0" "\$LARGO,\$ANCHO")

;; Dibuja malla de acero horizontal
(setq y 0)
(while (< y \$ANCHO)
  (command "line" "0,y" "\$LARGO,y" "")
  (setq y (+ y \$ESPACIAMIENTO))
)

;; Dibuja malla de acero vertical
(setq x 0)
(while (< x \$LARGO)
  (command "line" "x,0" "x,\$ANCHO" "")
  (setq x (+ x \$ESPACIAMIENTO))
)
''';

    // Reemplaza placeholders
    script = script.replaceAll('\$LARGO', largo.toString());
    script = script.replaceAll('\$ANCHO', ancho.toString());
    script = script.replaceAll('\$ESPACIAMIENTO', espaciamientoAcero.toString());

    // Guarda el archivo
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/zapata_script.lsp');
    await file.writeAsBytes(script.codeUnits);  // Corregido: writeAsBytes espera List<int>, no String
    return file.path;
  }
}
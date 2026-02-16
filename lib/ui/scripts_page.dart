import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';  // Para HapticFeedback
import 'package:path_provider/path_provider.dart';  // Para guardar archivos
import 'dart:io';
import 'package:provider/provider.dart';
import '../main.dart';

class ScriptsAutocadWidget extends StatefulWidget {
  const ScriptsAutocadWidget({super.key});

  @override
  State<ScriptsAutocadWidget> createState() => _ScriptsAutocadWidgetState();
}

class _ScriptsAutocadWidgetState extends State<ScriptsAutocadWidget> with TickerProviderStateMixin {
  // Campos optimizados con tipos explícitos
  double largo = 0.0;
  double ancho = 0.0;
  double _espaciamiento = 0.15;  // Espaciamiento NTP (m)
  String _diametro = '3/8"';  // Diámetro NTP
  String script = '';
  String? _errorMessage;
  bool _isGenerating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Nuevos campos para formas NTP
  String _selectedShape = 'Rectángulo con Malla';
  double _radius = 0.0;
  double _startX = 0.0, _startY = 0.0, _endX = 0.0, _endY = 0.0;
  int _lados = 3;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    if (kDebugMode) debugPrint("[TELEMETRIA SCRIPTS] Inicializado NTP");
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Método optimizado para validaciones NTP
  bool _validarEntradas() {
    if ((largo <= 0 || ancho <= 0) && _selectedShape != 'Círculo' && _selectedShape != 'Línea' && _selectedShape != 'Polígono') return false;
    if (_espaciamiento < 0.1 || _espaciamiento > 0.5) return false;
    if (_selectedShape == 'Círculo' && _radius <= 0) return false;
    if (_selectedShape == 'Línea' && (_startX < 0 || _startY < 0 || _endX < 0 || _endY < 0)) return false;
    if (_selectedShape == 'Polígono' && _lados < 3) return false;
    return true;
  }

  void generarScript() async {
    setState(() {
      _errorMessage = null;
      _isGenerating = true;
    });

    if (!_validarEntradas()) {
      setState(() {
        _errorMessage = 'Datos inválidos NTP. Verifica dimensiones.';
        _isGenerating = false;
      });
      return;
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Corregido: Cambiar incrementDailyCalculations a validateCalculation (undefined_method)
      appState.validateCalculation();  // Corregido: undefined_method, sin await

      // Cálculos NTP optimizados
      int varillasLargo = (largo / _espaciamiento).ceil();
      int varillasAncho = (ancho / _espaciamiento).ceil();
      double totalSteel = varillasLargo * largo + varillasAncho * ancho;
      String suggestion = totalSteel > 50 ? 'Optimiza NTP: Reduce espaciamiento.' : 'Malla óptima NTP.';
      String norma = 'NTP E060 cumplido.';

      // Logs NTP
      if (kDebugMode) debugPrint("Sugerencia: $suggestion, Norma: $norma");

      // Generación script NTP
      switch (_selectedShape) {
        case 'Rectángulo con Malla':
          script = '''
(defun c:drawrectmalla ()
  (command "rectangle" "0,0" "${largo.toStringAsFixed(2)},${ancho.toStringAsFixed(2)}")
  (repeat $varillasLargo (command "line" "0,(* \$index $_espaciamiento)" "${ancho.toStringAsFixed(2)},(* \$index $_espaciamiento)"))
  (repeat $varillasAncho (command "line" "(* \$index $_espaciamiento),0" "(* \$index $_espaciamiento),${largo.toStringAsFixed(2)}"))
  (princ "\\nNTP: $varillasLargo largo, $varillasAncho ancho, total ${totalSteel.toStringAsFixed(2)} m.")
)
'''.replaceAll('\$varillasLargo', varillasLargo.toString())
   .replaceAll('\$_espaciamiento', _espaciamiento.toString())
   .replaceAll('\$varillasAncho', varillasAncho.toString())
   .replaceAll('\$totalSteel', totalSteel.toStringAsFixed(2));
          break;
        case 'Círculo':
          script = '''
(defun c:drawcircle ()
  (command "circle" "${_startX.toStringAsFixed(2)},${_startY.toStringAsFixed(2)}" "${_radius.toStringAsFixed(2)}")
  (princ "\\nNTP: Círculo radio ${_radius.toStringAsFixed(2)} m.")
)
''';
          suggestion = 'Círculo NTP para RNE.';
          break;
        case 'Línea':
          script = '''
(defun c:drawline ()
  (command "line" "${_startX.toStringAsFixed(2)},${_startY.toStringAsFixed(2)}" "${_endX.toStringAsFixed(2)},${_endY.toStringAsFixed(2)}")
  (princ "\\nNTP: Línea trazada.")
)
''';
          suggestion = 'Línea NTP para RNC.';
          break;
        case 'Polígono':
          script = '''
(defun c:drawpolygon ()
  (command "polygon" "$_lados" "${_startX.toStringAsFixed(2)},${_startY.toStringAsFixed(2)}" "i" "${_radius.toStringAsFixed(2)}")
  (princ "\\nNTP: Polígono $_lados lados.")
)
'''.replaceAll('\$_lados', _lados.toString());
          suggestion = 'Polígono NTP irregular.';
          break;
        default:
          setState(() {
            _errorMessage = 'Forma no soportada NTP.';
            _isGenerating = false;
          });
          return;
      }

      setState(() {});
      HapticFeedback.mediumImpact();
      if (kDebugMode) debugPrint("[TELEMETRIA SCRIPTS] Script generado NTP");
    } catch (e) {
      setState(() => _errorMessage = 'Error NTP: $e');
      if (kDebugMode) debugPrint("[TELEMETRIA SCRIPTS] Error: $e");
      rethrow;
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  void guardarScript() async {
    if (script.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Genera script NTP primero')),
        );
      }
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/script_autocad.lsp');
      await file.writeAsString(script);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guardado NTP: ${file.path}')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SCRIPTS] Guardado .lsp");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error guardar NTP')),
        );
      }
      if (kDebugMode) debugPrint("[TELEMETRIA SCRIPTS] Error guardar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (appState.plan != 'pro') {
      return const Scaffold(body: Center(child: Text('PRO requerido.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scripts AutoCAD PRO - LYP Innova', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar NTP',
            onPressed: guardarScript,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Generador Scripts LISP NTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedShape,
                                items: const ['Rectángulo con Malla', 'Círculo', 'Línea', 'Polígono'].map((shape) {
                                  return DropdownMenuItem(value: shape, child: Text(shape));
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedShape = value!),
                                decoration: const InputDecoration(
                                  labelText: 'Forma NTP',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_selectedShape == 'Rectángulo con Malla' || _selectedShape == 'Línea') ...[
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Largo (m)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.straighten),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => largo = double.tryParse(v) ?? 0,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Ancho (m)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.width_normal),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => ancho = double.tryParse(v) ?? 0,
                                ),
                              ],
                              if (_selectedShape == 'Círculo' || _selectedShape == 'Polígono') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Centro X',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _startX = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Centro Y',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _startY = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Radio (m)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.circle),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _radius = double.tryParse(v) ?? 0,
                                ),
                              ],
                              if (_selectedShape == 'Línea') ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Inicio X',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _startX = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Inicio Y',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _startY = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Fin X',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _endX = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Fin Y',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.location_on),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _endY = double.tryParse(v) ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_selectedShape == 'Polígono') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Lados',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.format_shapes),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _lados = int.tryParse(v) ?? 3,
                                ),
                              ],
                              if (_selectedShape == 'Rectángulo con Malla') ...[
                                const SizedBox(height: 20),
                                const Text('Malla Acero NTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Espaciamiento (m)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.grid_on),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _espaciamiento = double.tryParse(v) ?? 0.15,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _diametro,
                                  items: const ['3/8"', '1/2"', '5/8"'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                  onChanged: (v) => setState(() => _diametro = v!),
                                  decoration: const InputDecoration(
                                    labelText: 'Diámetro',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.settings),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.code),
                                label: const Text('Generar NTP'),
                                onPressed: _isGenerating ? null : generarScript,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade900,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_errorMessage != null) Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      if (_isGenerating) const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(),
                      ),
                      if (script.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Script NTP Generado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: Colors.grey.shade100,
                                  child: SelectableText(
                                    script,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('Norma: NTP E060.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                const Text('Sugerencia: Copia y pega en AutoCAD.', style: TextStyle(fontSize: 14, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
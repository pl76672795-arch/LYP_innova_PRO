import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';  // Para HapticFeedback
import 'package:intl/intl.dart';  // Para formateo de fechas
import 'package:hive_flutter/hive_flutter.dart';  // Para persistencia
import 'package:share_plus/share_plus.dart';  // Para compartir/exportar
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  final AppState appState;

  const HistoryScreen({super.key, required this.appState});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Box _historyBox;  // Box de Hive para historial persistente
  List<Map<String, dynamic>> _history = [];
  DateTime? _filterDate;
  String? _filterType;  // Nuevo: filtro por tipo de cálculo
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _initHistoryBox();  // Inicializar Hive box
    if (kDebugMode) debugPrint("[TELEMETRIA HISTORY] Entrando a HistoryScreen PRO");
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initHistoryBox() async {
    _historyBox = await Hive.openBox('history_${widget.appState.currentUser?.uid ?? 'guest'}');
    _loadHistory();
  }

  void _loadHistory() {
    final rawHistory = _historyBox.values.toList();
    _history = rawHistory.map((item) => Map<String, dynamic>.from(item)).toList();
    setState(() {});
  }

  void _addToHistory(String calculation, String result) {
    final newItem = {
      'date': DateTime.now(),
      'calculation': calculation,
      'result': result,
      'type': _getTypeFromCalculation(calculation),  // Nuevo: tipo basado en cálculo
    };
    _historyBox.add(newItem);
    _loadHistory();
  }

  String _getTypeFromCalculation(String calculation) {
    if (calculation.contains('acero')) return 'Acero';
    if (calculation.contains('albañilería')) return 'Albañilería';
    if (calculation.contains('NTP')) return 'NTP';
    return 'Otro';
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    if (appState.plan != 'pro') {
      return const Scaffold(body: Center(child: Text('Esta función es solo para PRO.')));
    }

    final filteredHistory = _history.where((item) {
      final matchesDate = _filterDate == null || (item['date'] as DateTime).day == _filterDate!.day && (item['date'] as DateTime).month == _filterDate!.month && (item['date'] as DateTime).year == _filterDate!.year;
      final matchesType = _filterType == null || item['type'] == _filterType;
      return matchesDate && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial PRO - LYP Innova', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterType = value == 'Todos' ? null : value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Todos', child: Text('Todos los tipos')),
              const PopupMenuItem(value: 'Acero', child: Text('Acero')),
              const PopupMenuItem(value: 'Albañilería', child: Text('Albañilería')),
              const PopupMenuItem(value: 'NTP', child: Text('NTP')),
              const PopupMenuItem(value: 'Otro', child: Text('Otro')),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por tipo',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Filtrar por fecha',
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir historial',
            onPressed: () => _shareHistory(filteredHistory),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;  // Usado para ajustar padding
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
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),  // Responsive padding
                child: Column(
                  children: [
                    if (_filterDate != null || _filterType != null)
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_filterDate != null)
                            Chip(
                              label: Text('Fecha: ${_dateFormat.format(_filterDate!)}'),
                              onDeleted: () => setState(() => _filterDate = null),
                            ),
                          if (_filterType != null)
                            Chip(
                              label: Text('Tipo: $_filterType'),
                              onDeleted: () => setState(() => _filterType = null),
                            ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredHistory.isEmpty
                          ? const Center(child: Text('No hay historial disponible.'))
                          : ListView.builder(
                              itemCount: filteredHistory.length,
                              itemBuilder: (context, index) {
                                final item = filteredHistory[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: const Icon(Icons.history, color: Colors.orange),  // Const agregado
                                    title: Text(item['calculation'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Fecha: ${_dateFormat.format(item['date'])} | Tipo: ${item['type']} | Resultado: ${item['result']}'),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Detalles de: ${item['calculation']}')),
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteHistoryItem(item),  // Corregido: Pasar el item completo
                                      tooltip: 'Eliminar',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSampleHistory(),
        tooltip: 'Agregar cálculo de ejemplo',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  void _shareHistory(List<Map<String, dynamic>> history) {
    final text = history.map((item) => '${item['calculation']} - ${item['result']} (${_dateFormat.format(item['date'])})').join('\n');
    Share.share('Historial de cálculos:\n$text');
    if (kDebugMode) debugPrint("[TELEMETRIA HISTORY] Compartiendo ${history.length} items");
  }

  void _deleteHistoryItem(Map<String, dynamic> item) {  // Corregido: Recibir el item completo
    final originalIndex = _history.indexOf(item);
    _historyBox.deleteAt(originalIndex);
    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item eliminado')),
    );
  }

  void _addSampleHistory() {
    _addToHistory('Cálculo de ejemplo NTP', '300 m²');
  }
}
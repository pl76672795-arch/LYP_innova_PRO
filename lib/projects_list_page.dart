import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel;
import '../firebase_sync.dart';

// Clase principal: Página de lista de proyectos con optimizaciones avanzadas
class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({
    super.key,
    required this.projectBox,
    required this.onRefresh,
  });

  final dynamic projectBox; // Usar HiveBox si es posible para mejor tipado
  final VoidCallback onRefresh;

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> with TickerProviderStateMixin {
  late final projectBox = widget.projectBox;
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final ValueNotifier<String> _filterByNotifier = ValueNotifier('all');
  final ValueNotifier<bool> _isGridViewNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<List<String>> _filteredKeysNotifier = ValueNotifier([]);
  late AnimationController _fadeController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _updateFilteredKeys();
    _searchController.addListener(_onSearchChanged);
    _searchQueryNotifier.addListener(_updateFilteredKeys);
    _filterByNotifier.addListener(_updateFilteredKeys);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    _filterByNotifier.dispose();
    _isGridViewNotifier.dispose();
    _isLoadingNotifier.dispose();
    _filteredKeysNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text != _searchQueryNotifier.value) {
      _searchQueryNotifier.value = _searchController.text;
    }
  }

  void _updateFilteredKeys() {
    try {
      final allKeys = projectBox.keys.cast<String>().toList();
      final filtered = allKeys.where((key) {
        final project = projectBox.get(key);
        if (project == null) return false;

        final name = (project['name'] as String?)?.toLowerCase() ?? '';
        final matchesSearch = name.contains(_searchQueryNotifier.value.toLowerCase());

        final matchesFilter = _filterByNotifier.value == 'all' ||
            (_filterByNotifier.value == 'engineering' && project.containsKey('metrado_acero')) ||
            (_filterByNotifier.value == 'construction' && project.containsKey('ladrillos'));

        return matchesSearch && matchesFilter;
      }).toList();

      filtered.sort((a, b) {
        final dateA = projectBox.get(a)?['date'] ?? '';
        final dateB = projectBox.get(b)?['date'] ?? '';
        return dateB.compareTo(dateA);
      });

      _filteredKeysNotifier.value = List.unmodifiable(filtered);
    } catch (e) {
      _filteredKeysNotifier.value = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F7F9),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "LYP INNOVA PRO",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isGridViewNotifier,
            builder: (context, isGrid, _) => IconButton(
              icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
              onPressed: () => _isGridViewNotifier.value = !isGrid,
              tooltip: isGrid ? 'Cambiar a vista de lista' : 'Cambiar a vista de cuadrícula',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: _syncCloud,
            tooltip: 'Sincronizar con la nube',
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, _) => isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => _updateFilteredKeys(),
                      child: ValueListenableBuilder<List<String>>(
                        valueListenable: _filteredKeysNotifier,
                        builder: (context, keys, _) => keys.isEmpty
                            ? _buildEmptyState()
                            : _buildMainContent(),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange[800],
        onPressed: _exportToExcel,
        icon: const Icon(Icons.table_chart_rounded, color: Colors.white),
        label: const Text(
          "EXPORTAR EXCEL",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Buscar por nombre de obra...",
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _filterChip("Todos", 'all'),
              const SizedBox(width: 8),
              _filterChip("Ingeniería", 'engineering'),
              const SizedBox(width: 8),
              _filterChip("Obra", 'construction'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return ValueListenableBuilder<String>(
      valueListenable: _filterByNotifier,
      builder: (context, filter, _) {
        final active = filter == value;
        return Expanded(
          child: ChoiceChip(
            label: Text(
              label,
              style: TextStyle(color: active ? Colors.white : Colors.grey),
            ),
            selected: active,
            selectedColor: Colors.orange[700],
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            onSelected: (selected) {
              if (selected) _filterByNotifier.value = value;
            },
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isGridViewNotifier,
      builder: (context, isGrid, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isGrid
            ? GridView.builder(
                key: const ValueKey('grid'),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _filteredKeysNotifier.value.length,
                itemBuilder: (context, index) => _projectCard(_filteredKeysNotifier.value[index]),
              )
            : ListView.builder(
                key: const ValueKey('list'),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredKeysNotifier.value.length,
                itemBuilder: (context, index) => _projectCard(_filteredKeysNotifier.value[index]),
              ),
      ),
    );
  }

  Widget _projectCard(String id) {
    final p = projectBox.get(id);
    if (p == null) return const SizedBox.shrink();
    final isEng = p.containsKey('metrado_acero');

    return FadeTransition(
      opacity: _fadeController,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (isEng ? Colors.blue : Colors.orange).withValues(alpha: 0.1),
            child: Icon(
              isEng ? Icons.engineering : Icons.foundation,
              color: isEng ? Colors.blue : Colors.orange,
            ),
          ),
          title: Text(
            p['name'] ?? 'S/N',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(p['date'] ?? 'Sin fecha'),
          trailing: _buildPopupMenu(id, p),
          onTap: () => _showProjectDetails(p),
          onLongPress: () => _showQuickSummary(p),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(String id, Map project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (val) {
        if (val == 'pdf') _exportToPDF(project);
        if (val == 'edit') _editProjectName(id, project);
        if (val == 'delete') _deleteProject(id);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: Text("Exportar PDF")), // ✅ Agregado const
        const PopupMenuItem(value: 'edit', child: Text("Renombrar")), // ✅ Agregado const
        const PopupMenuItem(value: 'delete', child: Text("Eliminar", style: TextStyle(color: Colors.red))), // ✅ Agregado const
      ],
    );
  }

  Future<void> _exportToPDF(Map project) async {
    _isLoadingNotifier.value = true;
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("REPORTE TÉCNICO - LYP INNOVA PRO")),
              pw.Text("PROYECTO: ${project['name']}"),
              pw.Text("FECHA: ${project['date']}"),
              pw.Divider(),
              pw.Bullet(text: "Acero: ${project['metrado_acero'] ?? 0} kg"),
              pw.Bullet(text: "Ladrillos: ${project['ladrillos'] ?? 0} und"),
              pw.Bullet(text: "Concreto: ${project['concreto_m3'] ?? 0} m³"),
            ],
          ),
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Reporte_${project['name']}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte técnico LYP Innova');
      _showSnackBar("PDF generado 📄", isSuccess: true);
    } catch (e) {
      _showSnackBar("Error PDF: $e");
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  Future<void> _exportToExcel() async {
    _isLoadingNotifier.value = true;
    try {
      var ex = excel.Excel.createExcel();
      var sheet = ex['Proyectos'];
      sheet.appendRow([
        excel.TextCellValue("PROYECTO"),
        excel.TextCellValue("FECHA"),
        excel.TextCellValue("ACERO (kg)"),
        excel.TextCellValue("LADRILLOS (und)"),
        excel.TextCellValue("CONCRETO (m³)"),
      ]);

      for (var key in _filteredKeysNotifier.value) {
        final p = projectBox.get(key);
        sheet.appendRow([
          excel.TextCellValue(p?['name']?.toString() ?? ''),
          excel.TextCellValue(p?['date']?.toString() ?? ''),
          excel.TextCellValue(p?['metrado_acero']?.toString() ?? '0'),
          excel.TextCellValue(p?['ladrillos']?.toString() ?? '0'),
          excel.TextCellValue(p?['concreto_m3']?.toString() ?? '0'),
        ]);
      }

      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/Backup_LYP_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      await file.writeAsBytes(ex.save()!);
      await Share.shareXFiles([XFile(path)], text: 'Backup Excel LYP');
      _showSnackBar("Excel compartido 📊", isSuccess: true);
    } catch (e) {
      _showSnackBar("Error Excel: $e");
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _editProjectName(String id, Map project) {
    final controller = TextEditingController(text: project['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renombrar Obra"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                project['name'] = controller.text.trim();
                projectBox.put(id, project);
                _updateFilteredKeys();
                Navigator.pop(context);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _deleteProject(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar Proyecto?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () {
              projectBox.delete(id);
              _updateFilteredKeys();
              Navigator.pop(context);
              _showSnackBar("Eliminado 🗑️");
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProjectDetails(Map project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(project['name'] ?? "Detalles"),
        content: Text("Fecha: ${project['date']}\n\nLos cálculos técnicos están respaldados en la nube."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CERRAR"))],
      ),
    );
  }

  void _showQuickSummary(Map project) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("RESUMEN TÉCNICO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _sumItem(Icons.bolt, "Acero", "${project['metrado_acero'] ?? 0} kg"),
            _sumItem(Icons.layers, "Concreto", "${project['concreto_m3'] ?? 0} m³"),
          ],
        ),
      ),
    );
  }

  Widget _sumItem(IconData icon, String label, String val) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(label),
      trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _syncCloud() async {
    _isLoadingNotifier.value = true;
    try {
      await FirebaseSync.syncNow(context);
      if (!mounted) return;
      _showSnackBar("Nube sincronizada ✅", isSuccess: true);
    } catch (e) {
      _showSnackBar("Error sync: $e");
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
        _updateFilteredKeys();
      }
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No hay registros técnicos aún",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green : Colors.black87,
      ),
    );
  }
}
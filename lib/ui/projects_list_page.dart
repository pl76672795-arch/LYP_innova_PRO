import 'package:flutter/material.dart';
// Removido: import 'package:pdf/pdf.dart'; (unused import)
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart'; 
import 'package:path_provider/path_provider.dart'; 
import 'dart:io'; 
import 'package:excel/excel.dart' as excel;
import '../firebase_sync.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({
    super.key,
    required this.projectBox,
    required this.onRefresh,
  });

  final dynamic projectBox;
  final VoidCallback onRefresh;

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> with TickerProviderStateMixin {
  late final projectBox = widget.projectBox;
  String _searchQuery = '';
  String _filterBy = 'all'; 
  bool _isGridView = false;
  bool _isLoading = false;
  List<String> _filteredKeys = [];
  late AnimationController _fadeController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400)
    )..forward();
    _updateFilteredKeys();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.toLowerCase() != _searchQuery.toLowerCase()) {
      setState(() {
        _searchQuery = _searchController.text;
        _updateFilteredKeys();
      });
    }
  }

  void _updateFilteredKeys() {
    try {
      final allKeys = projectBox.keys.cast<String>().toList();
      _filteredKeys = allKeys.where((key) {
        final project = projectBox.get(key);
        if (project == null) return false;
        
        final name = (project['name'] as String?)?.toLowerCase() ?? '';
        final matchesSearch = name.contains(_searchQuery.toLowerCase());
        
        final matchesFilter = _filterBy == 'all' ||
            (_filterBy == 'engineering' && project.containsKey('metrado_acero')) ||
            (_filterBy == 'construction' && project.containsKey('ladrillos'));
            
        return matchesSearch && matchesFilter;
      }).toList();

      _filteredKeys.sort((a, b) {
        final dateA = projectBox.get(a)?['date'] ?? '';
        final dateB = projectBox.get(b)?['date'] ?? '';
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      debugPrint('Error en filtro: $e');
      _filteredKeys = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF4F7F9),
      appBar: AppBar(
        elevation: 0,
        title: const Text("LYP INNOVA PRO", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync_rounded),
            onPressed: _syncCloud,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => setState(_updateFilteredKeys),
                    child: _filteredKeys.isEmpty ? _buildEmptyState() : _buildMainContent(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange[800],
        onPressed: _exportToExcel,
        icon: const Icon(Icons.table_chart_rounded, color: Colors.white),
        label: const Text("EXPORTAR EXCEL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.1),  // ✅ Cambiado withOpacity a withValues
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
    final active = _filterBy == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label, style: TextStyle(
          color: active ? Colors.white : Colors.grey,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ))),
        selected: active,
        selectedColor: Colors.orange[700],
        backgroundColor: Colors.grey.withValues(alpha: 0.1),  // ✅ Cambiado withOpacity a withValues
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _filterBy = value;
              _updateFilteredKeys();
            });
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    return _isGridView 
      ? GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredKeys.length,
          itemBuilder: (context, index) => _projectCard(_filteredKeys[index]),
        )
      : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filteredKeys.length,
          itemBuilder: (context, index) => _projectCard(_filteredKeys[index]),
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
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),  // ✅ Cambiado withOpacity a withValues
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: isEng ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),  // ✅ Cambiado withOpacity a withValues
            child: Icon(isEng ? Icons.engineering : Icons.foundation, color: isEng ? Colors.blue : Colors.orange),
          ),
          title: Text(p['name'] ?? 'S/N', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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
        const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, color: Colors.red), SizedBox(width: 8), Text("PDF")])),
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text("Renombrar")])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.grey), SizedBox(width: 8), Text("Eliminar")])),
      ],
    );
  }

  // --- MÉTODOS DE LÓGICA ---

  Future<void> _exportToPDF(Map project) async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
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
      ));

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Reporte_${project['name']}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Reporte técnico LYP Innova');
      _showSnackBar("PDF generado 📄", isSuccess: true);
    } catch (e) {
      _showSnackBar("Error PDF: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    setState(() => _isLoading = true);
    try {
      var ex = excel.Excel.createExcel();
      var sheet = ex['Proyectos'];
      sheet.appendRow([excel.TextCellValue("PROYECTO"), excel.TextCellValue("FECHA"), excel.TextCellValue("ACERO (kg)")]);

      for (var key in _filteredKeys) {
        final p = projectBox.get(key);
        sheet.appendRow([
          excel.TextCellValue(p?['name']?.toString() ?? ''),
          excel.TextCellValue(p?['date']?.toString() ?? ''),
          excel.TextCellValue(p?['metrado_acero']?.toString() ?? '0'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editProjectName(String id, Map project) {
    final controller = TextEditingController(text: project['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renombrar Obra"),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Nuevo nombre")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              project['name'] = controller.text.trim();
              projectBox.put(id, project);
              setState(_updateFilteredKeys);
              Navigator.pop(context);
            }
          }, child: const Text("GUARDAR")),
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
          TextButton(onPressed: () {
            projectBox.delete(id);
            setState(_updateFilteredKeys);
            Navigator.pop(context);
            _showSnackBar("Eliminado 🗑️");
          }, child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))),
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
            Text("RESUMEN TÉCNICO", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // ✅ TextStyle ya es const
            const Divider(),
            _sumItem(Icons.bolt, "Acero", "${project['metrado_acero'] ?? 0} kg"),
            _sumItem(Icons.layers, "Concreto", "${project['concreto_m3'] ?? 0} m³"),
          ],
        ),
      ),
    );
  }

  Widget _sumItem(IconData icon, String label, String val) {
    return ListTile(leading: Icon(icon, color: Colors.orange), title: Text(label), trailing: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)));
  }

  Future<void> _syncCloud() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseSync.syncNow(context);
      _showSnackBar("Nube sincronizada ✅", isSuccess: true);
    } catch (e) {
      _showSnackBar("Error sync: $e");
    } finally {
      if (mounted) setState(() { _isLoading = false; _updateFilteredKeys(); });
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("No hay registros técnicos aún", style: const TextStyle(color: Colors.grey, fontSize: 16)), // ✅ Agregado const a TextStyle
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isSuccess ? Colors.green : Colors.black87,
    ));
  }
}
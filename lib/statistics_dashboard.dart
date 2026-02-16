import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsDashboard extends StatefulWidget {
  final dynamic projectBox;

  const StatisticsDashboard({
    super.key,
    required this.projectBox,
  });

  @override
  State<StatisticsDashboard> createState() => _StatisticsDashboardState();
}

class _StatisticsDashboardState extends State<StatisticsDashboard> {
  late final projectBox = widget.projectBox;

  int _getTotalProjects() => projectBox.length;

  int _getProjectsThisWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    int count = 0;
    for (int i = 0; i < projectBox.length; i++) {
      final project = projectBox.getAt(i);
      if (project is Map && project.containsKey('date')) {
        try {
          final projectDate = DateTime.parse(project['date']);
          // Validación NTP: Solo contar fechas válidas y dentro de la semana
          if (projectDate.isAfter(weekAgo) && projectDate.isBefore(now.add(const Duration(days: 1)))) {
            count++;
          }
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
    }
    return count;
  }

  String _getMemoryUsage() {
    try {
      int totalSize = 0;
      for (int i = 0; i < projectBox.length; i++) {
        final project = projectBox.getAt(i);
        if (project is Map) {
          totalSize += project.toString().length;
        }
      }

      // Validación NTP: Rangos razonables para memoria en apps de ingeniería (0-100MB típico)
      if (totalSize < 0) totalSize = 0;
      if (totalSize > 100 * 1024 * 1024) totalSize = 100 * 1024 * 1024;  // Límite superior

      if (totalSize < 1024) {
        return '$totalSize B';
      } else if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      return '0 B';
    }
  }

  Map<String, int> _getScansByDay() {
    final scansByDay = <String, int>{};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: 6 - i));
      final dateKey = DateFormat('EEE', 'es').format(date).substring(0, 3).toUpperCase();
      scansByDay[dateKey] = 0;
    }

    for (int i = 0; i < projectBox.length; i++) {
      final project = projectBox.getAt(i);
      if (project is Map && project.containsKey('date')) {
        try {
          final projectDate = DateTime.parse(project['date']);
          // Validación NTP: Solo contar fechas válidas dentro de la semana
          if (projectDate.isAfter(now.subtract(const Duration(days: 7)))) {
            final dateKey = DateFormat('EEE', 'es').format(projectDate).substring(0, 3).toUpperCase();
            scansByDay[dateKey] = (scansByDay[dateKey] ?? 0) + 1;
          }
        } catch (e) {
          // Ignorar fechas inválidas
        }
      }
    }

    return scansByDay;
  }

  @override
  Widget build(BuildContext context) {
    final scansByDay = _getScansByDay();
    final maxScans = scansByDay.values.isNotEmpty
        ? scansByDay.values.reduce((a, b) => a > b ? a : b)
        : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Estadísticas",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 15,
            childAspectRatio: 0.9,
            children: [
              _buildStatCard(
                title: 'Total',
                value: _getTotalProjects().toString(),
                icon: Icons.folder_rounded,
                color: Colors.orange,
              ),
              _buildStatCard(
                title: 'Semana',
                value: _getProjectsThisWeek().toString(),
                icon: Icons.trending_up_rounded,
                color: Colors.blue,
              ),
              _buildStatCard(
                title: 'Memoria',
                value: _getMemoryUsage(),
                icon: Icons.storage_rounded,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 35),
          const Text(
            "Actividad por Día",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(  // Corregido: Quitado const para evitar const_eval_property_access
              color: Colors.white.withValues(alpha: 7.65),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 51), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: scansByDay.entries.map((entry) {
                final height = (entry.value / (maxScans.toDouble() + 1)) * 120;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 28,
                      height: height,
                      decoration: BoxDecoration(  // Asegurado: Sin const para gradient
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade800, Colors.orange.shade400],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.key,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 25.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 76.5), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
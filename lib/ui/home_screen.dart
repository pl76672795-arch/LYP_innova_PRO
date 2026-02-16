import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    if (kDebugMode) debugPrint("[TELEMETRIA HOME] Entrando a HomeScreen NTP");
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final remainingCalculations = appState.plan == 'pro' ? 'Ilimitado' : (5 - appState.dailyCalculations).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LYP Innova Pro - Modo Invitado', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _showLogoutDialog(context, appState),
          ),
          IconButton(
            icon: Icon(appState.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white),
            tooltip: appState.isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
            onPressed: appState.toggleTheme,
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      color: Colors.orange.shade100,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.build, size: 40, color: Colors.orange),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '¡Bienvenido a LYP Innova Pro!\nHerramientas avanzadas para ingeniería civil.',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (appState.currentUser != null) ...[
                              Text('Usuario: ${appState.currentUser!.email}', style: const TextStyle(fontSize: 16)),
                              Text('Plan: ${appState.plan.toUpperCase()}', style: const TextStyle(fontSize: 16)),
                              Text('Licencia activa hasta: ${appState.licenseExpiry.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 16)),
                              Text(
                                'Cálculos diarios restantes: $remainingCalculations',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: appState.plan == 'free' && appState.dailyCalculations >= 5 ? Colors.red : Colors.green,
                                ),
                              ),
                            ] else ...[
                              const Text('Modo Invitado: Funciones limitadas.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmallScreen ? 2 : 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _getOptions(appState).length,
                        itemBuilder: (context, index) {
                          final option = _getOptions(appState)[index];
                          return _buildOptionCard(context, option['icon'] as IconData, option['title'] as String, option['route'] as String, appState);
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
    );
  }

  List<Map<String, dynamic>> _getOptions(AppState appState) {
    final options = [
      {'icon': Icons.calculate, 'title': 'Cálculos NTP', 'route': '/calculations'},
      {'icon': Icons.folder, 'title': 'Proyectos', 'route': '/projects'},
      {'icon': Icons.dashboard, 'title': 'Dashboard', 'route': '/dashboard'},
      {'icon': Icons.photo_library, 'title': 'Galería', 'route': '/galeria'},
    ];
    if (appState.plan == 'pro') {
      options.add({'icon': Icons.history, 'title': 'Historial PRO', 'route': '/history'});
    }
    return options;
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String route, AppState appState) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (appState.plan == 'free' && appState.dailyCalculations >= 5 && route == '/calculations') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Límite diario alcanzado. Actualiza a PRO.')),
            );
            return;
          }
          Navigator.pushNamed(context, route);
          if (kDebugMode) debugPrint("[TELEMETRIA HOME] Navegando a $route NTP");
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.orange.shade900),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              appState.logout();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              });
              if (kDebugMode) debugPrint("[TELEMETRIA HOME] Sesión cerrada NTP");
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
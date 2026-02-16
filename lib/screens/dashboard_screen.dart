import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';  // Para HapticFeedback
import 'package:percent_indicator/percent_indicator.dart';  // Asegúrate de agregarlo a pubspec.yaml
import '../main.dart';

class DashboardScreen extends StatefulWidget {
  final AppState appState;

  const DashboardScreen({super.key, required this.appState});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _iconController;  // Para animar íconos en grid

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));  // Animación de íconos
    if (kDebugMode) debugPrint("[TELEMETRIA DASHBOARD] Entrando al Dashboard PRO para usuario: ${widget.appState.currentUser?.email}");
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final isLicenseActive = appState.isLicenseActive();
    final remainingCalculations = appState.plan == 'pro' ? 'Ilimitado' : (5 - appState.dailyCalculations).toString();
    final progress = appState.plan == 'pro' ? 1.0 : (appState.dailyCalculations / 5.0).clamp(0.0, 1.0);  // Progreso de cálculos

    if (!isLicenseActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      });
      return const Scaffold(body: Center(child: Text('Licencia expirada. Activa una nueva.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard PRO - LYP Innova', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
      drawer: _buildDrawer(context, appState),  // Drawer lateral
      bottomNavigationBar: _buildBottomNavBar(context),  // Barra de navegación inferior
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido, ${appState.currentUser?.email}!',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            const SizedBox(height: 8),
                            Text('Plan: ${appState.plan.toUpperCase()}', style: const TextStyle(fontSize: 16)),
                            Text('Licencia activa hasta: ${appState.licenseExpiry.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 16)),  // Corregido: Quitado ?. para invalid_null_aware_operator
                            const SizedBox(height: 10),
                            // Indicador de progreso circular para cálculos diarios
                            CircularPercentIndicator(
                              radius: 50.0,
                              lineWidth: 8.0,
                              percent: progress,
                              center: Text(
                                appState.plan == 'pro' ? '∞' : '$remainingCalculations/5',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              progressColor: progress < 0.5 ? Colors.green : progress < 0.8 ? Colors.orange : Colors.red,
                              backgroundColor: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cálculos diarios restantes: $remainingCalculations',
                              style: TextStyle(
                                fontSize: 16,
                                color: appState.plan == 'free' && appState.dailyCalculations >= 5 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Herramientas Avanzadas PRO',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 10),
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

  Widget _buildDrawer(BuildContext context, AppState appState) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.orange.shade900),
            child: const Text(
              'Menú Rápido',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          ListTile(
            leading: const Icon(Icons.calculate),
            title: const Text('Cálculos'),
            onTap: () => Navigator.pushNamed(context, '/calculations'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Presupuesto'),
            onTap: () => Navigator.pushNamed(context, '/budget'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración próximamente'))),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Ayuda'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayuda próximamente'))),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.calculate), label: 'Cálculos'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Presupuesto'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushNamed(context, '/calculations');
            break;
          case 2:
            Navigator.pushNamed(context, '/budget');
            break;
        }
      },
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
    );
  }

  List<Map<String, dynamic>> _getOptions(AppState appState) {
    final options = [
      {'icon': Icons.calculate, 'title': 'Cálculos', 'route': '/calculations'},
      {'icon': Icons.folder, 'title': 'Proyectos', 'route': '/projects'},
      {'icon': Icons.history, 'title': 'Historial PRO', 'route': '/history'},
      {'icon': Icons.account_balance_wallet, 'title': 'Presupuesto', 'route': '/budget'},
      {'icon': Icons.camera, 'title': 'Escáner', 'route': '/scan'},
      {'icon': Icons.build, 'title': 'Acero', 'route': '/acero'},
      {'icon': Icons.construction, 'title': 'Albañilería', 'route': '/albanileria'},
      {'icon': Icons.code, 'title': 'Scripts', 'route': '/scripts'},
    ];
    return options;
  }

  Widget _buildOptionCard(BuildContext context, IconData icon, String title, String route, AppState appState) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _iconController.forward().then((_) => _iconController.reverse());  // Animación de ícono
          if (appState.plan == 'free' && appState.dailyCalculations >= 5 && route == '/calculations') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Límite diario alcanzado. Actualiza a PRO.')),
            );
            return;
          }
          Navigator.pushNamed(context, route);
          if (kDebugMode) debugPrint("[TELEMETRIA DASHBOARD] Navegando a $route");
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _iconController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + _iconController.value * 0.2,  // Escala animada
                    child: Icon(icon, size: 48, color: Colors.orange),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_getDescription(title), style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  String _getDescription(String title) {
    switch (title) {
      case 'Cálculos':
        return 'Herramientas de cálculo ingenieril';
      case 'Proyectos':
        return 'Gestiona tus proyectos';
      case 'Historial PRO':
        return 'Historial de cálculos (solo PRO)';
      case 'Presupuesto':
        return 'Gestión de presupuestos';
      case 'Escáner':
        return 'Escanea y calcula';
      case 'Acero':
        return 'Cálculos de acero';
      case 'Albañilería':
        return 'Cálculos de albañilería';
      case 'Scripts':
        return 'Scripts AutoCAD';
      default:
        return '';
    }
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
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {  // Corregido: Usado addPostFrameCallback para use_build_context_synchronously
                  if (mounted) {
                    Navigator.of(context).pop();  // Cerrar dialog primero
                    Navigator.pushReplacementNamed(context, '/login');  // Luego navegar
                  }
                });
              }
              if (kDebugMode) debugPrint("[TELEMETRIA DASHBOARD] Sesión cerrada");
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
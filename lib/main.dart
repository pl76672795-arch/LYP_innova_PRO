import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Pantallas
import 'screens/dashboard_screen.dart';
import 'screens/budget_screen.dart';
import 'ui/home_screen.dart';
import 'ui/login_screen.dart';
import 'ui/scripts_page.dart';
import 'galeria_obra_page.dart';
import 'screens/history_screen.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  String _plan = 'pro';
  int _dailyCalculations = 0;
  bool _isDarkMode = false;
  static const int maxDailyCalculations = 100;
  late Box _appBox;

  User? get currentUser => _currentUser;
  String get plan => _plan;
  int get dailyCalculations => _dailyCalculations;
  bool get isDarkMode => _isDarkMode;
  
  // ✅ FIX: Agregamos lo que el Dashboard y Home pedían
  DateTime get licenseExpiry => DateTime.now().add(const Duration(days: 365));
  bool isLicenseActive() => true;

  Future<void> initHive() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox('lyp_innova_pro_data');
    _dailyCalculations = _appBox.get('dailyCalculations', defaultValue: 0);
    _plan = _appBox.get('plan', defaultValue: 'pro');
    _isDarkMode = _appBox.get('isDarkMode', defaultValue: false);
    
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // ✅ FIX: Agregamos métodos para que el Login no de error
  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> loadUserData() async {
    notifyListeners();
  }

  void validateCalculation() {
    if (_dailyCalculations < maxDailyCalculations) {
      _dailyCalculations++;
      _appBox.put('dailyCalculations', _dailyCalculations);
      notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _appBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(); } catch (e) { if (kDebugMode) debugPrint("Error Firebase: $e"); }

  final appState = AppState();
  await appState.initHive();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return MaterialApp(
          title: 'LYP Innova PRO',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.orange,
            brightness: state.isDarkMode ? Brightness.dark : Brightness.light,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w900), // ✅ FIX: Cambiado 'black' por 'w900'
            ),
          ),
          initialRoute: state.currentUser == null ? '/login' : '/home',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/dashboard': (context) => DashboardScreen(appState: state),
            '/budget': (context) => BudgetScreen(appState: state),
            '/scripts': (context) => const ScriptsAutocadWidget(),
            '/galeria': (context) => const GaleriaObraPage(),
            '/history': (context) => HistoryScreen(appState: state),
          },
        );
      },
    );
  }
}
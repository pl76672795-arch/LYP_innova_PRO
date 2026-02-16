import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';  // Para HapticFeedback
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _codeController = TextEditingController();
  
  String _error = '';
  int _attempts = 0;
  bool _usePin = false;
  bool _isLoading = false;
  bool _isEmailValid = false;  // Nuevo: Para validación visual
  bool _isPasswordValid = false;  // Nuevo: Para validación visual
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _iconController;  // Nuevo: Para animar íconos

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));  // Nuevo: Animación de íconos
    if (kDebugMode) debugPrint("[TELEMETRIA LOGIN] Entrando a LoginScreen");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    _fadeController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _isPasswordValid = value.length >= 6;  // Mínimo 6 caracteres
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acceso Seguro - LYP Innova Pro'),
        backgroundColor: Colors.orange.shade900,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade100, Colors.white, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 48, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _iconController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + _iconController.value * 0.1,  // Animación de escala
                            child: const Icon(Icons.lock, size: 80, color: Colors.orange),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Usar Email/Password'),
                          Switch(
                            value: _usePin,
                            onChanged: (value) => setState(() => _usePin = value),
                          ),
                          const Text('Usar PIN'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (!_usePin) ...[
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: _validateEmail,  // Validación en tiempo real
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _isEmailValid ? Colors.green : Colors.red, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.orange, width: 2),
                            ),
                            prefixIcon: Icon(
                              _isEmailValid ? Icons.check_circle : Icons.email,
                              color: _isEmailValid ? Colors.green : Colors.grey,
                            ),
                            suffixIcon: _isEmailValid ? const Icon(Icons.check, color: Colors.green) : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.8),  // Corregido: Cambiado withOpacity a withValues para deprecated_member_use
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: _validatePassword,  // Validación en tiempo real
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _isPasswordValid ? Colors.green : Colors.red, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.orange, width: 2),
                            ),
                            prefixIcon: Icon(
                              _isPasswordValid ? Icons.lock_open : Icons.lock,
                              color: _isPasswordValid ? Colors.green : Colors.grey,
                            ),
                            suffixIcon: _isPasswordValid ? const Icon(Icons.check, color: Colors.green) : null,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.8),  // Corregido: Cambiado withOpacity a withValues para deprecated_member_use
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Iniciar Sesión'),
                          onPressed: (_isEmailValid && _isPasswordValid && !_isLoading) ? () => _loginWithFirebase(appState) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade900,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading ? null : () => _registerWithFirebase(appState),
                          child: const Text('¿No tienes cuenta? Regístrate'),
                        ),
                      ] else ...[
                        if (appState.currentUser == null) ...[
                          const Text('Debes iniciar sesión con Email primero.', style: TextStyle(color: Colors.red)),
                        ] else ...[
                          const Text('Ingresa tu PIN de 4 dígitos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('Fórmula: (tu número + 2012) * 2', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'PIN',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text('Ingresar con PIN'),
                            onPressed: _isLoading ? null : () => _verifyPin(appState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade900,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      if (appState.currentUser != null) ...[
                        const Text('Activar Versión PRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Código de Activación',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _activatePro(appState),
                          child: const Text('Activar PRO'),
                        ),
                      ],
                      if (_error.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                      if (_isLoading) const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: CircularProgressIndicator(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'LYP Innova Pro: Herramientas avanzadas para ingenieros. Inicio de sesión obligatorio para seguridad.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
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

  void _loginWithFirebase(AppState appState) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Completa email y contraseña.');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() => _error = 'Email inválido.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await appState.login(_emailController.text, _passwordController.text);
      HapticFeedback.mediumImpact();
      _iconController.forward();  // Animación de éxito
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
      if (kDebugMode) debugPrint("[TELEMETRIA LOGIN] Login exitoso, navegando a dashboard...");
    } catch (e) {
      setState(() => _error = 'Error en login: $e');
      if (kDebugMode) debugPrint("[TELEMETRIA LOGIN] Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _registerWithFirebase(AppState appState) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Completa email y contraseña.');
      return;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(_emailController.text)) {
      setState(() => _error = 'Email inválido.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await appState.login(_emailController.text, _passwordController.text);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
      if (kDebugMode) debugPrint("[TELEMETRIA REGISTRO] Registro y login exitoso.");
    } catch (e) {
      setState(() => _error = 'Error en registro: $e');
      if (kDebugMode) debugPrint("[TELEMETRIA REGISTRO] Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyPin(AppState appState) {
    if (_pinController.text.length != 4) {
      setState(() => _error = 'El PIN debe tener exactamente 4 dígitos.');
      return;
    }
    if (_attempts >= 3) {
      setState(() => _error = 'Demasiados intentos. Contacta al administrador.');
      return;
    }
    // Corregido: validateCalculation es void, quitar argumentos extra
    appState.validateCalculation();  // Corregido: use_of_void_result, extra_positional_arguments
    try {
      final box = Hive.box('users');
      final userNumber = box.get('user_number', defaultValue: 0);
      final expectedPin = ((userNumber + 2012) * 2).toString();
      if (_pinController.text == expectedPin) {
        if (appState.plan == 'free' && appState.dailyCalculations >= 5) {
          setState(() => _error = 'Límite diario alcanzado. Actualiza a PRO.');
          return;
        }
        HapticFeedback.mediumImpact();
        if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
        if (kDebugMode) debugPrint("[TELEMETRIA PIN] PIN correcto, acceso concedido.");
      } else {
        setState(() {
          _attempts++;
          _error = 'PIN incorrecto. Intentos restantes: ${3 - _attempts}';
          if (_attempts >= 3) {
            _error = 'Demasiados intentos. Contacta al administrador.';
          }
        });
        if (kDebugMode) debugPrint("[TELEMETRIA PIN] PIN incorrecto, intento $_attempts.");
      }
    } catch (e) {
      setState(() => _error = 'Error al verificar PIN. Verifica datos.');
      if (kDebugMode) debugPrint("[TELEMETRIA PIN] Error: $e");
    }
  }

  void _activatePro(AppState appState) async {
    if (_codeController.text.isEmpty) {
      setState(() => _error = 'Ingresa un código.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(appState.currentUser!.uid).update({'plan': 'pro'});
      await appState.loadUserData();
      HapticFeedback.mediumImpact();
      setState(() => _error = 'PRO activado exitosamente.');
      if (kDebugMode) debugPrint("[TELEMETRIA PRO] PRO activado.");
    } catch (e) {
      setState(() => _error = 'Error al activar: $e');
      if (kDebugMode) debugPrint("[TELEMETRIA PRO] Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
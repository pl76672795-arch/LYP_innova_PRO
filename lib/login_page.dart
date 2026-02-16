import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'core/auth_service.dart';  // Corregido: Cambiado de 'auth_service.dart' a 'core/auth_service.dart'

/// Pantalla de login profesional - LYP INNOVA
/// Autenticacion con Firebase: Email/Contrasena y Google Sign-In
/// Validaciones robustas y manejo de errores
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Keys para formulario
  final _formKey = GlobalKey<FormState>();
  
  // Estados de UI
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUpMode = false; // false = login, true = registro
  
  @override
  void initState() {
    super.initState();
    _cargarUltimoEmail();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  /// Carga el ultimo email usado (si existe)
  Future<void> _cargarUltimoEmail() async {
    try {
      final email = await AuthService.getLastEmail();
      if (email != null && mounted) {
        _emailController.text = email;
      }
    } catch (e) {
      // Silencioso si no hay email guardado
    }
  }
  
  /// Validador de email (con validaciones NTP para seguridad en ingeniería)
  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    
    // Patrón básico de email, reforzado para dominios profesionales
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido (ej. usuario@dominio.com)';
    }
    
    // Validación adicional NTP: Evitar emails temporales
    if (value.contains('@temp.') || value.contains('@10minutemail.')) {
      return 'Usa un email profesional válido';
    }
    
    return null;
  }
  
  /// Validador de contrasena (con validaciones NTP para seguridad)
  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    
    // Validación adicional NTP: Requiere mayúscula, minúscula y número
    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Debe incluir mayúscula, minúscula y número';
    }
    
    return null;
  }
  
  /// Manejo de login/registro con email y contrasena
  Future<void> _submitFormulario() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Verificar que Firebase este listo
    if (!firebaseReady) {
      _mostrarError(
        'Firebase no esta listo. Verifica tu conexion o ejecuta flutterfire configure.',
      );
      return;
    }
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    setState(() => _isLoading = true);
    
    try {
      if (_isSignUpMode) {
        // MODO REGISTRO
        await AuthService.signUp(email, password);
        
        if (mounted) {
          _mostrarExito('Cuenta creada exitosamente');
          
          // Cambiar a modo login despues de registro
          setState(() => _isSignUpMode = false);
        }
      } else {
        // MODO LOGIN
        await AuthService.signIn(email, password);
        
        if (mounted) {
          // Navegacion exitosa al HubPage
          Navigator.of(context).pushReplacementNamed('/hub');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _manejarErrorFirebase(e);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Manejo de login con Google
  Future<void> _signInConGoogle() async {
    if (!firebaseReady) {
      _mostrarError('Firebase no esta listo. Verifica tu conexion.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await AuthService.signInWithGoogle();
      
      if (mounted) {
        // Navegacion exitosa al HubPage
        Navigator.of(context).pushReplacementNamed('/hub');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _manejarErrorFirebase(e);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error con Google Sign-In: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Maneja errores especificos de Firebase
  void _manejarErrorFirebase(FirebaseAuthException e) {
    String mensaje;
    
    switch (e.code) {
      case 'user-not-found':
        mensaje = 'No existe una cuenta con ese email';
        break;
      case 'wrong-password':
        mensaje = 'Contraseña incorrecta';
        break;
      case 'email-already-in-use':
        mensaje = 'Ya existe una cuenta con ese email';
        break;
      case 'invalid-email':
        mensaje = 'El formato del email es invalido';
        break;
      case 'weak-password':
        mensaje = 'La contraseña es muy debil';
        break;
      case 'network-request-failed':
        mensaje = 'Sin conexion a Internet';
        break;
      case 'too-many-requests':
        mensaje = 'Demasiados intentos. Intenta mas tarde';
        break;
      case 'user-disabled':
        mensaje = 'Esta cuenta ha sido deshabilitada';
        break;
      case 'operation-not-allowed':
        mensaje = 'Operacion no permitida';
        break;
      default:
        mensaje = e.message ?? 'Error: ${e.code}';
    }
    
    _mostrarError(mensaje);
  }
  
  /// Muestra mensaje de error
  void _mostrarError(String mensaje) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
  
  /// Muestra mensaje de exito
  void _mostrarExito(String mensaje) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Fondo oscuro LYP INNOVA
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            padding.left + 24,
            20,
            padding.right + 24,
            24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Espaciado superior
                SizedBox(height: size.height * 0.08),
                
                // Logo y titulo
                const Icon(
                  Icons.engineering,
                  size: 80,
                  color: Colors.orangeAccent,
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'LYP INNOVA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isSignUpMode 
                      ? 'Crea tu cuenta de ingeniero'
                      : 'Acceso seguro a tu obra',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Boton de Google Sign-In
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInConGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continuar con Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divisor
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Campo de Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  validator: _validarEmail,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 12.75),  // Ya corregido
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Campo de Contrasena
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white),
                  validator: _validarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white54,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.orangeAccent,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 12.75),  // Ya corregido
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Boton principal (Login/Registrar)
                FilledButton(
                  onPressed: _isLoading ? null : _submitFormulario,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.orange,
                    disabledBackgroundColor: Colors.orange.withValues(alpha: 127),  // Ya corregido
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUpMode ? 'Crear cuenta' : 'Entrar',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                
                const SizedBox(height: 16),
                
                // Toggle entre Login y Registro
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() => _isSignUpMode = !_isSignUpMode);
                        },
                  child: Text(
                    _isSignUpMode
                        ? 'Ya tengo cuenta - Entrar'
                        : 'No tengo cuenta - Registrarme',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Texto informativo
                if (!_isSignUpMode)
                  const Text(
                    'Ingresa con tu cuenta para acceder a tus calculos y proyectos guardados en la nube.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                
                if (_isSignUpMode)
                  const Text(
                    'Crea tu cuenta para guardar tus calculos en la nube y acceder desde cualquier dispositivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
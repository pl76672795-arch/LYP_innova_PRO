import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  static Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'plan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return result.user;
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential result = await _auth.signInWithPopup(googleProvider);
      return result.user;
    } catch (e) {
      throw Exception('Error con Google: $e');
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<String?> getLastEmail() async {
    // Implementación para obtener último email (ej. desde SharedPreferences)
    return null;
  }

  static Future<void> activarPro(String code) async {
    // Implementación para activar PRO (ej. validar código y actualizar Firestore)
    throw Exception('Código inválido');
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
    }
  }

  static Future<void> updateProfile(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
    }
  }

  static Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
    }
  }
}
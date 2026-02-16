import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  Map<String, dynamic>? ultimoResultado;
  bool isDarkMode = false;

  void setResultado(Map<String, dynamic> resultado) {
    ultimoResultado = resultado;
    notifyListeners();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
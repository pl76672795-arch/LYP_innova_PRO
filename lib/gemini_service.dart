import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

// Esta clase es el motor de inteligencia para tus 7 APKs
class GeminiService {
  // 🔑 REEMPLAZA ESTE TEXTO CON TU CLAVE DE AI STUDIO
  static const String _apiKey = "TU_API_KEY_AQUI"; 

  Future<String> obtenerRespuesta(String mensaje) async {
    try {
      // Configuramos el modelo Gemini 1.5 Flash (el más rápido para móviles)
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: _apiKey,
      );

      final content = [Content.text(mensaje)];
      final response = await model.generateContent(content);
      
      // Si la respuesta es nula, enviamos un mensaje amigable
      return response.text ?? "La IA no pudo generar una respuesta ahora.";
      
    } catch (e) {
      // 🛡️ PARCHE ANTIPANTALLA ROJA:
      // Esto captura el error de Firebase/JavaScript y lo imprime en consola
      // en lugar de romper la aplicación en el navegador.
      debugPrint("---------- ERROR EN GEMINI SERVICE ----------");
      debugPrint(e.toString());
      debugPrint("---------------------------------------------");
      
      return "Ocurrió un pequeño error de conexión. Inténtalo de nuevo.";
    }
  }
}
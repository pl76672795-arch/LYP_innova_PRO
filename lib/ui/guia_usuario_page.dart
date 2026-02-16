import 'package:flutter/material.dart';

class GuiaUsuarioPage extends StatelessWidget {
  const GuiaUsuarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guía de Usuario')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.camera),
            title: Text('1. Usar el Scanner'),
            subtitle: Text('Abre la cámara, apunta a texto y escanea. La IA reconoce números automáticamente.'),
          ),
          ListTile(
            leading: Icon(Icons.save),
            title: Text('2. Guardar Proyectos'),
            subtitle: Text('Después de escanear, nombra el proyecto y guarda en BBDD Local (Hive).'),
          ),
          ListTile(
            leading: Icon(Icons.calculate),
            title: Text('3. Interpretar Dosificación'),
            subtitle: Text('En Metrados, ingresa volumen para ver bolsas cemento, arena, piedra y agua.'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NormatividadPage extends StatelessWidget {
  const NormatividadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Normatividad Peruana')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExpansionTile(
            title: Text('Reglamento Nacional de Edificaciones (RNE)'),
            children: [
              ListTile(
                title: Text('Normas G.050: Generalidades'),
                subtitle: Text('Define principios generales para edificaciones seguras.'),
              ),
              ListTile(
                title: Text('Normas E.060: Estructuras'),
                subtitle: Text('Requisitos para diseño estructural resistente a sismos.'),
              ),
              ListTile(
                title: Text('Normas E.070: Cimentaciones'),
                subtitle: Text('Especificaciones para bases sólidas en terrenos peruanos.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Ley 29090 de Habilitaciones Urbanas'),
            children: [
              ListTile(
                subtitle: Text('Regula permisos y procedimientos para urbanización y construcción en áreas rurales/urbanas.'),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Normas Técnicas Peruanas (NTP) sobre Agregados'),
            children: [
              ListTile(
                subtitle: Text('Especifica calidad de arena y piedra para concreto, asegurando durabilidad.'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ConversionFlotanteWidget extends StatefulWidget {
  const ConversionFlotanteWidget({super.key});

  @override
  State<ConversionFlotanteWidget> createState() => _ConversionFlotanteWidgetState();
}

class _ConversionFlotanteWidgetState extends State<ConversionFlotanteWidget> {
  final TextEditingController _inputController = TextEditingController();
  String _result = '';
  String _conversionType = 'metros_a_pies'; // Agregado para funcionalidad

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _convert() {
    final value = double.tryParse(_inputController.text) ?? 0;
    if (_conversionType == 'metros_a_pies') {
      setState(() => _result = '${value * 3.28084} pies');
    } else {
      setState(() => _result = '${value / 3.28084} metros');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversión Flotante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _conversionType,
              items: const [
                DropdownMenuItem(value: 'metros_a_pies', child: Text('Metros a Pies')),
                DropdownMenuItem(value: 'pies_a_metros', child: Text('Pies a Metros')),
              ],
              onChanged: (value) => setState(() => _conversionType = value!),
            ),
            TextField(
              controller: _inputController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor a convertir'),
            ),
            ElevatedButton(onPressed: _convert, child: const Text('Convertir')),
            Text(_result, style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
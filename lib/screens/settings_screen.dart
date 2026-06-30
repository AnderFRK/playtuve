import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/backend_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();

  bool _probandoConexion = false;
  String? _mensajeEstado;
  bool? _conexionExitosa;

  @override
  void initState() {
    super.initState();
    _cargarUrlGuardada();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _cargarUrlGuardada() async {
    String url = await BackendConfig.obtenerUrl();
    setState(() {
      _urlController.text = url;
    });
  }

  Future<void> _probarConexion() async {
    String url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _mensajeEstado = 'Ingresa una URL primero.';
        _conexionExitosa = false;
      });
      return;
    }

    // Quitamos la barra final si la tiene
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    setState(() {
      _probandoConexion = true;
      _mensajeEstado = null;
      _conexionExitosa = null;
    });

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Verificamos que la respuesta tenga el formato esperado de nuestro backend
        var data = jsonDecode(response.body);
        bool esBackendValido = data is Map && data.containsKey('status');

        setState(() {
          _conexionExitosa = esBackendValido;
          _mensajeEstado = esBackendValido
              ? 'Conectado correctamente al servidor.'
              : 'El servidor respondió, pero no parece ser el backend de PlayTuve.';
        });
      } else {
        setState(() {
          _conexionExitosa = false;
          _mensajeEstado =
              'El servidor respondió con error ${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _conexionExitosa = false;
        _mensajeEstado =
            'No se pudo conectar. Verifica la URL e intenta de nuevo.\n\nDetalle: ${e.toString()}';
      });
    } finally {
      setState(() {
        _probandoConexion = false;
      });
    }
  }

  Future<void> _guardarConfiguracion() async {
    String url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una URL antes de guardar.')),
      );
      return;
    }

    await BackendConfig.guardarUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Configuración guardada.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración del servidor'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección del servidor (backend)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplos:\n'
              '• Local: http://192.168.1.34:5000\n'
              '• En la nube: https://tu-backend.onrender.com',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL del servidor',
                hintText: 'Ej: http://${BackendConfig.placeholderEjemplo}',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.dns),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _probandoConexion ? null : _probarConexion,
                    icon: _probandoConexion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: const Text('Probar conexión'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_mensajeEstado != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _conexionExitosa == true
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _conexionExitosa == true ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _mensajeEstado!,
                  style: TextStyle(
                    color: _conexionExitosa == true
                        ? Colors.green[800]
                        : Colors.red[800],
                  ),
                ),
              ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: _guardarConfiguracion,
              icon: const Icon(Icons.save),
              label: const Text('Guardar configuración'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

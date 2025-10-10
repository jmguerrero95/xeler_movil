import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';

class CambiarPage extends StatefulWidget {
  const CambiarPage({super.key});

  @override
  State<CambiarPage> createState() => _CambiarPageState();
}

class _CambiarPageState extends State<CambiarPage> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordNuevoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    oldPasswordController.dispose();
    passwordController.dispose();
    passwordNuevoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Cambiar Contraseña'),
      ),
      body: SingleChildScrollView(
        child: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextField(
                  obscureText: true,
                  controller: oldPasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Contraseña Anterior',
                    labelText: 'Contraseña Anterior',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Contraseña Nueva',
                    labelText: 'Contraseña Nueva',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: TextField(
                  obscureText: true,
                  controller: passwordNuevoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Repite Contraseña Nueva',
                    labelText: 'Repite Contraseña Nueva',
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 118, 104, 254),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _isLoading ? null : _cambiar,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'Cambiar',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDialog(String msg, String titulo) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(msg),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cambiar() async {
    setState(() {
      _isLoading = true;
    });

    final data = {
      'old_password': oldPasswordController.text,
      'password': passwordController.text,
      'nueva': passwordNuevoController.text,
    };

    try {
      final res = await CallApi().postData(data, 'configuracion2');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final mensaje = body['mensaje']?.toString() ?? 'Operación completada';
      final titulo = body['titulo']?.toString() ?? 'Resultado';
      await _showDialog(mensaje, titulo);
      if (body['success'] == true) {
        oldPasswordController.clear();
        passwordNuevoController.clear();
        passwordController.clear();
      }
    } catch (error) {
      await _showDialog('No se pudo cambiar la contraseña: $error', 'Error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

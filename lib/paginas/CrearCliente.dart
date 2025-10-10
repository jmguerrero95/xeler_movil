import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/DetallesCliente.dart';

class CrearClientePage extends StatefulWidget {
  const CrearClientePage({super.key});

  @override
  State<CrearClientePage> createState() => _CrearClienteState();
}

class _CrearClienteState extends State<CrearClientePage> {
  final TextEditingController nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Crear Cliente'),
      ),
      body: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el nombre completo',
                    labelText: 'Nombre Completo',
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
                    onPressed: _isLoading ? null : _crearCliente,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'Crear',
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

  Future<void> _mostrarMensaje(String msg) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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

  Future<void> _crearCliente() async {
    setState(() {
      _isLoading = true;
    });

    final data = {
      'name': nameController.text.trim(),
    };

    try {
      final res = await CallApi().postData(data, 'crearCliente');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        nameController.clear();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => DetallesCliente(
              id: body['id'] as int,
              name: body['name'].toString(),
            ),
          ),
        );
      } else {
        await _mostrarMensaje(body['mensaje']?.toString() ?? 'Error inesperado');
      }
    } catch (error) {
      await _mostrarMensaje('No se pudo crear el cliente: $error');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }
}

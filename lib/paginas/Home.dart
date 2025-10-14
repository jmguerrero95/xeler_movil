import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/UltimosListView.dart';
import 'package:xeler_impresora/paginas/DetallesCliente.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  final List<UltimosClientes> _ultimos = [];

  @override
  void initState() {
    super.initState();
    _loadClientesRecientes();
  }

  Future<void> _loadClientesRecientes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await CallApi().getData('obtenerUltimos');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> clientes = (decoded['clientes'] as List<dynamic>? ?? []);
        final ultimos = clientes
            .map((noteJson) => UltimosClientes.fromJson(noteJson as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _ultimos
            ..clear()
            ..addAll(ultimos);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/512xeler.png',
              fit: BoxFit.contain,
              height: 32,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
        child: Container(
          width: double.infinity,
          height: 590,
          margin: const EdgeInsets.only(top: 15),
          child: Column(
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 20),
                      child: Text(
                        'Últimos 5 Clientes',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _ultimos.isNotEmpty
                        ? ListView.builder(
                            itemCount: _ultimos.length,
                            itemBuilder: (context, index) {
                              final cliente = _ultimos[index];
                              return Card(
                                elevation: 8.0,
                                margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 36, 38, 80),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20.0,
                                      vertical: 10.0,
                                    ),
                                    title: Text(
                                      cliente.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: <Widget>[
                                        Expanded(
                                          flex: 4,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 10.0),
                                            child: Text(
                                              cliente.id.toString(),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.keyboard_arrow_right,
                                      color: Colors.white,
                                      size: 30.0,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => DetallesCliente(
                                            id: cliente.id,
                                            name: cliente.name,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text(
                              'No tienes clientes',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

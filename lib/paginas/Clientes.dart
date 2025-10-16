import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Clientes.dart';
import 'package:xeler_impresora/paginas/CrearCliente.dart';
import 'package:xeler_impresora/paginas/DetallesCliente.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final List<Clientes> _notes = [];
  List<Clientes> _notesForDisplay = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final response = await CallApi().getData('obtenerMisClientes');
      if (response.statusCode == 200) {
        final List<dynamic> notesJson = jsonDecode(response.body) as List<dynamic>;
        final clientes = notesJson
            .map((noteJson) => Clientes.fromJson(noteJson as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _notes
            ..clear()
            ..addAll(clientes);
          _notesForDisplay = List<Clientes>.from(_notes);
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _notes
            ..clear()
            ..addAll(const []);
          _notesForDisplay = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notesForDisplay = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notesForDisplay.isNotEmpty
                ? ListView.builder(
                    itemBuilder: (context, index) {
                      return index == 0
                          ? _searchBar()
                          : _listItem(index - 1, context);
                    },
                    itemCount: _notesForDisplay.length + 1,
                  )
                : Center(
                    child: Text(
                      _notes.isEmpty
                          ? 'No tienes clientes'
                          : 'Ningún cliente encontrado',
                      style: const TextStyle(fontSize: 18.0),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CrearClientePage(),
            ),
          );
          _loadClientes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar...',
        ),
        onChanged: (text) {
          final query = text.toLowerCase();
          setState(() {
            _notesForDisplay = _notes
                .where((note) => note.name.toLowerCase().contains(query))
                .toList();
          });
        },
      ),
    );
  }

  Widget _listItem(int index, BuildContext context) {
    final cliente = _notesForDisplay[index];
    return Card(
      elevation: 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 36, 38, 80),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text(
            cliente.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              )
            ],
          ),
          trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
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
  }
}

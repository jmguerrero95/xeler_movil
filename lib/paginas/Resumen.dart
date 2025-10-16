import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Resumen.dart';

class ResumenPage extends StatefulWidget {
  const ResumenPage({super.key});

  @override
  State<ResumenPage> createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {
  final List<Resumen> _notes = [];
  List<Resumen> _notesForDisplay = [];
  final NumberFormat formato = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _loadResumen();
  }

  Future<void> _loadResumen() async {
    try {
      final response = await CallApi().getData('obtenerResumen');
      if (response.statusCode == 200) {
        final List<dynamic> notesJson = jsonDecode(response.body) as List<dynamic>;
        final notes = notesJson
            .map((noteJson) => Resumen.fromJson(noteJson as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _notes
            ..clear()
            ..addAll(notes);
          _notesForDisplay = List<Resumen>.from(_notes);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notesForDisplay = [];
      });
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
      body: SafeArea(
        child: _notesForDisplay.isNotEmpty
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Cliente')),
                    DataColumn(label: Text('Valor')),
                    DataColumn(label: Text('Creado')),
                  ],
                  rows: _notesForDisplay
                      .map(
                        (element) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(element.cliente)),
                            DataCell(Text(
                                formato.format(int.tryParse(element.valor) ?? 0))),
                            DataCell(Text(element.creado)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              )
            : const Center(
                child: Text(
                  'No hay datos de resumen disponibles',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
      ),
    );
  }
}

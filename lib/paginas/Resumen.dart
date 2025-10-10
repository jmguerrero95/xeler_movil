import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Resumen.dart';

class ResumenPage extends StatefulWidget {
  @override
  _ResumenPageState createState() => _ResumenPageState();
}

class _ResumenPageState extends State<ResumenPage> {

  List<Resumen> _notes = List<Resumen>();
  List<Resumen> _notesForDisplay = List<Resumen>();
  final formato = new NumberFormat("#,###");
  Future<List<Resumen>> fetchNotes() async {
    
    //await Future.delayed(Duration(seconds: 2));
    var response = await CallApi().getData('obtenerResumen');
    
    var notes = List<Resumen>();
    
    if (response.statusCode == 200) {
      var notesJson = json.decode(response.body);
      for (var noteJson in notesJson) {
        notes.add(Resumen.fromJson(noteJson));
      }
    }
    return notes;
  }

  @override
  void initState() {
    fetchNotes().then((value) {
      setState(() {
        _notes.addAll(value);
        _notesForDisplay = _notes;
      });
    });
    super.initState();
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
      body: SafeArea(child: DataTable(
                    columns: [
                      DataColumn(label: Text('Cliente')),
                      DataColumn(label: Text('Valor')),
                      DataColumn(label: Text('Creado')),
                    ],
                    rows:
                    _notesForDisplay
                        .map(
                      ((element) => DataRow(
                        cells: <DataCell>[
                          DataCell(Text(element.cliente)),
                          DataCell(Text(formato.format(int.parse(element.valor)))),
                          DataCell(Text(element.creado)),
                        ],
                      )),
                    )
                        .toList(),
                  ),),
    );
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Buscar...'
        ),
        onChanged: (text) {
          text = text.toLowerCase();
          setState(() {
            _notesForDisplay = _notes.where((note) {
              var noteTitle = note.cliente.toLowerCase();
              return noteTitle.contains(text);
            }).toList();
          });
        },
      ),
    );
  }


}
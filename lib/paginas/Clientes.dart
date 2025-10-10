import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/paginas/CrearCliente.dart';
import 'package:xeler_impresora/paginas/DetallesCliente.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Clientes.dart';

class ClientesPage extends StatefulWidget {
  @override
  _ClientesPageState createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List<Clientes> _notes = List<Clientes>();
  List<Clientes> _notesForDisplay = List<Clientes>();

  Future<List<Clientes>> fetchNotes() async {
    
    //await Future.delayed(Duration(seconds: 2));
    var response = await CallApi().getData('obtenerMisClientes');
    
    var notes = List<Clientes>();
    
    if (response.statusCode == 200) {
      var notesJson = json.decode(response.body);
      for (var noteJson in notesJson) {
        notes.add(Clientes.fromJson(noteJson));
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
       // bottom: _buildBottomBar(),
      ),
      body: SafeArea(
          child: _notesForDisplay.isNotEmpty ? 
          ListView.builder(
          itemBuilder: (context, index) {
          return index == 0 ? _searchBar() : _listItem(index -1,context);
        },
          itemCount: _notesForDisplay.length+1,
      ) 
      : Center(
        child: Text(_notesForDisplay.length == 0 ? 
        "No tienes clientes" : 'Ningun cliente encontrado',
                style: TextStyle(fontSize: 18.0)
                  )
              )
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () {
          Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CrearClientePage()));
        },
      ),
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
              var noteTitle = note.name.toLowerCase();
              return noteTitle.contains(text);
            }).toList();
          });
        },
      ),
    );
  }


  _listItem(index,BuildContext context) {
    return Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromARGB(255, 36, 38, 80)),
            child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text(_notesForDisplay[index].name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(_notesForDisplay[index].id.toString(),
                        style: TextStyle(color: Colors.white))),
              )
            ],
          ),
          trailing:
              Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
          onTap: () {
            Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DetallesCliente(id: _notesForDisplay[index].id,name: _notesForDisplay[index].name,)));
          },
        )
          ),
          );
  }

  /* Widget _buildShopItem(Map item,BuildContext context) {
    
  } */

}
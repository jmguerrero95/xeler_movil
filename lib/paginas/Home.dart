import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/UltimosListView.dart';

import 'DetallesCliente.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  bool _isLoading;
  //List clientes = [];
  List<UltimosClientes> _ultimos = List<UltimosClientes>();

  Future<List<UltimosClientes>> fetchNotes() async {
    setState(() {
       _isLoading = true;
    });
    //await Future.delayed(Duration(seconds: 2));
    var response = await CallApi().getData('obtenerUltimos');
    
    var notes = List<UltimosClientes>();
    
    if (response.statusCode == 200) {
      var notesJson = json.decode(response.body);
      for (var noteJson in notesJson['clientes']) {
        notes.add(UltimosClientes.fromJson(noteJson));
      }
    }
    return notes;
  }

  @override
  void initState() {
    _isLoading = true;
    fetchNotes().then((value) {
      setState(() {
        _isLoading = false;
        _ultimos.addAll(value);
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
      body: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 0.0, right: 0.0),
            child: Container(
              width: double.infinity,
              height: 590,
              margin: EdgeInsets.only(top: 15),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 20),
                        child: Text(
                          'Ultimos 5 Clientes',
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
      Expanded(
        
          child: _ultimos.length == 0 ? Center(child: CircularProgressIndicator()) : 
          _ultimos.isNotEmpty ?
          ListView.builder(
        itemBuilder: (context, index) {
          if(_isLoading){
            return Center(child: CircularProgressIndicator());
          }
          return Card(
          elevation: 8.0,
          margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          child: Container(
            decoration: BoxDecoration(color: Color.fromARGB(255, 36, 38, 80)),
            child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          title: Text(_ultimos[index].name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(_ultimos[index].id.toString(),
                        style: TextStyle(color: Colors.white))),
              )
            ],
          ),
          trailing:
              Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
          onTap: () {
            Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => DetallesCliente(id: _ultimos[index].id,name: _ultimos[index].name,)));
          },
        )
          ),
          );
        },
        itemCount: _ultimos.length)
        : Center(child: Text("No tienes clientes",
                style: TextStyle(fontSize: 18.0)
                  ),)
      )
       
      ],
  )
    )));
      
    
  }

  
}
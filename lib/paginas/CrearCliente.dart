import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xeler_impresora/api/api.dart';

import 'DetallesCliente.dart';

class CrearClientePage extends StatefulWidget {
  @override
  _CrearClienteState createState() => _CrearClienteState();

}

class _CrearClienteState extends State<CrearClientePage> {
   bool _isLoading = false;
  TextEditingController nameController = TextEditingController();
  ScaffoldState scaffoldState;

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Crear Cliente'),
      ),
      body: SingleChildScrollView(
        child: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Ingresa el nombre completo',
                    labelText:  'Nombre Completo'
                  )
                ),
              ),
              Divider(),
              Padding(
                padding: EdgeInsets.fromLTRB(25.0, 0.0, 25.0, 25.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                                  child: RaisedButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onPressed: _isLoading ? null : _crearCliente,
                    padding: EdgeInsets.all(12),
                    color: Color.fromARGB(255,118, 104, 254),
                    child: _isLoading ? Center( child:CircularProgressIndicator()) : 
                    Text(_isLoading? 'Creando...' : 'Crear', 
                    style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            ]
          ) 
        ,)
      ),
    );
  }

void _mostrarMensaje(msg) {
  final alert = AlertDialog(
    content: Text(msg),
    actions: [FlatButton(child: Text("OK"), onPressed: () {
      Navigator.of(context).pop();
     // Navigator.pop();
    })],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}


void _crearCliente() async{
    
    setState(() {
       _isLoading = true;
    });

    var data = {
        'name' : nameController.text
    };

    var res = await CallApi().postData(data, 'crearCliente');
    var body = json.decode(res.body);
    //print(body);
    if(res.statusCode == 200){
      nameController.clear();
      
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => DetallesCliente(id: body['id'],name: body['name'],)));
    }else{
      _mostrarMensaje(body['mensaje']);
      //_showMsg(body['message']);
    }


    setState(() {
       _isLoading = false;
    });

  


  }


}


  
